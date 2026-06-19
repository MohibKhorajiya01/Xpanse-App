import 'package:flutter/material.dart';

/// Returns an [Icon] widget built from a dynamic icon codepoint stored in the
/// database. Using this helper (instead of a bare `IconData(...)` literal)
/// prevents the Flutter release-build tree-shaker from complaining about
/// non-constant IconData invocations.
Widget buildIcon(
  int codepoint, {
  Color? color,
  double? size,
}) {
  // ignore: deprecated_member_use
  return Icon(
    IconData(codepoint, fontFamily: 'MaterialIcons'),
    color: color,
    size: size,
  );
}

/// Returns just the [IconData] for a dynamic codepoint.  Use [buildIcon]
/// whenever you can; call this only when you need an [IconData] value
/// (e.g. for a [ListTile.leading] that already wraps in [Icon]).
IconData iconDataFromCodepoint(int codepoint) {
  return IconData(codepoint, fontFamily: 'MaterialIcons');
}
