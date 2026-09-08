import 'audio_beeper_stub.dart'
    if (dart.library.js_interop) 'audio_beeper_web.dart' as impl;

class AudioBeeper {
  static void countdown() {
    impl.playBeep(880.0, 0.12);
  }

  static void finished() {
    impl.playFinished();
  }
}
