import 'dart:js_interop' as js;

@js.JS('window.playWorkoutBeep')
external void _playWorkoutBeep(double freq, double duration);

@js.JS('window.playWorkoutWhistle')
external void _playWorkoutWhistle();

void playBeep(double freq, double duration) {
  try {
    _playWorkoutBeep(freq, duration);
  } catch (_) {}
}

void playFinished() {
  try {
    _playWorkoutWhistle();
  } catch (_) {}
}
