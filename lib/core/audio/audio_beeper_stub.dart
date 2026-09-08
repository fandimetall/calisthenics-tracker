import 'package:flutter/services.dart';

void playBeep(double freq, double duration) {
  SystemSound.play(SystemSoundType.click);
}

void playFinished() {
  SystemSound.play(SystemSoundType.click);
}
