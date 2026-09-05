import 'package:flutter/foundation.dart';

import 'picker_enums.dart';

/// One entry in the ratio menu.
///
/// The digits are authored exactly once, here — consumers pass these constants
/// rather than repeating `4 / 5` at each call site.
@immutable
final class CropAspect {
  /// Creates a [CropAspect].
  const CropAspect({required this.x, required this.y, required this.label});

  /// An arbitrary ratio that is not one of the named shapes.
  const CropAspect.custom(this.x, this.y) : label = CropAspectLabel.custom;

  /// The x.
  final double x;

  /// The y.
  final double y;

  /// The label.
  final CropAspectLabel label;

  /// The ratio.
  double get ratio => x / y;

  /// The square.
  static const CropAspect square =
      CropAspect(x: 1, y: 1, label: CropAspectLabel.square);

  /// The portrait45.
  static const CropAspect portrait45 =
      CropAspect(x: 4, y: 5, label: CropAspectLabel.portrait);

  /// The landscape169.
  static const CropAspect landscape169 =
      CropAspect(x: 16, y: 9, label: CropAspectLabel.landscape);

  /// The story916.
  static const CropAspect story916 =
      CropAspect(x: 9, y: 16, label: CropAspectLabel.story);

  /// The banner31.
  static const CropAspect banner31 =
      CropAspect(x: 3, y: 1, label: CropAspectLabel.banner);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CropAspect &&
          other.x == x &&
          other.y == y &&
          other.label == label;

  @override
  int get hashCode => Object.hash(x, y, label);

  @override
  String toString() => 'CropAspect(${x.toStringAsFixed(0)}:'
      '${y.toStringAsFixed(0)}, $label)';
}
