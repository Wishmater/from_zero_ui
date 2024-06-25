import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:from_zero_ui/from_zero_ui.dart';
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

typedef ContextCallback = void Function(BuildContext context);
typedef ActionBuilder = Widget Function({
  required BuildContext context,
  required String title,
  Widget? icon,
  ContextCallback? onTap,
  String? disablingError,
  Color? color,
});
typedef OverflowActionBuilder = Widget Function({
  required BuildContext context,
  required String title,
  Widget? icon,
  ContextCallback? onTap,
  String? disablingError,
  bool forceIconSpace,
});

class ActionFromZero extends StatelessWidget {

  /// callback called when icon/button/overflowMenuItem is clicked
  /// if null and expandedWidget!= null, will switch expanded
  final ContextCallback? onTap;
  final String title;
  final Widget? icon;
  final Color? color;
  final String? disablingError;

  /// from each breakpoint up, the selected widget will be used
  /// defaults to overflow
  final Map<double, ActionState> breakpoints;

  int get uniqueId => Object.hashAll([title, icon]);

  /// optional callbacks to customize the look of the widget in its different states
  final OverflowActionBuilder overflowBuilder;
  Widget buildOverflow(BuildContext context, {bool forceIconSpace=false}) => overflowBuilder(context: context, title: title, icon: icon, onTap: onTap, disablingError: disablingError, forceIconSpace: forceIconSpace);

  final ActionBuilder iconBuilder;
  Widget buildIcon(BuildContext context, {
    Color? color,
  }) => iconBuilder(context: context, title: title, icon: icon, onTap: onTap, disablingError: disablingError, color: color??this.color);

  final ActionBuilder buttonBuilder;
  Widget buildButton(BuildContext context, {
    Color? color,
  }) => buttonBuilder(context: context, title: title, icon: icon, onTap: onTap, disablingError: disablingError, color: color??this.color);

  final ActionBuilder? expandedBuilder;
  Widget buildExpanded(BuildContext context, {
    Color? color,
  }) => expandedBuilder!(context: context, title: title, icon: icon, onTap: onTap, disablingError: disablingError, color: color??this.color);
  final bool centerExpanded;

  ActionFromZero({
    required this.title,
    this.onTap,
    this.icon,
    this.color,
    this.disablingError,
    Map<double, ActionState>? breakpoints,
    this.overflowBuilder = defaultOverflowBuilder,
    this.iconBuilder = defaultIconBuilder,
    this.buttonBuilder = defaultButtonBuilder,
    this.expandedBuilder,
    this.centerExpanded = true,
    super.key,
  }) : breakpoints = breakpoints ?? {
    0: icon==null ? ActionState.overflow : ActionState.icon,
    ScaffoldFromZero.screenSizeLarge: expandedBuilder==null ? ActionState.button : ActionState.expanded,
  };

  ActionFromZero.divider({super.key, 
    Map<double, ActionState>? breakpoints,
    this.overflowBuilder = dividerOverflowBuilder,
    this.iconBuilder = dividerIconBuilder,
    this.buttonBuilder = dividerIconBuilder,
  }) :  title = '',
        icon = null,
        color = null,
        onTap = null,
        expandedBuilder = null,
        disablingError = null,
        centerExpanded = true,
        breakpoints = breakpoints ?? {
          0: ActionState.overflow,
          // ScaffoldFromZero.screenSizeLarge: ActionState.icon,
        };

  static void Function(BuildContext context) nullOnTap = (context){};
  ActionFromZero copyWith({
    void Function(BuildContext context)? onTap,
    String? title,
    Widget? icon,
    Color? color,
    Map<double, ActionState>? breakpoints,
    OverflowActionBuilder? overflowBuilder,
    ActionBuilder? iconBuilder,
    ActionBuilder? buttonBuilder,
    ActionBuilder? expandedBuilder,
    bool? centerExpanded,
    String? disablingError,
  }) {
    return ActionFromZero(
      onTap: onTap==nullOnTap ? null : (onTap ?? this.onTap),
      title: title ?? this.title,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      breakpoints: breakpoints ?? this.breakpoints,
      overflowBuilder: overflowBuilder ?? this.overflowBuilder,
      iconBuilder: iconBuilder ?? this.iconBuilder,
      buttonBuilder: buttonBuilder ?? this.buttonBuilder,
      expandedBuilder: expandedBuilder ?? this.expandedBuilder,
      centerExpanded: centerExpanded ?? this.centerExpanded,
      disablingError: disablingError ?? this.disablingError,
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


  static Widget defaultIconBuilder({
    required BuildContext context,
    required String title,
    Widget? icon,
    ContextCallback? onTap,
    String? disablingError,
    Color? color,
  }) {
    final enabled = disablingError==null;
    if (!enabled || onTap==null) {
      color = Theme.of(context).disabledColor;
    } else {
      color ??= Theme.of(context).appBarTheme.toolbarTextStyle?.color
          ?? Theme.of(context).textTheme.bodyLarge!.color!;
    }
    final transparentColor = color.withOpacity(0.05);
    final semiTransparentColor = color.withOpacity(0.1);
    return TooltipFromZero(
      message: '$title${disablingError==null ? '' : '\n$disablingError'}',
      child: IconButton(
        icon: icon ?? const SizedBox.shrink(),
        color: color,
        hoverColor: transparentColor,
        highlightColor: semiTransparentColor,
        focusColor: semiTransparentColor,
        splashColor: semiTransparentColor,
        onPressed: (!enabled || onTap==null) ? null : (){
          onTap.call(context);
        },
      ),
    );
  }


  static Widget defaultButtonBuilder({
    required BuildContext context,
    required String title,
    Widget? icon,
    ContextCallback? onTap,
    String? disablingError,
    Color? color,
  }) {
    final enabled = disablingError==null;
    if (!enabled || onTap==null) {
      color = Theme.of(context).disabledColor;
    } else {
      color ??= Theme.of(context).appBarTheme.toolbarTextStyle?.color
          ?? Theme.of(context).textTheme.bodyLarge!.color!;
    }
    return TooltipFromZero(
      message: disablingError,
      child: SizedBox(
        height: 64,
        child: TextButton(
          style: TextButton.styleFrom(
            padding: EdgeInsets.zero,
            foregroundColor: color,
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
                const SizedBox(width: 8),
                if (icon!=null)
                  icon,
                if (icon!=null)
                  const SizedBox(width: 6,),
                Text(title,
                  style: TextStyle(
                    fontSize: 16,
                    color: color,
                  ),
                ),
                const SizedBox(width: 8),
              ],
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
    String? disablingError,
    bool forceIconSpace = false,
  }) {
    final enabled = disablingError==null;
    final originalContext = context;
    return Builder(
      builder: (context) {
        Widget result = Padding(
          padding: const EdgeInsets.symmetric(vertical: 5),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (icon!=null) const SizedBox(width: 12,),
              if (icon!=null) IconTheme(
                data: Theme.of(context).iconTheme.copyWith(
                  color: !enabled || onTap==null
                      ? Theme.of(context).disabledColor
                      : Theme.of(context).brightness==Brightness.light ? Colors.black45 : Colors.grey.shade300,
                ),
                child: icon,
              ),
              if (icon==null && forceIconSpace) const SizedBox(width: 36,),
              const SizedBox(width: 12,),
              Expanded(
                child: Text(title,
                  style: TextStyle(
                    fontSize: 16,
                    height: 1.1,
                    color: !enabled || onTap==null
                        ? Theme.of(context).disabledColor
                        : Theme.of(context).textTheme.bodyLarge!.color,
                  ),
                ),
              ),
              const SizedBox(width: 12,),
            ],
          ),
        );
        result = TextButton(
          onPressed: (!enabled || onTap==null) ? null : () => onTap.call(originalContext),
          style: TextButton.styleFrom(
            foregroundColor: !enabled || onTap==null
                ? Theme.of(context).disabledColor
                : Theme.of(context).textTheme.bodyLarge!.color,
            padding: EdgeInsets.zero,
          ),
          child: result,
        );
        return TooltipFromZero(
          message: disablingError,
          child: result,
        );
      },
    );
  }


  static Widget dividerIconBuilder({
    required BuildContext context,
    required String title,
    Widget? icon,
    ContextCallback? onTap,
    String? disablingError,
    Color? color,
  }) {
    return const VerticalDivider();
  }

  static Widget dividerOverflowBuilder({
    required BuildContext context,
    required String title,
    Widget? icon,
    ContextCallback? onTap,
    String? disablingError,
    bool forceIconSpace = false,
  }) {
    return const Divider();
  }

}



class AnimatedActionFromZero extends StatelessWidget implements ActionFromZero {

  final Listenable animation;
  final ActionFromZero Function() builder;

  AnimatedActionFromZero({
    required this.animation,
    required this.builder,
    super.key,
  });

  @override
  ActionFromZero copyWith({void Function(BuildContext context)? onTap, String? title, Widget? icon, Color? color, Map<double, ActionState>? breakpoints, OverflowActionBuilder? overflowBuilder, ActionBuilder? iconBuilder, ActionBuilder? buttonBuilder, ActionBuilder? expandedBuilder, bool? centerExpanded, String? disablingError})
      => _action.copyWith(onTap: onTap, title: title, icon: icon, color: color, breakpoints: breakpoints, overflowBuilder: overflowBuilder, iconBuilder: iconBuilder, buttonBuilder: buttonBuilder, expandedBuilder: expandedBuilder, centerExpanded: centerExpanded, disablingError: disablingError);

  ActionFromZero? _cachedAction;
  ActionFromZero get _action {
    _cachedAction ??= builder();
    return _cachedAction!;
  }

  void _reset() => _cachedAction = null;
  Widget _buildListenerWrapper(Widget Function(BuildContext) builder) {
    return _LifecycleHook(
      onInitState: () => animation.addListener(_reset),
      onDispose: () => animation.removeListener(_reset),
      child: AnimatedBuilder(
        animation: animation,
        builder: (context, child) {
          return builder(context);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) =>
      _buildListenerWrapper((context) => _action.build(context));
  @override
  Widget buildButton(BuildContext context, {Color? color}) =>
      _buildListenerWrapper((context) => _action.buildButton(context, color: color));
  @override
  Widget buildExpanded(BuildContext context, {Color? color}) =>
      _buildListenerWrapper((context) => _action.buildExpanded(context, color: color));
  @override
  Widget buildIcon(BuildContext context, {Color? color}) =>
      _buildListenerWrapper((context) => _action.buildIcon(context, color: color));
  @override
  Widget buildOverflow(BuildContext context, {bool forceIconSpace = false}) =>
      _buildListenerWrapper((context) => _action.buildOverflow(context, forceIconSpace: forceIconSpace));

  @override
  Map<double, ActionState> get breakpoints => _action.breakpoints;
  @override
  ActionBuilder get buttonBuilder => _action.buttonBuilder;
  @override
  bool get centerExpanded => _action.centerExpanded;
  @override
  Color? get color => _action.color;
  @override
  String? get disablingError => _action.disablingError;
  @override
  ActionBuilder? get expandedBuilder => _action.expandedBuilder;
  @override
  ActionState getStateForMaxWidth(double width) => _action.getStateForMaxWidth(width);
  @override
  Widget? get icon => _action.icon;
  @override
  ActionBuilder get iconBuilder => _action.iconBuilder;
  @override
  Key? get key => _action.key;
  @override
  ContextCallback? get onTap => _action.onTap;
  @override
  OverflowActionBuilder get overflowBuilder => _action.overflowBuilder;
  @override
  String get title => _action.title;
  @override
  int get uniqueId => _action.uniqueId;

}
class _LifecycleHook extends StatefulWidget {
  final Widget child;
  final VoidCallback? onInitState;
  final VoidCallback? onDispose;
  const _LifecycleHook({
    required this.child,
    this.onInitState,
    this.onDispose,
    super.key,
  });
  @override
  State<_LifecycleHook> createState() => _LifecycleHookState();
}
class _LifecycleHookState extends State<_LifecycleHook> {
  @override
  void initState() {
    super.initState();
    widget.onInitState?.call();
  }
  @override
  void dispose() {
    super.dispose();
    widget.onDispose?.call();
  }
  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}




typedef ApiActionCallback<T, R> = R Function(BuildContext context, List<T> data);
class APIActionFromZero<T> extends ActionFromZero {

  final List<ValueNotifier> dependedNotifiers;
  final List<ApiProvider<T>> Function(List<dynamic> values) providersBuilder;
  final ApiActionCallback<T, void>? onTapApi;
  final ApiActionCallback<T, String?>? disablingErrorBuilder;
  final ApiActionCallback<T, String?>? titleApiBuilder;
  final ApiActionCallback<T, Widget?>? iconApiBuilder;

  APIActionFromZero({
    required super.title,
    required this.providersBuilder,
    this.onTapApi,
    super.icon,
    super. breakpoints,
    this.dependedNotifiers = const [],
    this.disablingErrorBuilder,
    this.titleApiBuilder,
    this.iconApiBuilder,
    super.key,
  });

  @override
  ActionBuilder get iconBuilder => apiIconBuilder;

  @override
  ActionBuilder get buttonBuilder => apiButtonBuilder;

  @override
  OverflowActionBuilder get overflowBuilder => apiOverflowBuilder;

  static Widget _maybeAddMultiValueListenableBuilder(BuildContext context, {
    required List<ValueListenable> valueListenables,
    required Widget Function(BuildContext context, List<dynamic> values, Widget? child) builder,
    Widget? child,
  }) {
    if (valueListenables.isEmpty) {
      return builder(context, [], child);
    }
    return MultiValueListenableBuilder(
      valueListenables: valueListenables,
      builder: builder,
      child: child,
    );
  }

  Widget apiIconBuilder({
    required BuildContext context,
    required String title,
    Widget? icon,
    ContextCallback? onTap,
    String? disablingError,
    Color? color,
  }) {
    return _maybeAddMultiValueListenableBuilder(context,
      valueListenables: dependedNotifiers,
      builder: (context, values, child) {
        return ApiProviderMultiBuilder(
          providers: providersBuilder(values),
          animatedSwitcherType: AnimatedSwitcherType.normal,
          transitionBuilder: (context, child, animation) => FadeTransition(opacity: animation, child: child),
          dataBuilder: (context, data) {
            onTap = onTapApi==null ? null : (context) {
              return onTapApi!(context, data);
            };
            return ActionFromZero.defaultIconBuilder(
              context: context,
              title: titleApiBuilder?.call(context, data) ?? title,
              icon: iconApiBuilder?.call(context, data) ?? icon,
              onTap: onTap,
              disablingError: disablingErrorBuilder?.call(context, data),
              color: color,
            );
          },
          loadingBuilder: (context, progress) {
            onTap = null;
            return Stack(
              children: [
                ActionFromZero.defaultIconBuilder(
                  context: context,
                  title: title,
                  icon: icon,
                  onTap: null,
                  disablingError: '',
                  color: color,
                ),
                Positioned.fill(
                  child: IgnorePointer(
                    child: ApiProviderBuilder.defaultLoadingBuilder(context, progress, size: 32),
                  ),
                ),
              ],
            );
          },
          errorBuilder: (context, error, stackTrace, onRetry) {
            // TODO 1 this error will be completely buried
            onTap = null;
            return ActionFromZero.defaultIconBuilder(
              context: context,
              title: title,
              icon: icon,
              onTap: null,
              disablingError: '',
              color: color,
            );
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
    String? disablingError,
    Color? color,
  }) {
    return _maybeAddMultiValueListenableBuilder(context,
      valueListenables: dependedNotifiers,
      builder: (context, values, child) {
        return ApiProviderMultiBuilder(
          providers: providersBuilder(values),
          animatedSwitcherType: AnimatedSwitcherType.normal,
          transitionBuilder: (context, child, animation) => FadeTransition(opacity: animation, child: child),
          dataBuilder: (context, data) {
            onTap = onTapApi==null ? null : (context) {
              return onTapApi!(context, data);
            };
            return ActionFromZero.defaultButtonBuilder(
              context: context,
              title: titleApiBuilder?.call(context, data) ?? title,
              icon: iconApiBuilder?.call(context, data) ?? icon,
              onTap: onTap,
              disablingError: disablingErrorBuilder?.call(context, data),
              color: color,
            );
          },
          loadingBuilder: (context, progress) {
            onTap = null;
            return Stack(
              children: [
                ActionFromZero.defaultButtonBuilder(
                  context: context,
                  title: title,
                  icon: icon,
                  onTap: null,
                  disablingError: '',
                  color: color,
                ),
                Positioned.fill(
                  child: IgnorePointer(
                    child: ApiProviderBuilder.defaultLoadingBuilder(context, progress, size: 34),
                  ),
                ),
              ],
            );
          },
          errorBuilder: (context, error, stackTrace, onRetry) {
            // TODO 1 this error will be completely buried
            onTap = null;
            return ActionFromZero.defaultButtonBuilder(
              context: context,
              title: title,
              icon: icon,
              onTap: null,
              disablingError: '',
              color: color,
            );
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
    String? disablingError,
    bool forceIconSpace = false,
  }) {
    return _maybeAddMultiValueListenableBuilder(context,
      valueListenables: dependedNotifiers,
      builder: (context, values, child) {
        return ApiProviderMultiBuilder(
          providers: providersBuilder(values),
          animatedSwitcherType: AnimatedSwitcherType.normal,
          transitionBuilder: (context, child, animation) => FadeTransition(opacity: animation, child: child),
          dataBuilder: (context, data) {
            onTap = onTapApi==null ? null : (context) {
              return onTapApi!(context, data);
            };
            return ActionFromZero.defaultOverflowBuilder(
              context: context,
              title: titleApiBuilder?.call(context, data) ?? title,
              icon: iconApiBuilder?.call(context, data) ?? icon,
              onTap: onTap,
              disablingError: disablingErrorBuilder?.call(context, data),
              forceIconSpace: forceIconSpace,
            );
          },
          loadingBuilder: (context, progress) {
            onTap = null;
            return Stack(
              children: [
                ActionFromZero.defaultOverflowBuilder(
                  context: context,
                  title: title,
                  icon: icon,
                  onTap: null,
                  disablingError: '',
                  forceIconSpace: forceIconSpace,
                ),
                Positioned.fill(
                  child: IgnorePointer(
                    child: ApiProviderBuilder.defaultLoadingBuilder(context, progress, size: 32),
                  ),
                ),
              ],
            );
          },
          errorBuilder: (context, error, stackTrace, onRetry) {
            // TODO 1 this error will be completely buried
            onTap = null;
            return ActionFromZero.defaultOverflowBuilder(
              context: context,
              title: title,
              icon: icon,
              onTap: null,
              disablingError: '',
              forceIconSpace: forceIconSpace,
            );
          },
        );
      },
    );
  }

}