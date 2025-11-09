import 'package:flutter/widgets.dart';

/// Small screen utilities for responsive sizing.
/// Use heightPct(context, 0.02) for 2% of screen height, etc.
class ScreenUtil {
  /// Returns [percent] of the screen height (0.0 - 1.0).
  static double heightPct(BuildContext context, double percent) {
    final h = MediaQuery.of(context).size.height;
    return h * percent;
  }

  /// Returns [percent] of the screen width (0.0 - 1.0).
  static double widthPct(BuildContext context, double percent) {
    final w = MediaQuery.of(context).size.width;
    return w * percent;
  }

  /// Convenience: compute font-size from a dSize base used in the app.
  /// Example: for `dSize * 0.39` use `fontFromD(dSize, 0.39)`.
  static double fontFromD(double dSize, double multiplier) {
    return dSize * multiplier;
  }
}
