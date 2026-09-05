import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/picker_tuning.dart';
import '../providers/permission_provider.dart';
import '../text/asset_picker_text.dart';
import '../text/asset_picker_text_scope.dart';
import '../theme/asset_picker_theme_scope.dart';
import '../theme/resolved_asset_picker_theme.dart';

/// The denied state: rationale, then the way out (design §4.2).
///
/// A `ConsumerStatefulWidget` because a [WidgetsBindingObserver] is a framework
/// object with a subscription lifetime — the one exception this package makes
/// to "all state values live in Riverpod". Nothing here is *state*; the
/// permission itself still lives in `assetPickerPermissionProvider`.
///
/// The resume hook is the general case, not a duplicate of the button: the user
/// can reach Settings through the app switcher, flip the grant, and come back
/// having never touched this screen. Returning from Settings is the only moment
/// a denied user becomes a granted one without an app restart.
class PermissionDeniedView extends ConsumerStatefulWidget {
  /// Creates a [PermissionDeniedView].
  const PermissionDeniedView({super.key});

  @override
  ConsumerState<PermissionDeniedView> createState() =>
      _PermissionDeniedViewState();
}

class _PermissionDeniedViewState extends ConsumerState<PermissionDeniedView>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) {
      return;
    }
    ref.read(permissionActionsProvider.notifier).recheck();
  }

  @override
  Widget build(BuildContext context) {
    final ResolvedAssetPickerTheme theme = context.pickerTheme;
    final AssetPickerText text = context.pickerText;

    return ColoredBox(
      color: theme.background,
      child: Padding(
        padding: PickerChromeSizes.statePadding,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(
              Icons.photo_library_outlined,
              size: PickerChromeSizes.stateIconSize,
              color: theme.onSurfaceMuted,
            ),
            const SizedBox(height: PickerChromeSizes.stateSpacing),
            Text(
              text.pickerPermissionDeniedTitle,
              textAlign: TextAlign.center,
              style: theme.titleStyle.copyWith(color: theme.onSurface),
            ),
            const SizedBox(height: PickerChromeSizes.stateSpacing),
            Text(
              text.pickerPermissionDeniedBody,
              textAlign: TextAlign.center,
              style: theme.labelStyle.copyWith(color: theme.onSurfaceMuted),
            ),
            const SizedBox(height: PickerChromeSizes.stateSpacing),
            FilledButton(
              onPressed:
                  ref.read(permissionActionsProvider.notifier).openSettings,
              child: Text(text.pickerOpenSettings),
            ),
          ],
        ),
      ),
    );
  }
}
