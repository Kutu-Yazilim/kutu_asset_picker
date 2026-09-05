import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/picker_tuning.dart';
import '../providers/albums_provider.dart';
import '../text/asset_picker_text.dart';
import '../text/asset_picker_text_provider.dart';
import '../theme/asset_picker_theme.dart';
import '../theme/resolved_asset_picker_theme.dart';

/// The permanent limited-access bar (design §2.10).
///
/// Permanent, not dismissible: it is the only affordance a limited user has for
/// changing what this app can see, and a user who cannot find their photo needs
/// it at exactly the moment they would already have dismissed it.
///
/// The tap is a single notifier call — presenting the OS UI *and* reconciling
/// the stale album list afterwards both live in
/// [AssetPickerAlbums.manageLimitedSelection] (Flutter rule 6).
class LimitedAccessBar extends ConsumerWidget {
  const LimitedAccessBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ResolvedAssetPickerTheme theme = AssetPickerTheme.resolve(context);
    final AssetPickerText text = ref.watch(assetPickerTextProvider);

    return ColoredBox(
      color: theme.surface,
      child: Padding(
        padding: PickerChromeSizes.limitedBarPadding,
        child: Row(
          children: <Widget>[
            Expanded(
              child: Text(
                text.pickerLimitedBanner,
                style: theme.labelStyle.copyWith(color: theme.onSurfaceMuted),
              ),
            ),
            TextButton(
              onPressed: ref
                  .read(assetPickerAlbumsProvider.notifier)
                  .manageLimitedSelection,
              child: Text(
                text.pickerManageSelection,
                style: theme.labelStyle.copyWith(color: theme.onSurface),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
