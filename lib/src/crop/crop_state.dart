import 'package:flutter/painting.dart';
import 'package:kutu_asset_picker/src/config/crop_aspect.dart';
import 'package:kutu_media_transform/kutu_media_transform.dart';
import 'package:flutter/foundation.dart';

/// One asset's framing.
///
/// Stores `scale` and `offset` rather than a `Matrix4` on purpose (contract
/// §6): a matrix is not value-comparable, cannot be `const`, and turns every
/// clamp assertion into matrix archaeology. The `Matrix4` is derived at paint
/// time by `cropMatrix`, in exactly one place.
///
/// `scale` and `offset` are expressed against `kCanonicalCropArea`, not against
/// whatever the device laid out — see the doc on that constant.
@immutable
final class CropState {
  /// Creates a [CropState].
  const CropState({
    required this.aspect,
    required this.scale,
    required this.offset,
    this.trim,
    this.coverAt,
  });

  /// The state of an asset that has not met a crop window yet.
  ///
  /// `scale: 0` is below every possible cover scale, so the first
  /// `reclampForAspect` raises it to exactly `scaleToCover` and centres it.
  /// That is deliberately a *read-time* normalization: nothing has to write to
  /// a provider during layout, which is illegal in Riverpod and would need a
  /// post-frame callback to work around.
  const CropState.unsized(CropAspect aspect)
      : this(aspect: aspect, scale: 0, offset: Offset.zero);

  /// The aspect.
  final CropAspect aspect;

  /// Multiplier on the source's own pixel size. Always `>= scaleToCover`
  /// after normalization.
  final double scale;

  /// Translation of the image centre away from the crop window centre.
  final Offset offset;

  /// Kept range of a video, relative to the source. Null for images.
  final DurationRange? trim;

  /// Where the poster frame is taken from. Null for images.
  final Duration? coverAt;

  /// True while this state is still the placeholder from [CropState.unsized].
  bool get isUnsized => scale == 0;

  /// Copy with.
  CropState copyWith({
    CropAspect? aspect,
    double? scale,
    Offset? offset,
    DurationRange? trim,
    Duration? coverAt,
  }) =>
      CropState(
        aspect: aspect ?? this.aspect,
        scale: scale ?? this.scale,
        offset: offset ?? this.offset,
        trim: trim ?? this.trim,
        coverAt: coverAt ?? this.coverAt,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CropState &&
          other.aspect == aspect &&
          other.scale == scale &&
          other.offset == offset &&
          other.trim == trim &&
          other.coverAt == coverAt;

  @override
  int get hashCode => Object.hash(aspect, scale, offset, trim, coverAt);

  @override
  String toString() =>
      'CropState($aspect, scale: $scale, offset: $offset, trim: $trim, '
      'coverAt: $coverAt)';
}
