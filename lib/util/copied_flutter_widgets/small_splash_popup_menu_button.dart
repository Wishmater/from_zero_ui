import 'package:flutter/material.dart';
import 'package:from_zero_ui/util/copied_flutter_widgets/my_tooltip.dart';

class PopupMenuButton<T> extends StatefulWidget {
  /// Creates a button that shows a popup menu.
  ///
  /// The [itemBuilder] argument must not be null.
  const PopupMenuButton({
    Key? key,
    required this.itemBuilder,
    this.initialValue,
    this.onSelected,
    this.onCanceled,
    this.tooltip,
    this.elevation,
    this.padding = const EdgeInsets.all(8.0),
    this.child,
    this.icon,
    this.offset = Offset.zero,
    this.enabled = true,
    this.shape,
    this.color,
  }) : assert(itemBuilder != null),
        assert(offset != null),
        assert(enabled != null),
        assert(!(child != null && icon != null),
        'You can only pass [child] or [icon], not both.'),
        super(key: key);

  /// Called when the button is pressed to create the items to show in the menu.
  final PopupMenuItemBuilder<T> itemBuilder;

  /// The value of the menu item, if any, that should be highlighted when the menu opens.
  final T? initialValue;

  /// Called when the user selects a value from the popup menu created by this button.
  ///
  /// If the popup menu is dismissed without selecting a value, [onCanceled] is
  /// called instead.
  final PopupMenuItemSelected<T>? onSelected;

  /// Called when the user dismisses the popup menu without selecting an item.
  ///
  /// If the user selects a value, [onSelected] is called instead.
  final PopupMenuCanceled? onCanceled;

  /// Text that describes the action that will occur when the button is pressed.
  ///
  /// This text is displayed when the user long-presses on the button and is
  /// used for accessibility.
  final String? tooltip;

  /// The z-coordinate at which to place the menu when open. This controls the
  /// size of the shadow below the menu.
  ///
  /// Defaults to 8, the appropriate elevation for popup menus.
  final double? elevation;

  /// Matches IconButton's 8 dps padding by default. In some cases, notably where
  /// this button appears as the trailing element of a list item, it's useful to be able
  /// to set the padding to zero.
  final EdgeInsetsGeometry padding;

  /// If provided, [child] is the widget used for this button
  /// and the button will utilize an [InkWell] for taps.
  final Widget? child;

  /// If provided, the [icon] is used for this button
  /// and the button will behave like an [IconButton].
  final Widget? icon;

  /// The offset applied to the Popup Menu Button.
  ///
  /// When not set, the Popup Menu Button will be positioned directly next to
  /// the button that was used to create it.
  final Offset offset;

  /// Whether this popup menu button is interactive.
  ///
  /// Must be non-null, defaults to `true`
  ///
  /// If `true` the button will respond to presses by displaying the menu.
  ///
  /// If `false`, the button is styled with the disabled color from the
  /// current [Theme] and will not respond to presses or show the popup
  /// menu and [onSelected], [onCanceled] and [itemBuilder] will not be called.
  ///
  /// This can be useful in situations where the app needs to show the button,
  /// but doesn't currently have anything to show in the menu.
  final bool enabled;

  /// If provided, the shape used for the menu.
  ///
  /// If this property is null, then [PopupMenuThemeData.shape] is used.
  /// If [PopupMenuThemeData.shape] is also null, then the default shape for
  /// [MaterialType.card] is used. This default shape is a rectangle with
  /// rounded edges of BorderRadius.circular(2.0).
  final ShapeBorder? shape;

  /// If provided, the background color used for the menu.
  ///
  /// If this property is null, then [PopupMenuThemeData.color] is used.
  /// If [PopupMenuThemeData.color] is also null, then
  /// Theme.of(context).cardColor is used.
  final Color? color;

  @override
  PopupMenuButtonState<T> createState() => PopupMenuButtonState<T>();
}

/// The [State] for a [PopupMenuButton].
///
/// See [showButtonMenu] for a way to programmatically open the popup menu
/// of your button state.
class PopupMenuButtonState<T> extends State<PopupMenuButton<T>> {
  /// A method to show a popup menu with the items supplied to
  /// [PopupMenuButton.itemBuilder] at the position of your [PopupMenuButton].
  ///
  /// By default, it is called when the user taps the button and [PopupMenuButton.enabled]
  /// is set to `true`. Moreover, you can open the button by calling the method manually.
  ///
  /// You would access your [PopupMenuButtonState] using a [GlobalKey] and
  /// show the menu of the button with `globalKey.currentState.showButtonMenu`.
  void showButtonMenu() {
    final PopupMenuThemeData popupMenuTheme = PopupMenuTheme.of(context);
    final RenderBox button = context.findRenderObject() as RenderBox;
    final RenderBox overlay = Overlay.of(context)!.context.findRenderObject() as RenderBox;
    final RelativeRect position = RelativeRect.fromRect(
      Rect.fromPoints(
        button.localToGlobal(widget.offset, ancestor: overlay),
        button.localToGlobal(button.size.bottomRight(Offset.zero), ancestor: overlay),
      ),
      Offset.zero & overlay.size,
    );
    final List<PopupMenuEntry<T>> items = widget.itemBuilder(context);
    // Only show the menu if there is something to show
    if (items.isNotEmpty) {
      showMenu<T>(
        context: context,
        elevation: widget.elevation ?? popupMenuTheme.elevation,
        items: items,
        initialValue: widget.initialValue,
        position: position,
        shape: widget.shape ?? popupMenuTheme.shape,
        color: widget.color ?? popupMenuTheme.color,
      )
          .then<void>((T? newValue) {
        if (!mounted)
          return null;
        if (newValue == null) {
          widget.onCanceled?.call();
          return null;
        }
        widget.onSelected?.call(newValue);
      });
    }
  }

  Icon _getIcon(TargetPlatform platform) {
    assert(platform != null);
    switch (platform) {
      case TargetPlatform.android:
      case TargetPlatform.fuchsia:
      case TargetPlatform.linux:
      case TargetPlatform.windows:
        return const Icon(Icons.more_vert);
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
        return const Icon(Icons.more_horiz);
    }
  }

  bool get _canRequestFocus {
    final NavigationMode mode = MediaQuery.of(context).navigationMode;
    switch (mode) {
      case NavigationMode.traditional:
        return widget.enabled;
      case NavigationMode.directional:
        return true;
    }
    assert(false, 'Navigation mode $mode not handled');
  }

  @override
  Widget build(BuildContext context) {
    assert(debugCheckHasMaterialLocalizations(context));

    if (widget.child != null)
      return TooltipFromZero(
        message: widget.tooltip ?? MaterialLocalizations.of(context).showMenuTooltip,
        child: InkWell(
          onTap: widget.enabled ? showButtonMenu : null,
          canRequestFocus: _canRequestFocus,
          child: widget.child,
        ),
      );

    return TooltipFromZero(
      message: widget.tooltip ?? MaterialLocalizations.of(context).showMenuTooltip,
      child: IconButton(
        icon: widget.icon ?? _getIcon(Theme.of(context).platform),
        padding: widget.padding,
        onPressed: widget.enabled ? showButtonMenu : null,
        splashRadius: 18,
      ),
    );
  }
}
