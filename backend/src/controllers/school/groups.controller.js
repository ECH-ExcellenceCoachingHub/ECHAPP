/**
 * Class discussion groups (the school "community").
 *
 * Teachers create groups for a class they teach (class teacher or subject
 * teacher; school admins for any class), for the whole class or chosen
 * students, and moderate them. Students discuss in the groups they belong to.
 */
const SchoolGroup = require('../../models/SchoolGroup');
const GroupMessage = require('../../models/GroupMessage');
const Classroom = require('../../models/Classroom');
const User = require('../../models/User');
const { classroomAccess, canManageSchool, same } = require('../../services/school/access.service');
const { notifyUsers } = require('../../services/school/notify.service');
const { cleanAttachments } = require('./teaching.controller');
const { HttpError, ok, wrap, requireId } = require('./helpers');

const PAGE = 40;

function isTeacherOf(group, user) {
  return (group.teacherIds || []).some((t) => same(t, user._id)) || canManageSchool(user, group.schoolId);
}

function isStudentOf(group, user) {
  if (user.role !== 'student' || !user.isActive) return false;
  if (!same(user.classroomId, group.classroomId)) return false;
  return group.wholeClass || (group.studentIds || []).some((s) => same(s, user._id));
}

async function loadGroup(req) {
  requireId(req.params.id, 'group id');
  const g = await SchoolGroup.findById(req.params.id);
  if (!g || !g.isActive) throw new HttpError('Group not found', 404);
  const teacher = isTeacherOf(g, req.user);
  const student = !teacher && isStudentOf(g, req.user);
  if (!teacher && !student) throw new HttpError('You are not a member of this group.', 403);
  return { g, teacher };
}

async function memberStudentIds(g) {
  if (g.wholeClass) {
    return (await User.find({ classroomId: g.classroomId, role: 'student', isActive: true }).select('_id').lean()).map((u) => u._id);
  }
  return g.studentIds || [];
}

async function groupView(g, user, { withMembers = false } = {}) {
  const o = g.toObject ? g.toObject() : g;
  const lastRead = o.lastRead instanceof Map ? o.lastRead.get(String(user._id)) : o.lastRead?.[String(user._id)];
  const [classroom, unread, studentCount] = await Promise.all([
    Classroom.findById(o.classroomId).select('name').lean(),
    GroupMessage.countDocuments({ groupId: o._id, deletedAt: null, authorId: { $ne: user._id }, ...(lastRead ? { createdAt: { $gt: lastRead } } : {}) }),
    o.wholeClass ? User.countDocuments({ classroomId: o.classroomId, role: 'student', isActive: true }) : Promise.resolve((o.studentIds || []).length),
  ]);
  const view = {
    id: String(o._id),
    name: o.name,
    description: o.description || '',
    subject: o.subject || null,
    classroomId: String(o.classroomId),
    className: classroom?.name || null,
    wholeClass: o.wholeClass,
    announcementsOnly: o.announcementsOnly,
    studentCount,
    unread,
    lastMessageAt: o.lastMessageAt,
    isTeacher: isTeacherOf(o, user),
    createdAt: o.createdAt,
  };
  if (withMembers) {
    const [teachers, students] = await Promise.all([
      User.find({ _id: { $in: o.teacherIds } }).select('fullName').lean(),
      User.find(o.wholeClass ? { classroomId: o.classroomId, role: 'student', isActive: true } : { _id: { $in: o.studentIds } }).select('fullName studentCode').sort({ fullName: 1 }).lean(),
    ]);
    view.teachers = teachers.map((t) => ({ id: String(t._id), fullName: t.fullName }));
    view.students = students.map((s) => ({ id: String(s._id), fullName: s.fullName, studentCode: s.studentCode }));
    view.studentIds = (o.studentIds || []).map(String);
  }
  return view;
}

function messageView(m, me, canModerate) {
  const author = m.authorId && m.authorId.fullName ? m.authorId : null;
  const deleted = !!m.deletedAt;
  return {
    id: String(m._id),
    author: author ? { id: String(author._id), fullName: author.fullName, role: author.role } : { id: String(m.authorId) },
    text: deleted ? '' : m.text || '',
    attachments: deleted ? [] : m.attachments || [],
    replyTo: m.replyTo ? String(m.replyTo) : null,
    pinned: !!m.pinned,
    deleted,
    mine: same(author?._id || m.authorId, me._id),
    canDelete: !deleted && (canModerate || same(author?._id || m.authorId, me._id)),
    createdAt: m.createdAt,
  };
}

/** Students of the class to include (chosen subset must belong to the class). */
async function cleanStudentIds(classroomId, ids) {
  if (!Array.isArray(ids)) return [];
  const valid = await User.find({ _id: { $in: ids.filter((x) => /^[a-f0-9]{24}$/i.test(String(x))) }, classroomId, role: 'student' }).select('_id').lean();
  return valid.map((v) => v._id);
}

/** GET /school/groups — groups I teach or belong to. */
const myGroups = wrap(async (req, res) => {
  const u = req.user;
  let filter;
  if (u.role === 'student') {
    if (!u.classroomId) return ok(res, { groups: [] });
    filter = { classroomId: u.classroomId, isActive: true, $or: [{ wholeClass: true }, { studentIds: u._id }] };
  } else if (u.role === 'school_admin') {
    filter = { schoolId: u.schoolId, isActive: true };
  } else {
    filter = { teacherIds: u._id, isActive: true };
  }
  const groups = await SchoolGroup.find(filter).sort({ lastMessageAt: -1, createdAt: -1 }).limit(100);
  ok(res, { groups: await Promise.all(groups.map((g) => groupView(g, u))) });
});

/** POST /school/groups { classroomId, name, description?, subject?, wholeClass, studentIds?, announcementsOnly? } */
const createGroup = wrap(async (req, res) => {
  const b = req.body || {};
  requireId(b.classroomId, 'class id');
  const room = await Classroom.findById(b.classroomId);
  if (!room || !room.isActive) throw new HttpError('Class not found', 404);
  const a = await classroomAccess(req.user, room);
  if (!a.canView) throw new HttpError('You can only create groups for classes you teach.', 403);
  const name = String(b.name || '').trim();
  if (name.length < 2) throw new HttpError('Give the group a name.');
  const wholeClass = b.wholeClass !== false;
  const studentIds = wholeClass ? [] : await cleanStudentIds(room._id, b.studentIds);
  if (!wholeClass && !studentIds.length) throw new HttpError('Choose at least one student.');
  const g = await SchoolGroup.create({
    schoolId: room.schoolId,
    classroomId: room._id,
    subject: b.subject ? String(b.subject).trim() : undefined,
    name,
    description: b.description ? String(b.description).trim() : undefined,
    createdBy: req.user._id,
    teacherIds: [req.user._id],
    wholeClass,
    studentIds,
    announcementsOnly: !!b.announcementsOnly,
  });
  const members = await memberStudentIds(g);
  await notifyUsers(members, { title: 'New class group', message: `${req.user.fullName} added you to "${name}"`, type: 'school', data: { kind: 'group', groupId: String(g._id), route: `/school/groups/${g._id}` }, push: false });
  ok(res, { group: await groupView(g, req.user) }, 'Group created', 201);
});

/** GET /school/groups/:id — group with members. */
const getGroup = wrap(async (req, res) => {
  const { g } = await loadGroup(req);
  ok(res, { group: await groupView(g, req.user, { withMembers: true }) });
});

/** PATCH /school/groups/:id { name?, description?, announcementsOnly?, wholeClass?, studentIds?, addTeacherId?, removeTeacherId? } */
const updateGroup = wrap(async (req, res) => {
  const { g, teacher } = await loadGroup(req);
  if (!teacher) throw new HttpError('Only the group\'s teachers can change it.', 403);
  const b = req.body || {};
  if (b.name !== undefined) { if (String(b.name).trim().length < 2) throw new HttpError('Give the group a name.'); g.name = String(b.name).trim(); }
  if (b.description !== undefined) g.description = String(b.description).trim();
  if (b.announcementsOnly !== undefined) g.announcementsOnly = !!b.announcementsOnly;
  if (b.wholeClass !== undefined) g.wholeClass = !!b.wholeClass;
  if (b.studentIds !== undefined) g.studentIds = await cleanStudentIds(g.classroomId, b.studentIds);
  if (!g.wholeClass && !g.studentIds.length) throw new HttpError('Choose at least one student.');
  if (b.addTeacherId) {
    requireId(b.addTeacherId, 'teacher id');
    const t = await User.findOne({ _id: b.addTeacherId, schoolId: g.schoolId, role: { $in: ['instructor', 'school_admin'] }, isActive: true }).select('_id').lean();
    if (!t) throw new HttpError('Teacher not found in this school.', 404);
    if (!g.teacherIds.some((x) => same(x, t._id))) g.teacherIds.push(t._id);
  }
  if (b.removeTeacherId) {
    g.teacherIds = g.teacherIds.filter((x) => !same(x, b.removeTeacherId));
    if (!g.teacherIds.length) throw new HttpError('A group needs at least one teacher.');
  }
  await g.save();
  ok(res, { group: await groupView(g, req.user, { withMembers: true }) }, 'Group saved');
});

/** DELETE /school/groups/:id — archives the group (messages are kept for the school). */
const archiveGroup = wrap(async (req, res) => {
  const { g, teacher } = await loadGroup(req);
  if (!teacher) throw new HttpError('Only the group\'s teachers can remove it.', 403);
  g.isActive = false;
  await g.save();
  ok(res, { id: String(g._id) }, 'Group closed');
});

/** GET /school/groups/:id/messages?before=<iso>&after=<iso> — newest first page, or new since `after`. */
const listMessages = wrap(async (req, res) => {
  const { g, teacher } = await loadGroup(req);
  const filter = { groupId: g._id };
  if (req.query.after) filter.createdAt = { $gt: new Date(req.query.after) };
  else if (req.query.before) filter.createdAt = { $lt: new Date(req.query.before) };
  const list = await GroupMessage.find(filter).populate('authorId', 'fullName role').sort({ createdAt: -1 }).limit(PAGE).lean();
  // Mark as read.
  await SchoolGroup.updateOne({ _id: g._id }, { $set: { [`lastRead.${req.user._id}`]: new Date() } });
  const pinned = await GroupMessage.find({ groupId: g._id, pinned: true, deletedAt: null }).populate('authorId', 'fullName role').sort({ createdAt: -1 }).limit(3).lean();
  ok(res, {
    messages: list.reverse().map((m) => messageView(m, req.user, teacher)),
    pinned: pinned.map((m) => messageView(m, req.user, teacher)),
    hasMore: list.length === PAGE,
    canPost: teacher || !g.announcementsOnly,
  });
});

/** POST /school/groups/:id/messages { text?, attachments?, replyTo? } */
const postMessage = wrap(async (req, res) => {
  const { g, teacher } = await loadGroup(req);
  if (!teacher && g.announcementsOnly) throw new HttpError('Only teachers can post in this group.', 403);
  const text = String(req.body?.text || '').trim();
  const attachments = cleanAttachments(req.body?.attachments);
  if (!text && !attachments.length) throw new HttpError('Write a message first.');
  let replyTo = null;
  if (req.body?.replyTo) {
    requireId(req.body.replyTo, 'message id');
    if (await GroupMessage.exists({ _id: req.body.replyTo, groupId: g._id })) replyTo = req.body.replyTo;
  }
  const m = await GroupMessage.create({ groupId: g._id, authorId: req.user._id, text, attachments, replyTo });
  await SchoolGroup.updateOne({ _id: g._id }, { $set: { lastMessageAt: m.createdAt, [`lastRead.${req.user._id}`]: m.createdAt } });
  if (teacher && g.announcementsOnly) {
    const members = await memberStudentIds(g);
    await notifyUsers(members, { title: g.name, message: text.slice(0, 140) || 'New announcement', type: 'school', data: { kind: 'group', groupId: String(g._id), route: `/school/groups/${g._id}` } });
  }
  await m.populate('authorId', 'fullName role');
  ok(res, { message: messageView(m.toObject(), req.user, teacher) }, 'Sent', 201);
});

/** DELETE /school/groups/:id/messages/:messageId — own message, or any message for teachers. */
const deleteMessage = wrap(async (req, res) => {
  const { g, teacher } = await loadGroup(req);
  requireId(req.params.messageId, 'message id');
  const m = await GroupMessage.findOne({ _id: req.params.messageId, groupId: g._id });
  if (!m) throw new HttpError('Message not found', 404);
  if (!teacher && !same(m.authorId, req.user._id)) throw new HttpError('You can only delete your own messages.', 403);
  m.deletedAt = new Date();
  m.deletedBy = req.user._id;
  m.pinned = false;
  await m.save();
  ok(res, { id: String(m._id) }, 'Deleted');
});

/** POST /school/groups/:id/messages/:messageId/pin { pinned } — teachers. */
const pinMessage = wrap(async (req, res) => {
  const { g, teacher } = await loadGroup(req);
  if (!teacher) throw new HttpError('Only teachers can pin messages.', 403);
  requireId(req.params.messageId, 'message id');
  const m = await GroupMessage.findOneAndUpdate({ _id: req.params.messageId, groupId: g._id, deletedAt: null }, { pinned: req.body?.pinned !== false }, { returnDocument: 'after' });
  if (!m) throw new HttpError('Message not found', 404);
  ok(res, { id: String(m._id), pinned: m.pinned });
});

module.exports = { myGroups, createGroup, getGroup, updateGroup, archiveGroup, listMessages, postMessage, deleteMessage, pinMessage };
