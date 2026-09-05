import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/library_empty_provider.dart';
import 'asset_grid.dart';
import 'limited_access_bar.dart';
import 'limited_empty_view.dart';

/// Limited access: the bar, then the same grid every other user gets.
///
/// [scrollController] is the sheet's controller in sheet mode and null in page
/// mode; it is threaded straight through to the grid.
class LimitedAccessBody extends ConsumerWidget {
  const LimitedAccessBody({super.key, this.scrollController});

  final ScrollController? scrollController;

  @override
  Widget build(BuildContext context, WidgetRef ref) => Column(
        children: <Widget>[
          const LimitedAccessBar(),
          Expanded(
            child: ref.watch(pickerLibraryEmptyProvider)
                ? const LimitedEmptyView()
                : AssetGrid(scrollController: scrollController),
          ),
        ],
      );
}
