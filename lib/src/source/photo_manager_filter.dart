import 'package:photo_manager/photo_manager.dart';

/// Fallbacks for an unconfigured filter.
abstract final class PickerFilterDefaults {
  const PickerFilterDefaults._();

  /// `DurationConstraint`'s own default max. Restating it keeps "no configured
  /// limit" explicit rather than implicit.
  static const Duration maxVideoDuration = Duration(days: 1);
}

/// Builds the query-time filter for album and asset listing.
///
/// Duration filtering happens here rather than in Dart because the platform
/// can do it in the query (design §4.5) — but with two non-obvious settings
/// that the defaults get wrong:
///
/// * `allowNullable: true`. The default `false` silently hides every asset
///   whose MediaStore duration column is null, which is a real set of files on
///   Android from some downloads and third-party recorders.
/// * `createTimeCond.ignore: true`. `FilterOptionGroup` defaults this to
///   `DateTimeCond.def()`, whose `max` is `DateTime.now()` evaluated at
///   construction — so an asset captured after the filter was built is
///   filtered out, including the one the camera tile just produced.
FilterOptionGroup buildPickerFilter({Duration? maxVideoDuration}) {
  const SizeConstraint anySize = SizeConstraint(ignoreSize: true);
  final DurationConstraint duration = DurationConstraint(
    max: maxVideoDuration ?? PickerFilterDefaults.maxVideoDuration,
    allowNullable: true,
  );

  return FilterOptionGroup(
    imageOption: const FilterOption(
      needTitle: false,
      sizeConstraint: anySize,
      durationConstraint: DurationConstraint(allowNullable: true),
    ),
    videoOption: FilterOption(
      needTitle: false,
      sizeConstraint: anySize,
      durationConstraint: duration,
    ),
    createTimeCond: DateTimeCond(
      min: DateTimeCond.zero,
      max: DateTimeCond.zero,
      ignore: true,
    ),
    orders: const <OrderOption>[
      OrderOption(type: OrderOptionType.createDate, asc: false),
    ],
  );
}
