import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/picker_tuning.dart';
import '../providers/albums_provider.dart';
import '../text/asset_picker_text.dart';
import '../text/asset_picker_text_provider.dart';
import '../theme/asset_picker_theme.dart';
import '../theme/resolved_asset_picker_theme.dart';

/// The empty state under limited access.
///
/// **This screen must never say "no photos found."** Neither OS reports which
/// media kinds are in a limited selection, so requesting images while the user
/// granted only videos produces `limited` plus zero results — a state that is
/// indistinguishable from an empty library (design §4.2). Asserting emptiness
/// here would be the picker telling the user something false about their own
/// device.
///
/// So it states what is actually known — the visible set is the granted set —
/// and offers the one control that changes it.
class LimitedEmptyView extends ConsumerWidget {
  const LimitedEmptyView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ResolvedAssetPickerTheme theme = AssetPickerTheme.resolve(context);
    final AssetPickerText text = ref.watch(assetPickerTextProvider);

    return Padding(
      padding: PickerChromeSizes.statePadding,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Icon(
            Icons.filter_none_outlined,
            size: PickerChromeSizes.stateIconSize,
            color: theme.onSurfaceMuted,
          ),
          const SizedBox(height: PickerChromeSizes.stateSpacing),
          Text(
            text.pickerEmptyLimited,
            textAlign: TextAlign.center,
            style: theme.labelStyle.copyWith(color: theme.onSurfaceMuted),
          ),
          const SizedBox(height: PickerChromeSizes.stateSpacing),
          FilledButton(
            onPressed: ref
                .read(assetPickerAlbumsProvider.notifier)
                .manageLimitedSelection,
            child: Text(text.pickerManageSelection),
          ),
        ],
      ),
    );
  }
}
