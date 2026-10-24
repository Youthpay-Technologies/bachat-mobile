import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Include the bundled fonts in Flutter's native license viewer.
abstract final class BachatLicenses {
  static bool _registered = false;

  static void register() {
    if (_registered) return;
    _registered = true;
    LicenseRegistry.addLicense(() async* {
      for (final font in {
        'Instrument Sans': 'InstrumentSans-OFL.txt',
        'Instrument Serif': 'InstrumentSerif-OFL.txt',
        'Inter': 'Inter-OFL.txt',
      }.entries) {
        yield LicenseEntryWithLineBreaks([
          font.key,
        ], await rootBundle.loadString('assets/fonts/${font.value}'));
      }
    });
  }
}
