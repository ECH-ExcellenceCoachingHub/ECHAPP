const mongoose = require('mongoose');
const StudySession = require('../../models/community/StudySession');
const StudyGroup = require('../../models/community/StudyGroup');
const User = require('../../models/User');
const BBBService = require('../../services/bbb.service');
const { sendSuccess, sendError, sendNotFound, sendForbidden } = require('../../utils/response.utils');
const { PUBLIC_USER_FIELDS } = require('../../utils/community.utils');
const { mapSession } = require('../../utils/session.mapper');
const CommunityNotificationService = require('../../services/community-notification.service');

/**
 * Peer study sessions, running on the same BigBlueButton server as the
 * teacher-led `LiveSession` feature.
 *
 * The BBB meeting is created lazily — the first time the organiser opens the
 * room — so scheduling a session costs nothing on the BBB server and a session
 * nobody attends never occupies a slot.
 */

const POPULATE = [
  { path: 'createdBy', select: PUBLIC_USER_FIELDS },
  { path: 'participants.userId', select: PUBLIC_USER_FIELDS },
  { path: 'groupId', select: 'name' }
];

const loadSession = (id) => StudySession.findById(id).populate(POPULATE).lean();

class SessionController {
  /**
   * Every upcoming study session across all the caller's courses.
   *
   * Not scoped to a course, so it runs without `loadCommunityContext` and
   * derives membership itself: sessions from courses the user is enrolled in
   * or teaches. The home dashboard lists these beside teacher-led live
   * sessions, so a group meeting is as visible as a class.
   */
  async mySessions(req, res) {
    try {
      const userId = req.user._id;
      const isAdmin = req.user.role === 'admin';

      const Enrollment = require('../../models/Enrollment');
      const TeacherAssignment = require('../../models/TeacherAssignment');

      const [enrollments, assignments] = await Promise.all([
        Enrollment.find({ userId }).select('courseId').lean(),
        TeacherAssignment.find({ teacherId: userId, isActive: true, source: { $ne: 'guide_purchase' } })
          .select('courseId')
          .lean()
      ]);

      const courseIds = [
        ...new Set([
          ...enrollments.map((e) => String(e.courseId)),
          ...assignments.map((a) => String(a.courseId))
        ])
      ];

      if (courseIds.length === 0) {
        return sendSuccess(res, { sessions: [] }, 'No sessions');
      }

      const now = new Date();
      const query = {
        courseId: { $in: courseIds },
        $or: [
          { status: 'scheduled', scheduledAt: { $gte: new Date(now.getTime() - 60 * 60 * 1000) } },
          { status: 'live' }
        ]
      };

      const sessions = await StudySession.find(query)
        .sort({ scheduledAt: 1 })
        .limit(25)
        .populate(POPULATE)
        .populate('courseId', 'title')
        .lean();

      // A group's sessions are private to that group; course-wide ones are
      // open to everyone in the course.
      const myGroupIds = new Set(
        (await StudyGroup.find({
          courseId: { $in: courseIds },
          isArchived: false,
          members: { $elemMatch: { userId, status: 'active' } }
        })
          .select('_id')
          .lean()).map((g) => String(g._id))
      );

      const teacherCourseIds = new Set(assignments.map((a) => String(a.courseId)));

      const visible = sessions.filter((s) => {
        if (!s.groupId) return true;
        const groupId = String(s.groupId._id || s.groupId);
        if (myGroupIds.has(groupId)) return true;
        return isAdmin || teacherCourseIds.has(String(s.courseId._id || s.courseId));
      });

      return sendSuccess(res, {
        sessions: visible.map((s) => {
          const isTeacher =
            isAdmin || teacherCourseIds.has(String(s.courseId._id || s.courseId));
          return {
            ...mapSession(s, userId, isTeacher),
            courseId: String(s.courseId._id || s.courseId),
            courseTitle: s.courseId && s.courseId.title ? s.courseId.title : null
          };
        })
      }, 'Your study sessions');
    } catch (error) {
      console.error('Error loading cross-course sessions:', error);
      return sendError(res, 'Failed to load your study sessions', 500, error.message);
    }
  }

  async listSessions(req, res) {
    try {
      const { courseId, userId, isTeacher } = req.community;
      const { scope = 'upcoming', groupId } = req.query;

      const query = { courseId };
      if (groupId && mongoose.Types.ObjectId.isValid(groupId)) query.groupId = groupId;

      const now = new Date();
      if (scope === 'upcoming') {
        // A session that is live stays in "upcoming" even once its start time
        // has passed, otherwise it would vanish exactly when people need it.
        query.$or = [
          { status: 'scheduled', scheduledAt: { $gte: now } },
          { status: 'live' }
        ];
      } else if (scope === 'past') {
        query.status = { $in: ['completed', 'cancelled'] };
      } else if (scope === 'mine') {
        query.$or = [{ createdBy: userId }, { 'participants.userId': userId }];
      }

      const sessions = await StudySession.find(query)
        .sort({ scheduledAt: scope === 'past' ? -1 : 1 })
        .limit(100)
        .populate(POPULATE)
        .lean();

      return sendSuccess(res, {
        sessions: sessions.map((s) => mapSession(s, userId, isTeacher))
      }, 'Study sessions loaded');
    } catch (error) {
      console.error('Error listing study sessions:', error);
      return sendError(res, 'Failed to load study sessions', 500, error.message);
    }
  }

  async getSession(req, res) {
    try {
      const { courseId, userId, isTeacher } = req.community;
      const { sessionId } = req.params;

      if (!mongoose.Types.ObjectId.isValid(sessionId)) {
        return sendError(res, 'A valid session ID is required', 400);
      }

      const session = await StudySession.findOne({ _id: sessionId, courseId })
        .populate(POPULATE)
        .lean();
      if (!session) return sendNotFound(res, 'Study session not found');

      return sendSuccess(res, mapSession(session, userId, isTeacher), 'Session loaded');
    } catch (error) {
      console.error('Error loading study session:', error);
      return sendError(res, 'Failed to load session', 500, error.message);
    }
  }

  /**
   * Create a session. Group sessions notify that group; course-wide sessions
   * stay quiet at creation time so the class is not spammed — people find them
   * in the Sessions tab and RSVP, and only then start receiving reminders.
   */
  async createSession(req, res) {
    try {
      const { courseId, userId, isTeacher } = req.community;
      const {
        topic,
        description = '',
        scheduledAt,
        durationMinutes = 60,
        agenda = [],
        maxParticipants = 10,
        meetingLink = '',
        groupId = null
      } = req.body;

      if (!topic || !topic.trim()) return sendError(res, 'A session topic is required', 400);
      if (!scheduledAt) return sendError(res, 'Pick a date and time for the session', 400);

      const when = new Date(scheduledAt);
      if (Number.isNaN(when.getTime())) {
        return sendError(res, 'That date and time is not valid', 400);
      }
      if (when.getTime() < Date.now() - 5 * 60 * 1000) {
        return sendError(res, 'Pick a time in the future', 400);
      }

      let resolvedGroupId = null;
      if (groupId && mongoose.Types.ObjectId.isValid(groupId)) {
        const group = await StudyGroup.findOne({ _id: groupId, courseId, isArchived: false });
        if (!group) return sendNotFound(res, 'Study group not found');
        if (!group.isActiveMember(userId) && !isTeacher) {
          return sendForbidden(res, 'You are not a member of that group');
        }
        resolvedGroupId = group._id;
      }

      // An organiser-supplied link wins; otherwise the session runs on the
      // platform's BBB server (falling back to `external` if BBB is unset up).
      const externalLink = (meetingLink || '').trim();
      let provider = externalLink ? 'external' : 'bbb';
      if (provider === 'bbb' && !(await BBBService.getConfig())) {
        provider = 'external';
      }

      const session = await StudySession.create({
        courseId,
        groupId: resolvedGroupId,
        createdBy: userId,
        topic: topic.trim(),
        description: (description || '').trim(),
        scheduledAt: when,
        durationMinutes: Math.min(240, Math.max(10, parseInt(durationMinutes, 10) || 60)),
        agenda: Array.isArray(agenda)
          ? agenda.map((a) => String(a).trim()).filter(Boolean).slice(0, 20)
          : [],
        maxParticipants: Math.min(100, Math.max(2, parseInt(maxParticipants, 10) || 10)),
        meetingProvider: provider,
        meetingLink: externalLink,
        // The organiser is always the first participant.
        participants: [{ userId, joinedAt: new Date() }]
      });

      if (resolvedGroupId) {
        const [organiser, group] = await Promise.all([
          User.findById(userId).select('fullName').lean(),
          StudyGroup.findById(resolvedGroupId).select('members').lean()
        ]);
        CommunityNotificationService.sessionScheduled({
          recipientIds: group.members
            .filter((m) => m.status === 'active')
            .map((m) => String(m.userId)),
          courseId,
          sessionId: String(session._id),
          topic: session.topic,
          scheduledAt: session.scheduledAt,
          organiserName: organiser ? organiser.fullName : 'A classmate',
          excludeUserId: userId
        });
      }

      const populated = await loadSession(session._id);
      return sendSuccess(res, mapSession(populated, userId, isTeacher), 'Study session created', 201);
    } catch (error) {
      console.error('Error creating study session:', error);
      return sendError(res, 'Failed to create study session', 500, error.message);
    }
  }

  /** Toggle "I am coming". Separate from actually entering the room. */
  async rsvp(req, res) {
    try {
      const { courseId, userId, isTeacher } = req.community;
      const { sessionId } = req.params;

      const session = await StudySession.findOne({ _id: sessionId, courseId });
      if (!session) return sendNotFound(res, 'Study session not found');
      if (session.status === 'cancelled') {
        return sendError(res, 'This session was cancelled', 400);
      }
      if (session.status === 'completed') {
        return sendError(res, 'This session has already finished', 400);
      }

      const existing = session.participants.find(
        (p) => String(p.userId) === String(userId)
      );

      if (existing) {
        if (String(session.createdBy) === String(userId)) {
          return sendError(
            res,
            'You are organising this session — cancel it instead of leaving',
            400
          );
        }
        // Someone who already sat in the room keeps their attendance record.
        session.participants = session.participants.filter(
          (p) => String(p.userId) !== String(userId)
        );
      } else {
        if (session.participants.length >= session.maxParticipants) {
          return sendError(res, 'This session is already full', 400);
        }
        session.participants.push({ userId, joinedAt: new Date() });
      }

      await session.save();
      const populated = await loadSession(session._id);

      return sendSuccess(
        res,
        mapSession(populated, userId, isTeacher),
        existing ? 'You left the session' : 'You are on the list'
      );
    } catch (error) {
      console.error('Error updating session RSVP:', error);
      return sendError(res, 'Failed to update your RSVP', 500, error.message);
    }
  }

  /**
   * Enter the meeting room.
   *
   * The organiser (or a teacher) opening the room is what makes the session
   * live: their first join creates the BBB meeting and notifies everyone who
   * RSVP'd. Everyone else can only enter once it is live — mirroring how the
   * teacher-led `LiveSession` join works.
   */
  async join(req, res) {
    try {
      const { courseId, userId, isTeacher } = req.community;
      const { sessionId } = req.params;

      const session = await StudySession.findOne({ _id: sessionId, courseId });
      if (!session) return sendNotFound(res, 'Study session not found');
      if (session.status === 'cancelled') {
        return sendError(res, 'This session was cancelled', 400);
      }
      if (session.status === 'completed') {
        return sendError(res, 'This session has already finished', 400);
      }

      const isOrganiser = String(session.createdBy) === String(userId);
      const canModerate = isOrganiser || isTeacher;

      // Everyone is out once the session's window has closed.
      if (!session.isBeforeEnd()) {
        return sendError(res, 'This session\'s time has passed', 400);
      }

      // The organiser can open the room whenever they like. Attendees can
      // enter as soon as it is actually live — including when the organiser
      // started early. Only a room that is not open yet holds them to the
      // pre-start window, so nobody spins up a BBB room hours ahead.
      if (!canModerate &&
          session.status !== 'live' &&
          !session.isWithinJoinWindow()) {
        return sendError(
          res,
          `The room opens ${StudySession.EARLY_JOIN_MINUTES} minutes before the start time`,
          400
        );
      }

      // Joining implies attending — add the caller if they had not RSVP'd.
      let participant = session.participants.find(
        (p) => String(p.userId) === String(userId)
      );
      if (!participant) {
        if (session.participants.length >= session.maxParticipants && !canModerate) {
          return sendError(res, 'This session is already full', 400);
        }
        session.participants.push({ userId, joinedAt: new Date() });
        participant = session.participants[session.participants.length - 1];
      }
      if (!participant.attendedAt) participant.attendedAt = new Date();

      // ── External link: nothing to orchestrate, just hand it over ──
      if (session.meetingProvider === 'external') {
        if (!session.meetingLink) {
          return sendError(
            res,
            'The organiser has not shared a meeting link for this session yet',
            400
          );
        }
        if (canModerate && session.status !== 'live') {
          session.status = 'live';
          session.startedAt = session.startedAt || new Date();
        }
        await session.save();
        return sendSuccess(res, {
          provider: 'external',
          joinUrl: session.meetingLink,
          isModerator: canModerate,
          status: session.status
        }, 'Meeting link ready');
      }

      // ── BigBlueButton ──
      const config = await BBBService.getConfig();
      if (!config) {
        return sendError(
          res,
          'Video conferencing is not configured on this platform yet. Ask the organiser to share a meeting link instead.',
          503
        );
      }

      const user = await User.findById(userId).select('fullName').lean();
      const meetingId = session.bbbMeetingId || session.buildMeetingId();

      if (canModerate) {
        // Make sure a room actually exists on the BBB server. It may never
        // have been created, or BBB may have reclaimed it after it emptied.
        let running = false;
        if (session.bbbMeetingId) {
          try {
            const info = await BBBService.getMeetingInfo(
              meetingId,
              session.bbbModeratorPw || ''
            );
            running = Boolean(info.success && info.isRunning);
          } catch (e) {
            console.log('BBB meeting info check failed, recreating:', e.message);
          }
        }

        if (!running) {
          const meeting = await BBBService.createMeeting({
            name: session.topic,
            meetingId,
            duration: session.durationMinutes + StudySession.LATE_JOIN_MINUTES,
            maxParticipants: session.maxParticipants,
            // Peer sessions record so classmates who miss it can catch up.
            record: true,
            allowStartStopRecording: true,
            autoStartRecording: false,
            muteOnStart: true,
            welcomeMsg: session.description || `Welcome to "${session.topic}"`,
            meta: {
              courseId: String(courseId),
              sessionId: String(session._id),
              kind: 'study-session'
            }
          });
          session.bbbMeetingId = meetingId;
          session.bbbInternalMeetingId =
            meeting.internalMeetingId || session.bbbInternalMeetingId;
          session.bbbModeratorPw = meeting.moderatorPw || session.bbbModeratorPw;
          session.bbbAttendeePw = meeting.attendeePw || session.bbbAttendeePw;
        }

        const wasLive = session.status === 'live';
        session.status = 'live';
        session.startedAt = session.startedAt || new Date();
        await session.save();

        // Tell the people who said they were coming, but only on the
        // transition into live — not on every re-join by the organiser.
        if (!wasLive) {
          CommunityNotificationService.sessionStarted({
            recipientIds: session.participants.map((p) => String(p.userId)),
            courseId,
            sessionId: String(session._id),
            topic: session.topic,
            organiserName: user ? user.fullName : 'The organiser',
            excludeUserId: userId
          });
        }

        const joinUrl = await BBBService.getJoinUrl({
          fullName: user?.fullName || 'Organiser',
          meetingId,
          password: session.bbbModeratorPw || '',
          userId: String(userId),
          isModerator: true
        });

        return sendSuccess(res, {
          provider: 'bbb',
          joinUrl,
          isModerator: true,
          status: session.status
        }, 'Room ready');
      }

      // ── Attendee ──
      if (session.status !== 'live' || !session.bbbMeetingId) {
        await session.save();
        return sendError(
          res,
          'The organiser has not opened the room yet. You will be notified the moment it starts.',
          409
        );
      }

      let info;
      try {
        info = await BBBService.getMeetingInfo(meetingId, session.bbbModeratorPw || '');
      } catch (e) {
        console.log('BBB meeting info check failed for attendee:', e.message);
      }
      if (!info || !info.success || !info.isRunning) {
        // The organiser left and BBB tore the room down.
        session.status = 'scheduled';
        await session.save();
        return sendError(
          res,
          'The room is not open right now. You will be notified when it restarts.',
          409
        );
      }

      await session.save();

      const joinUrl = await BBBService.getJoinUrl({
        fullName: user?.fullName || 'Student',
        meetingId,
        password: session.bbbAttendeePw || '',
        userId: String(userId),
        isModerator: false
      });

      return sendSuccess(res, {
        provider: 'bbb',
        joinUrl,
        isModerator: false,
        status: session.status
      }, 'Joining the room');
    } catch (error) {
      console.error('Error joining study session:', error);
      return sendError(res, 'Failed to join the session', 500, error.message);
    }
  }

  /** Organiser closes the room; attendance minutes are settled here. */
  async end(req, res) {
    try {
      const { courseId, userId, isTeacher } = req.community;
      const { sessionId } = req.params;

      const session = await StudySession.findOne({ _id: sessionId, courseId });
      if (!session) return sendNotFound(res, 'Study session not found');
      if (String(session.createdBy) !== String(userId) && !isTeacher) {
        return sendForbidden(res, 'Only the organiser can end this session');
      }

      if (session.bbbMeetingId && session.meetingProvider === 'bbb') {
        try {
          await BBBService.endMeeting(session.bbbMeetingId, session.bbbModeratorPw || '');
        } catch (e) {
          // The room may already be gone — that is exactly the state we want.
          console.log('BBB end meeting failed (may already be closed):', e.message);
        }
      }

      const endedAt = new Date();
      session.participants.forEach((p) => {
        if (p.attendedAt && !p.attendanceMinutes) {
          const minutes = Math.round((endedAt - new Date(p.attendedAt)) / 60000);
          p.attendanceMinutes = Math.max(0, Math.min(minutes, session.durationMinutes + 60));
        }
      });

      session.status = 'completed';
      session.endedAt = endedAt;
      await session.save();

      const populated = await loadSession(session._id);
      return sendSuccess(res, mapSession(populated, userId, isTeacher), 'Session ended');
    } catch (error) {
      console.error('Error ending study session:', error);
      return sendError(res, 'Failed to end the session', 500, error.message);
    }
  }

  async updateSession(req, res) {
    try {
      const { courseId, userId, isTeacher } = req.community;
      const { sessionId } = req.params;
      const { topic, description, scheduledAt, durationMinutes, agenda, meetingLink, maxParticipants } = req.body;

      const session = await StudySession.findOne({ _id: sessionId, courseId });
      if (!session) return sendNotFound(res, 'Study session not found');
      if (String(session.createdBy) !== String(userId) && !isTeacher) {
        return sendForbidden(res, 'Only the organiser can change this session');
      }
      if (session.status === 'completed') {
        return sendError(res, 'A finished session cannot be edited', 400);
      }

      let rescheduled = false;

      if (topic !== undefined && topic.trim()) session.topic = topic.trim();
      if (description !== undefined) session.description = (description || '').trim();
      if (scheduledAt !== undefined) {
        const when = new Date(scheduledAt);
        if (Number.isNaN(when.getTime())) {
          return sendError(res, 'That date and time is not valid', 400);
        }
        if (when.getTime() !== new Date(session.scheduledAt).getTime()) {
          rescheduled = true;
          // Moving the session invalidates any reminder already sent.
          session.reminders = { dayBefore: null, thirtyMinutes: null, starting: null };
        }
        session.scheduledAt = when;
      }
      if (durationMinutes !== undefined) {
        session.durationMinutes = Math.min(
          240,
          Math.max(10, parseInt(durationMinutes, 10) || session.durationMinutes)
        );
      }
      if (maxParticipants !== undefined) {
        const cap = Math.min(100, Math.max(2, parseInt(maxParticipants, 10) || session.maxParticipants));
        if (cap < session.participants.length) {
          return sendError(res, 'That limit is below the number of people already signed up', 400);
        }
        session.maxParticipants = cap;
      }
      if (Array.isArray(agenda)) {
        session.agenda = agenda.map((a) => String(a).trim()).filter(Boolean).slice(0, 20);
      }
      if (meetingLink !== undefined) {
        session.meetingLink = (meetingLink || '').trim();
        // Clearing the link hands the session back to BBB, if it is available.
        if (!session.meetingLink && (await BBBService.getConfig())) {
          session.meetingProvider = 'bbb';
        } else if (session.meetingLink) {
          session.meetingProvider = 'external';
        }
      }

      await session.save();

      if (rescheduled) {
        CommunityNotificationService.sessionRescheduled({
          recipientIds: session.participants.map((p) => String(p.userId)),
          courseId,
          sessionId: String(session._id),
          topic: session.topic,
          scheduledAt: session.scheduledAt,
          excludeUserId: userId
        });
      }

      const populated = await loadSession(session._id);
      return sendSuccess(res, mapSession(populated, userId, isTeacher), 'Session updated');
    } catch (error) {
      console.error('Error updating study session:', error);
      return sendError(res, 'Failed to update session', 500, error.message);
    }
  }

  async cancelSession(req, res) {
    try {
      const { courseId, userId, isTeacher } = req.community;
      const { sessionId } = req.params;

      const session = await StudySession.findOne({ _id: sessionId, courseId });
      if (!session) return sendNotFound(res, 'Study session not found');
      if (String(session.createdBy) !== String(userId) && !isTeacher) {
        return sendForbidden(res, 'Only the organiser can cancel this session');
      }

      if (session.bbbMeetingId && session.status === 'live') {
        try {
          await BBBService.endMeeting(session.bbbMeetingId, session.bbbModeratorPw || '');
        } catch (e) {
          console.log('BBB end meeting on cancel failed:', e.message);
        }
      }

      session.status = 'cancelled';
      session.endedAt = new Date();
      await session.save();

      CommunityNotificationService.sessionCancelled({
        recipientIds: session.participants.map((p) => String(p.userId)),
        courseId,
        sessionId: String(session._id),
        topic: session.topic,
        excludeUserId: userId
      });

      return sendSuccess(res, null, 'Session cancelled');
    } catch (error) {
      console.error('Error cancelling study session:', error);
      return sendError(res, 'Failed to cancel session', 500, error.message);
    }
  }

  /**
   * The recording, with everything needed to review it properly: how long it
   * runs, who was there, which playback formats exist and whether a
   * downloadable file is among them.
   *
   * Pulls from BBB on demand — the scheduler also does this in the background,
   * but someone asking right after a session should not wait for the sweep.
   */
  async getRecording(req, res) {
    try {
      const { courseId, userId, isTeacher } = req.community;
      const { sessionId } = req.params;

      const session = await StudySession.findOne({ _id: sessionId, courseId });
      if (!session) return sendNotFound(res, 'Study session not found');

      const isOrganiser = String(session.createdBy) === String(userId);
      const canManage = isOrganiser || isTeacher;

      // Only the organiser sees a recording they have unpublished.
      if (!session.isRecordingPublished && !canManage) {
        return sendSuccess(res, {
          recordingUrl: null,
          unavailable: true
        }, 'The organiser has not shared this recording');
      }

      const payload = () => ({
        recordingUrl: session.recordingUrl,
        recordingDownloadUrl: session.recordingDownloadUrl,
        recordingDuration: session.recordingDuration,
        recordingParticipants: session.recordingParticipants,
        formats: session.recordingFormats || [],
        // A file only reaches members once the organiser has allowed it.
        canDownload: Boolean(
          session.recordingDownloadUrl &&
          (canManage || session.allowRecordingDownload)
        ),
        /**
         * Peer sessions are the organiser's own content, so they decide who
         * may keep a copy — unlike course live classes, where the file is
         * institutional and only an admin can take it off the platform.
         */
        downloadPolicy: 'organiser_controlled',
        hasDownloadableFile: Boolean(session.recordingDownloadUrl),
        allowRecordingDownload: session.allowRecordingDownload,
        isRecordingPublished: session.isRecordingPublished,
        canManageRecording: canManage,
        topic: session.topic,
        endedAt: session.endedAt
      });

      if (session.recordingUrl) {
        return sendSuccess(res, payload(), 'Recording ready');
      }

      if (!session.bbbMeetingId || session.meetingProvider !== 'bbb') {
        return sendSuccess(res, { recordingUrl: null }, 'This session was not recorded');
      }

      const recordings = await BBBService.getRecordings(session.bbbMeetingId);
      const ready = recordings.find((r) => r.published && r.playback);

      if (!ready) {
        session.recordingCheckedAt = new Date();
        await session.save();
        return sendSuccess(res, {
          recordingUrl: null,
          processing: true,
          canManageRecording: canManage
        }, 'The recording is still processing — check back shortly');
      }

      session.recordingUrl = ready.playback;
      session.recordingDownloadUrl = ready.downloadUrl || null;
      session.recordingFormats = ready.formats || [];
      session.recordingDuration = ready.duration || 0;
      session.recordingParticipants = ready.participants || 0;
      session.recordingCheckedAt = new Date();
      await session.save();

      return sendSuccess(res, payload(), 'Recording ready');
    } catch (error) {
      console.error('Error fetching session recording:', error);
      return sendError(res, 'Failed to fetch the recording', 500, error.message);
    }
  }

  /**
   * Organiser controls over the recording: share it with the group or not, and
   * whether members may keep a copy.
   */
  async updateRecording(req, res) {
    try {
      const { courseId, userId, isTeacher } = req.community;
      const { sessionId } = req.params;
      const { allowDownload, isPublished } = req.body;

      const session = await StudySession.findOne({ _id: sessionId, courseId });
      if (!session) return sendNotFound(res, 'Study session not found');

      if (String(session.createdBy) !== String(userId) && !isTeacher) {
        return sendForbidden(res, 'Only the organiser can manage this recording');
      }

      if (allowDownload !== undefined) {
        session.allowRecordingDownload = Boolean(allowDownload);
      }
      if (isPublished !== undefined) {
        session.isRecordingPublished = Boolean(isPublished);
      }
      await session.save();

      // Telling people a recording is downloadable is worth a notification;
      // silently flipping a flag they cannot see is not.
      if (allowDownload === true && session.isRecordingPublished) {
        CommunityNotificationService.sessionRecordingReady({
          recipientIds: session.participants.map((p) => String(p.userId)),
          courseId,
          sessionId: String(session._id),
          topic: session.topic
        });
      }

      return sendSuccess(res, {
        allowRecordingDownload: session.allowRecordingDownload,
        isRecordingPublished: session.isRecordingPublished
      }, 'Recording updated');
    } catch (error) {
      console.error('Error updating session recording:', error);
      return sendError(res, 'Failed to update the recording', 500, error.message);
    }
  }
}

module.exports = new SessionController();
