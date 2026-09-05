import 'package:flutter/foundation.dart';
import 'package:kutu_media_transform/kutu_media_transform.dart';

import '../source/picker_media_type.dart';
import 'crop_aspect.dart';
import 'picker_enums.dart';

/// Everything a consumer can configure. There are no builder slots in v1
/// (design §2.9): the widget tree is closed, and customization is this object
/// plus `AssetPickerTheme` plus the text delegate.
@immutable
final class AssetPickerConfig {
  const AssetPickerConfig({
    this.mediaTypes = const <PickerMediaType>{
      PickerMediaType.image,
      PickerMediaType.video,
    },
    this.minSelection = 1,
    this.maxSelection = 10,
    this.aspects = const <CropAspect>[
      CropAspect.square,
      CropAspect.portrait45,
      CropAspect.landscape169,
    ],
    this.initialAspect,
    this.allowPerAssetAspect = true,
    this.cropOverlayShape = CropOverlayShape.rectangle,
    this.gridColumns = 3,
    this.cellAspectRatio = 1.0,
    this.gridSpacing = 2.0,
    this.pickerSurface = PickerSurface.page,
    this.cropSurface = PickerSurface.page,
    this.enableCamera = true,
    this.enableCrop = true,
    this.enableTrim = true,
    this.enableCoverFrame = true,
    this.maxVideoDuration,
    this.maxSourceMegapixels,
    this.keepOriginals = false,
    this.imageEncode = const ImageEncodeSettings(),
    this.videoEncode = const VideoEncodeSettings(),
    this.thumbSize = const ThumbSize.square(200),
  })  : assert(minSelection >= 1, 'minSelection must be at least 1.'),
        assert(maxSelection >= minSelection,
            'maxSelection must be >= minSelection.'),
        assert(gridColumns >= 1, 'gridColumns must be at least 1.'),
        assert(cellAspectRatio > 0, 'cellAspectRatio must be positive.'),
        assert(gridSpacing >= 0, 'gridSpacing cannot be negative.');

  /// Which kinds the grid offers. Must not be empty; a const constructor
  /// cannot assert on a collection's length, so an empty set simply yields
  /// an empty grid and an empty [aspects] throws from [effectiveInitialAspect].
  final Set<PickerMediaType> mediaTypes;

  final int minSelection;

  /// `maxSelection: 1` is the single-pick mode.
  final int maxSelection;

  /// The ratio menu. A single-entry list is the forced-ratio mode.
  final List<CropAspect> aspects;

  final CropAspect? initialAspect;

  /// False collapses the aspect to one shared value for the whole batch.
  final bool allowPerAssetAspect;

  final CropOverlayShape cropOverlayShape;

  final int gridColumns;
  final double cellAspectRatio;
  final double gridSpacing;

  final PickerSurface pickerSurface;
  final PickerSurface cropSurface;

  final bool enableCamera;
  final bool enableCrop;
  final bool enableTrim;
  final bool enableCoverFrame;

  /// Both a trim clamp and a query-time filter (design §4.5).
  final Duration? maxVideoDuration;

  /// Honoured at decode, never after, so a full-size bitmap is never allocated
  /// (design §7.2).
  final int? maxSourceMegapixels;

  final bool keepOriginals;

  final ImageEncodeSettings imageEncode;
  final VideoEncodeSettings videoEncode;

  /// One flat, clamped thumbnail size for the whole grid.
  ///
  /// Per-cell DPR scaling multiplies cache keys, which is exactly the thing to
  /// avoid (design §4.4).
  final ThumbSize thumbSize;

  /// The aspect the crop step starts on.
  CropAspect get effectiveInitialAspect => initialAspect ?? aspects.first;
}
