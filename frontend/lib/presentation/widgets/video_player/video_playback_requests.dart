import 'package:flutter/foundation.dart';

/// Lets the screen hosting a player ask it to start or stop, e.g. play when the
/// student jumps to the video and pause when they scroll away from it.
///
/// A play request made before the player has loaded is honoured once it has.
class VideoPlaybackRequests extends ChangeNotifier {
  bool _wantsPlay = false;
  bool get wantsPlay => _wantsPlay;

  void play() {
    _wantsPlay = true;
    notifyListeners();
  }

  void pause() {
    // Always notify: the student may have started playback with the player's
    // own controls, which this object never hears about.
    _wantsPlay = false;
    notifyListeners();
  }
}
