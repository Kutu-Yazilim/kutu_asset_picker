/// A themeable, embeddable asset picker with first-class limited-access
/// support and no native code of its own.
///
/// See `package:kutu_asset_picker/testing.dart` for [FakeAssetSource].
library;

export 'src/source/picker_album.dart';
export 'src/source/picker_asset.dart';
export 'src/source/picker_media_type.dart';
export 'src/source/picker_permission.dart';
export 'src/config/asset_picker_config.dart';
export 'src/config/crop_aspect.dart';
export 'src/config/picker_enums.dart';
export 'src/config/picker_tuning.dart';
export 'src/source/asset_source.dart';
export 'src/source/photo_manager_asset_source.dart';
export 'src/source/picker_asset_image_provider.dart';
export 'src/source/picker_asset_key.dart';
export 'src/camera/picker_camera_delegate.dart';
export 'src/providers/injection_providers.dart';
export 'src/providers/permission_provider.dart';
export 'src/providers/albums_provider.dart';
export 'src/providers/asset_page_provider.dart';
export 'src/providers/selection_provider.dart';
export 'src/theme/asset_picker_theme.dart';
export 'src/theme/resolved_asset_picker_theme.dart';
export 'src/text/asset_picker_text.dart';
export 'src/text/asset_picker_text_en.dart';
export 'src/providers/camera_capture_provider.dart';
export 'src/providers/picker_commit_provider.dart';
export 'src/source/asset_availability.dart';
export 'src/providers/library_empty_provider.dart';
export 'src/picker/asset_picker_view.dart';
export 'src/picker/picker_grid_step.dart';

// Result
export 'src/result/asset_picker_result.dart';
export 'src/result/picked_asset.dart';

// Crop state and math — the math is exported because slice 5 and any consumer
// building a custom crop surface need it, and it is pure and stable.
export 'src/crop/crop_math.dart';
export 'src/crop/crop_state.dart';

// Export pipeline
export 'src/export/export_failure.dart';
export 'src/export/export_progress.dart';
export 'src/export/export_queue.dart';

// Theme and text — only this slice's new files; slice 3 exports the rest.
export 'src/text/asset_picker_text_locale.dart';
export 'src/text/asset_picker_text_scope.dart';
export 'src/text/asset_picker_text_tr.dart';
export 'src/theme/asset_picker_theme_scope.dart';

// Providers a consumer overrides or watches
export 'src/crop/crop_providers.dart';
export 'src/export/export_controller.dart';
export 'src/view/picker_step_controller.dart';

// Entry points — `src/picker/asset_picker_view.dart` is slice 3's export and
// already there; Task 17 changed its contents, not its path.
export 'src/view/asset_picker_scope.dart';
export 'src/view/kutu_asset_picker.dart';

// Video (slice 5)
export 'src/crop/video/scrubber_mode.dart' show ScrubberMode;
export 'src/crop/video/video_rejection.dart'
    show
        VideoRejectedException,
        VideoRejection,
        VideoTooLarge,
        VideoTooLong,
        VideoUnavailableException;
