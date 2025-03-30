import 'package:uuid/v1.dart';
import 'package:uuid/v4.dart';
import 'package:uuid/v6.dart';
import 'package:uuid/v7.dart';

/// A utility class for generating UUIDs (Universally Unique Identifiers)
/// of different versions.
///
/// This class provides static methods to generate UUIDs following versions
/// 1, 4, 6, and 7 of the UUID specification. It cannot be instantiated.
class IdGenerator {
  /// Private constructor to prevent instantiation.
  /// This class is meant to be used statically.
  const IdGenerator._();

  /// Version 1 UUID generator (time-based)
  static const UuidV1 v1 = UuidV1();

  /// Version 4 UUID generator (random)
  static const UuidV4 v4 = UuidV4();

  /// Version 6 UUID generator (reordered time-based)
  static const UuidV6 v6 = UuidV6();

  /// Version 7 UUID generator (Unix Epoch time-based)
  static const UuidV7 v7 = UuidV7();

  /// Generates a UUID string of the specified version.
  ///
  /// [version]: The UUID version to generate (1, 4, 6, or 7).
  ///            Defaults to 1 if not specified or if an invalid version is provided.
  ///            Values are clamped between 1 and 7.
  ///
  /// Returns a UUID string according to the requested version specification.
  /// If the version is not supported (2, 3, 5, or any other number),
  /// falls back to version 1 UUID.
  static String gen({int version = 1}) {
    // Ensure version is within valid range (1-7)
    version = version.clamp(1, 7);

    switch (version) {
      case 1:
        return v1.generate();
      case 4:
        return v4.generate();
      case 6:
        return v6.generate();
      case 7:
        return v7.generate();
      default:
        // Fallback to version 1 for any other number (though clamp prevents this)
        return v1.generate();
    }
  }
}
