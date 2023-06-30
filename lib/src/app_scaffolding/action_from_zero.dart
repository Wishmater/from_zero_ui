import 'package:flutter/material.dart';
import 'package:from_zero_ui/from_zero_ui.dart';
import 'package:from_zero_ui/src/app_scaffolding/scaffold_from_zero.dart';
import 'package:multi_value_listenable_builder/multi_value_listenable_builder.dart';



enum ActionState {
  none,
  popup,
  overflow,
  icon,
  button,
  expanded,
}
extension ActionStateExtension on ActionState {
  bool get shownOnPrimaryToolbar => this==ActionState.icon || this==ActionState.button || this==ActionState.expanded;
  bool get shownOnOverflowMenu => this==ActionState.overflow;
  bool get shownOnContextMenu => this==ActionState.icon || this==ActionState.button || this==ActionState.expanded || this==ActionState.overflow || this==ActionState.popup;
}

typedef void ContextCallback(BuildContext context);
typedef Widget ActionBuilder({
  required BuildContext context,
  required String title,
  Widget? icon,
  ContextCallback? onTap,
  bool enabled,
  Color? color,
});
typedef Widget OverflowActionBuilder({
  required BuildContext context,
  required String title,
  Widget? icon,
  ContextCallback? onTap,
  bool enabled,
  bool forceIconSpace,
});

class ActionFromZero extends StatelessWidget {

  /// callback called when icon/button/overflowMenuItem is clicked
  /// if null and expandedWidget!= null, will switch expanded
  final ContextCallback? onTap;
  final String title;
  final Widget? icon;
  final bool enabled;

  /// from each breakpoint up, the selected widget will be used
  /// defaults to overflow
  final Map<double, ActionState> breakpoints;

  int get uniqueId => Object.hashAll([title, icon]);

  /// optional callbacks to customize the look of the widget in its different states
  final OverflowActionBuilder overflowBuilder;
  Widget buildOverflow(BuildContext context, {bool forceIconSpace=false}) => overflowBuilder(context: context, title: title, icon: icon, onTap: onTap, enabled: enabled, forceIconSpace: forceIconSpace);

  final ActionBuilder iconBuilder;
  Widget buildIcon(BuildContext context, {
    Color? color,
  }) => iconBuilder(context: context, title: title, icon: icon, onTap: onTap, enabled: enabled, color: color);

  final ActionBuilder buttonBuilder;
  Widget buildButton(BuildContext context, {
    Color? color,
  }) => buttonBuilder(context: context, title: title, icon: icon, onTap: onTap, enabled: enabled, color: color);

  final ActionBuilder? expandedBuilder;
  Widget buildExpanded(BuildContext context, {
    Color? color,
  }) => expandedBuilder!(context: context, title: title, icon: icon, onTap: onTap, enabled: enabled, color: color);
  final bool centerExpanded;

  ActionFromZero({
    this.onTap,
    required this.title,
    this.icon,
    this.enabled = true,
    Map<double, ActionState>? breakpoints,
    this.overflowBuilder = defaultOverflowBuilder,
    this.iconBuilder = defaultIconBuilder,
    this.buttonBuilder = defaultButtonBuilder,
    this.expandedBuilder,
    this.centerExpanded = true,
  }) : this.breakpoints = breakpoints ?? {
    0: icon==null ? ActionState.overflow : ActionState.icon,
    ScaffoldFromZero.screenSizeLarge: expandedBuilder==null ? ActionState.button : ActionState.expanded,
  };

  ActionFromZero.divider({
    Map<double, ActionState>? breakpoints,
    this.overflowBuilder = dividerOverflowBuilder,
    this.iconBuilder = dividerIconBuilder,
    this.buttonBuilder = dividerIconBuilder,
  }) :  title = '',
        icon = null,
        onTap = null,
        expandedBuilder = null,
        centerExpanded = true,
        enabled = true,
        this.breakpoints = breakpoints ?? {
          0: ActionState.overflow,
          // ScaffoldFromZero.screenSizeLarge: ActionState.icon,
        };

  static final Function(BuildContext context)? nullOnTap = (context)=>null;
  ActionFromZero copyWith({
    void Function(BuildContext context)? onTap,
    String? title,
    Widget? icon,
    Map<double, ActionState>? breakpoints,
    OverflowActionBuilder? overflowBuilder,
    ActionBuilder? iconBuilder,
    ActionBuilder? buttonBuilder,
    ActionBuilder? expandedBuilder,
    bool? centerExpanded,
    bool? enabled,
  }) {
    return ActionFromZero(
      onTap: onTap==nullOnTap ? null : (onTap ?? this.onTap),
      title: title ?? this.title,
      icon: icon ?? this.icon,
      breakpoints: breakpoints ?? this.breakpoints,
      overflowBuilder: overflowBuilder ?? this.overflowBuilder,
      iconBuilder: iconBuilder ?? this.iconBuilder,
      buttonBuilder: buttonBuilder ?? this.buttonBuilder,
      expandedBuilder: expandedBuilder ?? this.expandedBuilder,
      centerExpanded: centerExpanded ?? this.centerExpanded,
      enabled: enabled ?? this.enabled,
    );
  }

  @override
  Widget build(BuildContext context) {
    return buildButton(context);
  }

  ActionState getStateForMaxWidth(double width) {
    ActionState state = ActionState.overflow;
    double biggestKey=-1;
    breakpoints.forEach((key, value) {
      if (key<=width && key>biggestKey){
        state = value;
        biggestKey = key;
      }
    });
    return state;
  }

  static Widget defaultAnimatedSwitcherBuilder({
    required Widget child,
  }) {
    return child; // TODO 3 implemet animating between action states, currently it breaks due to some change in Appbar
    return AnimatedSwitcher(
      duration: Duration(milliseconds: 300),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (child, animation) {
        return SizeTransition(
          sizeFactor: animation,
          axis: Axis.horizontal,
          axisAlignment: -1,
          child: child,
        );
      },
      child: child,
    );
  }

  static Widget defaultIconBuilder({
    required BuildContext context,
    required String title,
    Widget? icon,
    ContextCallback? onTap,
    bool enabled = true,
    Color? color,
  }) {
    color ??= Theme.of(context).appBarTheme.toolbarTextStyle?.color
        ?? (Theme.of(context).primaryColorBrightness==Brightness.light ? Colors.black : Colors.white);
    final transparentColor = color.withOpacity(0.05);
    final semiTransparentColor = color.withOpacity(0.1);
    return defaultAnimatedSwitcherBuilder(
      child: TooltipFromZero(
        message: title,
        child: IconButton(
          icon: icon ?? SizedBox.shrink(),
          color: color,
          hoverColor: transparentColor,
          highlightColor: semiTransparentColor,
          focusColor: semiTransparentColor,
          splashColor: semiTransparentColor,
          onPressed: (!enabled || onTap==null) ? null : (){
            onTap.call(context);
          },
        ),
      ),
    );
  }

  static Widget defaultButtonBuilder({
    required BuildContext context,
    required String title,
    Widget? icon,
    ContextCallback? onTap,
    bool enabled = true,
    Color? color,
  }) {
    color ??= Theme.of(context).appBarTheme.toolbarTextStyle?.color
        ?? (Theme.of(context).primaryColorBrightness==Brightness.light ? Colors.black : Colors.white);
    return defaultAnimatedSwitcherBuilder(
      child: SizedBox(
        height: 64,
        child: GestureDetector(
          onDoubleTap: () => (!enabled || onTap==null) ? null : onTap.call(context),
          child: TextButton(
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              primary: color,
            ),
            onPressed: (!enabled || onTap==null) ? null : (){
              onTap.call(context);
            },
            // onLongPress: () => null,
            child: IconTheme(
              data: IconThemeData(
                color: color,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(width: 8),
                  if (icon!=null)
                    icon,
                  if (icon!=null)
                    SizedBox(width: 6,),
                  Text(title,
                    style: TextStyle(
                      fontSize: 16,
                      color: color,
                    ),
                  ),
                  SizedBox(width: 8),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  static Widget defaultOverflowBuilder({
    required BuildContext context,
    required String title,
    Widget? icon,
    ContextCallback? onTap,
    bool enabled = true,
    bool forceIconSpace = false,
  }) {
    Widget result = Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (icon!=null) SizedBox(width: 12,),
          if (icon!=null) IconTheme(
            data: Theme.of(context).iconTheme.copyWith(
              color: !enabled || onTap==null
                  ? Theme.of(context).textTheme.caption!.color
                  : Theme.of(context).brightness==Brightness.light ? Colors.black45 : Colors.white,
            ),
            child: icon,
          ),
          if (icon==null && forceIconSpace) SizedBox(width: 36,),
          SizedBox(width: 12,),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: 2),
              child: Text(title,
                style: TextStyle(
                  fontSize: 16,
                  color: !enabled || onTap==null
                      ? Theme.of(context).textTheme.caption!.color
                      : Theme.of(context).textTheme.bodyText1!.color,
                ),
              ),
            ),
          ),
          SizedBox(width: 12,),
        ],
      ),
    );
    if (!enabled || onTap==null) {
      result = MouseRegion(
        cursor: SystemMouseCursors.forbidden,
        child: result,
      );
    }
    result = TextButton(
      onPressed: (!enabled || onTap==null) ? null : () => onTap.call(context),
      style: TextButton.styleFrom(
        padding: EdgeInsets.zero,
        primary: !enabled || onTap==null
            ? Theme.of(context).textTheme.caption!.color
            : Theme.of(context).textTheme.bodyText1!.color,
      ),
      child: result,
    );
    return result;
  }

  static Widget dividerIconBuilder({
    required BuildContext context,
    required String title,
    Widget? icon,
    ContextCallback? onTap,
    bool enabled = true,
    Color? color,
  }) {
    return VerticalDivider();
  }

  static Widget dividerOverflowBuilder({
    required BuildContext context,
    required String title,
    Widget? icon,
    ContextCallback? onTap,
    bool enabled = true,
    bool forceIconSpace = false,
  }) {
    return Divider();
  }

}





typedef void ApiActionCallback(BuildContext context, List<dynamic> data);
class APIActionFromZero extends ActionFromZero {

  final List<ValueNotifier> dependedNotifiers;
  final List<ApiProvider> Function(List<dynamic> values) providersBuilder;
  final ApiActionCallback? onTapApi;

  APIActionFromZero({
    this.onTapApi,
    required super.title,
    super.icon,
    super.enabled = true,
    super. breakpoints,
    required this.providersBuilder,
    this.dependedNotifiers = const [],
  });

  @override
  ActionBuilder get iconBuilder => apiIconBuilder;

  @override
  ActionBuilder get buttonBuilder => apiButtonBuilder;

  @override
  OverflowActionBuilder get overflowBuilder => apiOverflowBuilder;

  Widget apiIconBuilder({
    required BuildContext context,
    required String title,
    Widget? icon,
    ContextCallback? onTap,
    bool enabled = true,
    Color? color,
  }) {
    return MultiValueListenableBuilder(
      valueListenables: dependedNotifiers,
      builder: (context, values, child) {
        return ApiProviderMultiBuilder(
          providers: providersBuilder(values),
          transitionBuilder: (context, child, animation) => FadeTransition(child: child, opacity: animation),
          dataBuilder: (context, data) {
            onTap = onTapApi==null ? null : (context) {
              return onTapApi!(context, data);
            };
            return ActionFromZero.defaultIconBuilder(context: context, title: title, icon: icon, onTap: onTap, enabled: enabled, color: color);
          },
          loadingBuilder: (context, progress) {
            onTap = null;
            return Stack(
              children: [
                ActionFromZero.defaultIconBuilder(context: context, title: title, icon: icon, onTap: null, enabled: false, color: color),
                Positioned.fill(
                  child: IgnorePointer(
                    child: ApiProviderBuilder.defaultLoadingBuilder(context, progress, size: 32),
                  ),
                ),
              ],
            );
          },
          errorBuilder: (context, error, stackTrace, onRetry) {
            onTap = null;
            return ActionFromZero.defaultIconBuilder(context: context, title: title, icon: icon, onTap: null, enabled: false, color: color);
          },
        );
      },
    );
  }

  Widget apiButtonBuilder({
    required BuildContext context,
    required String title,
    Widget? icon,
    ContextCallback? onTap,
    bool enabled = true,
    Color? color,
  }) {
    return MultiValueListenableBuilder(
      valueListenables: dependedNotifiers,
      builder: (context, values, child) {
        return ApiProviderMultiBuilder(
          providers: providersBuilder(values),
          transitionBuilder: (context, child, animation) => FadeTransition(child: child, opacity: animation),
          dataBuilder: (context, data) {
            onTap = onTapApi==null ? null : (context) {
              return onTapApi!(context, data);
            };
            return ActionFromZero.defaultButtonBuilder(context: context, title: title, icon: icon, onTap: onTap, enabled: enabled, color: color);
          },
          loadingBuilder: (context, progress) {
            onTap = null;
            return Stack(
              children: [
                ActionFromZero.defaultButtonBuilder(context: context, title: title, icon: icon, onTap: null, enabled: false, color: color),
                Positioned.fill(
                  child: IgnorePointer(
                    child: ApiProviderBuilder.defaultLoadingBuilder(context, progress, size: 34),
                  ),
                ),
              ],
            );
          },
          errorBuilder: (context, error, stackTrace, onRetry) {
            onTap = null;
            return ActionFromZero.defaultButtonBuilder(context: context, title: title, icon: icon, onTap: null, enabled: false, color: color);
          },
        );
      },
    );
  }

  Widget apiOverflowBuilder({
    required BuildContext context,
    required String title,
    Widget? icon,
    ContextCallback? onTap,
    bool enabled = true,
    bool forceIconSpace = false,
  }) {
    return MultiValueListenableBuilder(
      valueListenables: dependedNotifiers,
      builder: (context, values, child) {
        return ApiProviderMultiBuilder(
          providers: providersBuilder(values),
          transitionBuilder: (context, child, animation) => FadeTransition(child: child, opacity: animation),
          dataBuilder: (context, data) {
            onTap = onTapApi==null ? null : (context) {
              return onTapApi!(context, data);
            };
            return ActionFromZero.defaultOverflowBuilder(context: context, title: title, icon: icon, onTap: onTap, enabled: enabled, forceIconSpace: forceIconSpace);
          },
          loadingBuilder: (context, progress) {
            onTap = null;
            return Stack(
              children: [
                ActionFromZero.defaultOverflowBuilder(context: context, title: title, icon: icon, onTap: null, enabled: false, forceIconSpace: forceIconSpace),
                Positioned.fill(
                  child: IgnorePointer(
                    child: ApiProviderBuilder.defaultLoadingBuilder(context, progress, size: 32),
                  ),
                ),
              ],
            );
          },
          errorBuilder: (context, error, stackTrace, onRetry) {
            onTap = null;
            return ActionFromZero.defaultOverflowBuilder(context: context, title: title, icon: icon, onTap: null, enabled: false, forceIconSpace: forceIconSpace);
          },
        );
      },
    );
  }

}