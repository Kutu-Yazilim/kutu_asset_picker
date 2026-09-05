import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/picker_tuning.dart';
import '../providers/permission_provider.dart';
import '../source/picker_permission.dart';
import '../theme/asset_picker_theme_scope.dart';
import '../theme/resolved_asset_picker_theme.dart';
import 'full_access_body.dart';
import 'limited_access_body.dart';
import 'permission_denied_view.dart';

/// Chooses the screen for the library-access state (design §4.2).
///
/// The switch is **exhaustive over [PickerPermission]**, which is a stronger
/// guarantee than "branch on `hasAccess`, never on `isAuth`": an exhaustive
/// switch cannot silently funnel an unrecognised state into the denied branch,
/// and that funnel is precisely the `isAuth` bug in another costume. Adding a
/// fourth state would fail to compile here rather than quietly showing every
/// affected user an empty grid.
///
/// A permission check that *failed* renders the denied view on purpose: the
/// user's situation is identical — no library — and the denied view is the only
/// surface that carries a way out of it.
class PermissionGate extends ConsumerWidget {
  const PermissionGate({super.key, this.scrollController});

  /// The sheet's controller in sheet mode, null in page mode. Threaded through
  /// to whichever body ends up owning the grid.
  final ScrollController? scrollController;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ResolvedAssetPickerTheme theme = context.pickerTheme;

    return ref.watch(assetPickerPermissionProvider).when(
          loading: () => Center(
            child: CircularProgressIndicator(
              color: theme.progressIndicator,
              strokeWidth: PickerChromeSizes.progressStrokeWidth,
            ),
          ),
          error: (Object error, StackTrace stack) =>
              const PermissionDeniedView(),
          data: (PickerPermission permission) => switch (permission) {
            PickerPermission.full =>
              FullAccessBody(scrollController: scrollController),
            PickerPermission.limited =>
              LimitedAccessBody(scrollController: scrollController),
            PickerPermission.denied => const PermissionDeniedView(),
          },
        );
  }
}
