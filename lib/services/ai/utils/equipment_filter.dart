import '../models/user_profile.dart';

/// Mapping equipment JSON string → HomeEquipment enum.
///
/// Satu equipment JSON bisa cocok ke beberapa HomeEquipment.
/// Contoh: "bench_or_chair" → user butuh benchOrChair.
class EquipmentFilter {
  /// Cek apakah user punya equipment yang dibutuhkan exercise.
  ///
  /// Return true = user BISA melakukan exercise ini.
  static bool userCanDo(String exerciseEquipment, Set<HomeEquipment> userEquip) {
    final eq = exerciseEquipment.toLowerCase().trim();

    // Tidak butuh alat → semua bisa
    if (eq == 'none' || eq == 'wall' || eq == 'floor' || eq.isEmpty) {
      return true;
    }

    // Pull-up bar variants
    if (eq.contains('pull_up_bar') || eq.contains('rings')) {
      return userEquip.contains(HomeEquipment.pullUpBar);
    }

    // Resistance band
    if (eq.contains('resistance_band')) {
      return userEquip.contains(HomeEquipment.resistanceBand);
    }

    // Bench / chair / step / box
    if (eq.contains('bench') ||
        eq.contains('chair') ||
        eq.contains('step') ||
        eq.contains('box')) {
      return userEquip.contains(HomeEquipment.benchOrChair);
    }

    // Table / bar at waist height
    if (eq.contains('table') ||
        eq.contains('bar_at_waist') ||
        eq.contains('low_bar')) {
      return userEquip.contains(HomeEquipment.tableOrBar);
    }

    // Parallettes
    if (eq.contains('parallettes')) {
      return userEquip.contains(HomeEquipment.parallettes);
    }

    // Doorframe (kusen pintu) → anggap semua orang punya
    if (eq == 'doorframe') {
      return true;
    }

    // Anchor for feet (kaki di bawah sofa dll) → anggap semua bisa
    if (eq.contains('anchor')) {
      return true;
    }

    // Vertical pole / stall bars → butuh pull-up bar minimal
    if (eq.contains('pole') || eq.contains('stall')) {
      return userEquip.contains(HomeEquipment.pullUpBar);
    }

    // Weight belt / backpack → semua orang punya tas
    if (eq.contains('backpack') || eq.contains('weight')) {
      return true;
    }

    // Default: kalau tidak dikenali, izinkan
    return true;
  }
}
