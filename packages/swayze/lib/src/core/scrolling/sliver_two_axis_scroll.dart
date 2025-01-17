import 'dart:async';

import 'package:flutter/widgets.dart';

import '../../../controller.dart';
import '../../../widgets.dart';
import '../../config.dart' as config;
import '../../widgets/internal_scope.dart';
import '../controller/scroll/scroll_controller.dart';
import '../viewport_context/viewport_context_provider.dart';
import '../virtualization/virtualization_calculator.dart';
import 'pointer_scroll_detector.dart';
import 'sliver_scrolling_data_builder.dart';

/// The value in pixels in which defines as a severe table size change.
///
/// Table size changes bigger than this will receive a longer
/// intrinsic animation.
const _kSevereTableSizeChangeThreshold = config.kDefaultCellWidth * 2;

/// A signature for callbacks that receive [VirtualizationState.displacement]
/// of the two axis of scroll.
typedef TwoAxisScrollBuilder = Widget Function(
  BuildContext context,
  double verticalDisplacement,
  double horizontalDisplacement,
  bool isOffscreen,
);

/// A sliver that renders a [SliverScrollingDataBuilder] in two axis.
///
/// For the vertical axis it relies on an external scroll view, usually
/// [CustomScrollView]
/// For the horizontal axis, it contains an internal scroll view with
/// [SliverScrollingDataBuilder]
///
/// For each axis, this widget contains a [VirtualizationCalculator] in which
/// its provided virtualization state is passed as arguments to
/// [twoAxisScrollBuilder].
class SliverTwoAxisScroll extends StatefulWidget {
  /// A callback to be built with the virtualization states generated by each
  /// axis's [VirtualizationCalculator].
  final TwoAxisScrollBuilder twoAxisScrollBuilder;

  /// The amount of pixels to compensate the sticky header passed via
  /// [SliverSwayzeTable.stickyHeader].
  final double paddingTop;

  /// The [ScrollController] that manages the external vertical scroll view.
  final ScrollController verticalScrollController;

  /// See [SliverSwayzeTable.wrapBox]
  final WrapBoxBuilder? wrapBox;

  const SliverTwoAxisScroll({
    Key? key,
    required this.twoAxisScrollBuilder,
    required this.paddingTop,
    required this.verticalScrollController,
    required this.wrapBox,
  }) : super(key: key);

  @override
  _SliverTwoAxisScrollState createState() => _SliverTwoAxisScrollState();
}

class _SliverTwoAxisScrollState extends State<SliverTwoAxisScroll> {
  late final tableDataController =
      InternalScope.of(context).controller.tableDataController;

  /// The internal [ScrollController] that manages the horizontal scroll view.
  late final horizontalScrollController = ScrollController();

  @override
  void dispose() {
    horizontalScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<SwayzeHeaderState>(
      valueListenable: tableDataController.rows,
      builder: (context, rowsState, child) {
        final leadingPadding = widget.paddingTop + config.kColumnHeaderHeight;
        // The total height of the table in pixels, including the column header
        // and the paddingTop
        final verticalExtent = rowsState.extent + leadingPadding;

        return _TableSizeImplicitAnimation(
          extent: verticalExtent,
          builder: (context, double verticalExtent, Widget? child) {
            return SliverScrollingDataBuilder(
              leadingPadding: leadingPadding,
              extent: verticalExtent,
              contentBuilder: (
                BuildContext context,
                ScrollingData verticalScrollingData,
              ) {
                return VirtualizationCalculator(
                  headerSize: tableDataController.columnHeaderHeight(),
                  scrollingData: verticalScrollingData,
                  axis: Axis.vertical,
                  frozenAmount: rowsState.frozenCount,
                  contentBuilder: (context, verticalVirtualizationState) {
                    return ValueListenableBuilder<SwayzeHeaderState>(
                      valueListenable: tableDataController.columns,
                      builder: (context, columnsState, child) {
                        final rowHeaderWidth =
                            tableDataController.rowHeaderWidthForRange(
                          verticalVirtualizationState.rangeNotifier.value,
                        );

                        // The total width of the table in pixels, including
                        // the rows header.
                        final horizontalExtent =
                            columnsState.extent + rowHeaderWidth;

                        return _TableSizeImplicitAnimation(
                          extent: horizontalExtent,
                          builder: (
                            context,
                            double horizontalExtent,
                            Widget? child,
                          ) {
                            final horizontalCustomSliver =
                                SliverScrollingDataBuilder(
                              leadingPadding: rowHeaderWidth,
                              extent: horizontalExtent,
                              contentBuilder:
                                  (context, horizontalScrollingData) {
                                return VirtualizationCalculator(
                                  headerSize: rowHeaderWidth,
                                  scrollingData: horizontalScrollingData,
                                  axis: Axis.horizontal,
                                  frozenAmount: columnsState.frozenCount,
                                  contentBuilder: (
                                    context,
                                    horizontalVirtualizationState,
                                  ) {
                                    return _buildContent(
                                      context,
                                      horizontalVirtualizationState,
                                      verticalVirtualizationState,
                                    );
                                  },
                                );
                              },
                            );
                            return SizedBox(
                              width: horizontalExtent,
                              height: verticalScrollingData.viewportExtent,
                              child: CustomScrollView(
                                controller: horizontalScrollController,
                                scrollDirection: Axis.horizontal,
                                slivers: [horizontalCustomSliver],
                              ),
                            );
                          },
                        );
                      },
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }

  /// Build content inside slivers in both axis.
  Widget _buildContent(
    BuildContext context,
    VirtualizationState horizontalVirtualizationState,
    VirtualizationState verticalVirtualizationState,
  ) {
    // get the scrolling data that triggered this build
    final horizontalScrollingData = horizontalVirtualizationState.scrollingData;
    final verticalScrollingData = verticalVirtualizationState.scrollingData;

    // In case of non exhibition of a table, tell the content builder it is
    // offscreen in order to avoid unnecessary builds.
    final isOffscreen = verticalScrollingData.viewportExtent == 0 ||
        verticalScrollingData.constraints.scrollOffset >=
            tableDataController.rows.value.extent;

    Widget content = ViewportContextProvider(
      horizontalVirtualizationState: horizontalVirtualizationState,
      verticalVirtualizationState: verticalVirtualizationState,
      child: ScrollControllerAttacher(
        horizontalScrollController: horizontalScrollController,
        verticalScrollController: widget.verticalScrollController,
        child: Padding(
          padding: EdgeInsets.only(top: widget.paddingTop),
          child: SizedBox(
            width: horizontalScrollingData.viewportExtent,
            height: verticalScrollingData.remainingContentExtent,
            child: PointerScrollDetector(
              horizontalScrollController: horizontalScrollController,
              verticalScrollController: widget.verticalScrollController,
              child: widget.twoAxisScrollBuilder(
                context,
                verticalVirtualizationState.displacement,
                horizontalVirtualizationState.displacement,
                isOffscreen,
              ),
            ),
          ),
        ),
      ),
    );

    // Add wrapBox right underneath the scroll views
    final wrapBox = widget.wrapBox;
    if (wrapBox != null) {
      content = wrapBox(context, content);
    }

    return content;
  }
}

/// A [Widget] that animates between changes on [extent].
///
/// It animates retractions but not animates expansions.
class _TableSizeImplicitAnimation extends StatefulWidget {
  final ValueWidgetBuilder<double> builder;
  final double extent;

  const _TableSizeImplicitAnimation({
    Key? key,
    required this.builder,
    required this.extent,
  }) : super(key: key);

  @override
  State<_TableSizeImplicitAnimation> createState() =>
      _TableSizeImplicitAnimationState();
}

class _TableSizeImplicitAnimationState
    extends State<_TableSizeImplicitAnimation> {
  late double cacheExtent = widget.extent;

  Duration duration = Duration.zero;

  Timer? _animateRepeatDebounce;

  void restartDebounce() {
    _animateRepeatDebounce?.cancel();
    _animateRepeatDebounce = Timer(
      config.kDefaultScrollAnimationDuration,
      () => _animateRepeatDebounce = null,
    );
  }

  @override
  void didUpdateWidget(_TableSizeImplicitAnimation oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.extent != oldWidget.extent) {
      final isDeltaSeverelyNegative =
          widget.extent - oldWidget.extent < -_kSevereTableSizeChangeThreshold;
      final isDebounceActive = _animateRepeatDebounce?.isActive ?? false;
      // Then the value change to a smaller value, animate it. When it expands,
      // make a sudden change.

      if (isDebounceActive) {
        // When repeated table extent changes occur, do not animate
        duration = Duration.zero;
      } else if (isDeltaSeverelyNegative) {
        // When the table extent changes to a severely smaller value at once,
        // perform a longer animation
        duration = config.kDefaultScrollAnimationDuration * 3;
      } else {
        duration = config.kDefaultScrollAnimationDuration;
      }
      restartDebounce();
      setState(() {
        cacheExtent = widget.extent;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: cacheExtent),
      duration: duration,
      curve: kDefaultScrollAnimationCurve,
      builder: widget.builder,
    );
  }
}
