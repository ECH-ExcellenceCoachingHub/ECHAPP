import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Game-style reward sounds for learning milestones.
///
/// Sounds live in `assets/sounds/` (CC0, see CREDITS.md). They grow with the
/// size of the achievement: a quick ding for a lesson, a short jingle for a
/// chapter or quiz, the longest fanfare for finishing a whole course.
enum AchievementSound {
  lessonComplete('lesson_complete.mp3'),
  xpGain('xp_gain.mp3'),
  achievementUnlocked('achievement_unlocked.mp3'),
  quizPassed('quiz_passed.mp3'),
  quizFailed('quiz_failed.mp3'),
  chapterComplete('chapter_complete.mp3'),
  certificateEarned('certificate_earned.mp3'),
  courseComplete('course_complete.mp3');

  final String file;
  const AchievementSound(this.file);
}

class AchievementSoundService {
  AchievementSoundService._();
  static final AchievementSoundService instance = AchievementSoundService._();

  static const _prefsKey = 'achievement_sounds_enabled';
  static const double _volume = 0.7;

  final Map<AchievementSound, AudioPlayer> _players = {};
  bool _enabled = true;
  bool _loaded = false;

  bool get isEnabled => _enabled;

  /// Reads the saved on/off setting (for showing it in Settings).
  Future<bool> loadEnabled() async {
    await _ensureLoaded();
    return _enabled;
  }

  Future<void> _ensureLoaded() async {
    if (_loaded) return;
    _loaded = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      _enabled = prefs.getBool(_prefsKey) ?? true;
    } catch (_) {
      // Keep the default if preferences are unavailable.
    }
  }

  Future<void> setEnabled(bool enabled) async {
    _enabled = enabled;
    _loaded = true;
    if (!enabled) {
      for (final p in _players.values) {
        p.stop();
      }
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_prefsKey, enabled);
    } catch (_) {}
  }

  /// Plays [sound] without waiting for it to finish. Never throws: a missing
  /// audio device must not break the celebration UI it accompanies.
  Future<void> play(AchievementSound sound) async {
    await _ensureLoaded();
    if (!_enabled) return;
    try {
      // One player per sound so a quick "xp" ding doesn't cut off a fanfare.
      final player = _players.putIfAbsent(sound, () {
        final p = AudioPlayer();
        // Celebration sounds should mix with, not interrupt, other audio
        // such as a paused lesson video.
        p.setAudioContext(AudioContextConfig(focus: AudioContextConfigFocus.mixWithOthers).build());
        return p;
      });
      await player.stop();
      await player.play(AssetSource('sounds/${sound.file}'), volume: _volume);
    } catch (e) {
      debugPrint('Achievement sound "${sound.name}" failed: $e');
    }
  }

  /// Plays [first], then [second] once a short gap has passed — e.g. a quiz
  /// jingle followed by the XP ding.
  Future<void> playSequence(AchievementSound first, AchievementSound second,
      {Duration gap = const Duration(milliseconds: 900)}) async {
    await play(first);
    await Future.delayed(gap);
    await play(second);
  }
}
