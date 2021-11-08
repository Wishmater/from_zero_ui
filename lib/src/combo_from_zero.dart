import 'package:animations/animations.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:from_zero_ui/from_zero_ui.dart';
import 'package:from_zero_ui/util/my_popup_menu.dart' as my_popup;

typedef Widget ButtonChildBuilder<T>(BuildContext context, String? title, String? hint, T? value, bool enabled, bool clearable, {bool showDropdownIcon});
/// returns true if navigator should pop after (default true)
typedef bool? OnPopupItemSelected<T>(T? value);
typedef dynamic DAOGetter<T>(T value);    // TODO this should be DAO
typedef Widget ExtraWidgetBuilder<T>(BuildContext context, OnPopupItemSelected<T>? onSelected,);

class ComboFromZero<T> extends StatefulWidget {

  final T? value;
  final List<T>? possibleValues;
  final Future<List<T>>? futurePossibleValues;
  final my_popup.PopupMenuCanceled? onCanceled;
  final OnPopupItemSelected<T>? onSelected;
  final bool showSearchBox;
  final String? title;
  final String? hint;
  final bool enabled;
  final bool clearable;
  final bool sort;
  final bool showViewActionOnDAOs;
  final bool showDropdownIcon;
  final ButtonChildBuilder<T>? buttonChildBuilder;
  final double popupWidth;
  final ExtraWidgetBuilder<T>? extraWidget;
  final FocusNode? focusNode;
  final Widget Function(T value)? popupWidgetBuilder;

  ComboFromZero({
    this.value,
    this.possibleValues,
    this.futurePossibleValues,
    this.onSelected,
    this.onCanceled,
    this.showSearchBox=true,
    this.title,
    this.hint,
    this.buttonChildBuilder,
    this.enabled = true,
    this.clearable = true,
    this.sort = true,
    this.showViewActionOnDAOs = true,
    this.showDropdownIcon = true,
    this.popupWidth = 312,
    this.extraWidget,
    this.focusNode,
    this.popupWidgetBuilder,
  }) :  assert(possibleValues!=null || futurePossibleValues!=null);

  @override
  _ComboFromZeroState<T> createState() => _ComboFromZeroState<T>();

  static Widget defaultButtonChildBuilder(BuildContext context, String? title, String? hint, dynamic value, bool enabled, bool clearable, {bool showDropdownIcon=true}) {
    return IntrinsicWidth(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minHeight: 38, minWidth: 192,
        ),
        child: Padding(
          padding: EdgeInsets.only(right: enabled&&clearable ? 32 : 0),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              SizedBox(width: 8,),
              Expanded(
                child: value==null&&hint==null&&title!=null
                    ? Text(title, style: Theme.of(context).textTheme.subtitle1!.copyWith(
                      color: enabled ? Theme.of(context).textTheme.caption!.color : Theme.of(context).textTheme.bodyText1!.color!.withOpacity(0.75),
                    ),)
                    : MaterialKeyValuePair(
                      title: title,
                      value: value==null ? (hint ?? '') : value.toString(),
                      valueStyle: Theme.of(context).textTheme.subtitle1!.copyWith(
                        height: 1,
                        color: value==null ? Theme.of(context).textTheme.caption!.color!
                            : Theme.of(context).textTheme.bodyText1!.color!.withOpacity(enabled ? 1 : 0.75),
                      ),
                    ),
              ),
              SizedBox(width: 4,),
              if (showDropdownIcon && enabled && !clearable)
                Icon(Icons.arrow_drop_down, color: Theme.of(context).textTheme.bodyText1!.color,),
              SizedBox(width: 4,),
            ],
          ),
        ),
      ),
    );
  }

}

class _ComboFromZeroState<T> extends State<ComboFromZero<T>> {

  List<T>? possibleValues;
  GlobalKey buttonKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    init();
  }
  @override
  void didUpdateWidget(covariant ComboFromZero<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.possibleValues!=widget.possibleValues) {
      init();
    } else if (oldWidget.futurePossibleValues!=widget.futurePossibleValues) {
      init();
      WidgetsBinding.instance!.addPostFrameCallback((timeStamp) {
        setState(() {
          possibleValues = (widget.possibleValues==null ? null : List.from(widget.possibleValues!));
        });
      });
    }
  }
  void init() async {
    possibleValues = (widget.possibleValues==null ? null : List.from(widget.possibleValues!)) ?? possibleValues;
    // if (widget.sort) sort();
    if (widget.futurePossibleValues!=null) {
      possibleValues = List.from(await widget.futurePossibleValues!);
      // if (widget.sort) sort();
      setState(() {});
    }
  }
  // void sort() { // sorting is now delegated to the tableFromZero in the popup
  //   if (possibleValues!=null) {
  //     possibleValues!.sort((a, b) {
  //       return a.toString().compareTo(b.toString());
  //     });
  //   }
  // }

  late final buttonFocusNode = widget.focusNode ?? FocusNode();
  @override
  Widget build(BuildContext context) {
    Widget result;
    if (possibleValues==null) {
      result = SizedBox(
        width: 64,
        height: 38,
        child: Center(
          child: SizedBox(
            width: 26,
            height: 26,
            child: CircularProgressIndicator(
              strokeWidth: 3,
            ),
          ),
        ),
      );
    } else {
      Widget child;
      if (widget.buttonChildBuilder==null) {
        child = ComboFromZero.defaultButtonChildBuilder(context, widget.title, widget.hint, widget.value, widget.enabled, widget.clearable,
          showDropdownIcon: widget.showDropdownIcon,
        );
      } else {
        child = widget.buttonChildBuilder!(context, widget.title, widget.hint, widget.value, widget.enabled, widget.clearable,
          showDropdownIcon: widget.showDropdownIcon,
        );
      }
      result = Stack(
        children: [
          TextButton(
            key: buttonKey,
            child: Center(
              child: OverflowScroll(
                child: child,
                scrollDirection: Axis.vertical,
              ),
            ),
            focusNode: buttonFocusNode,
            onPressed: widget.enabled ? () async {
              buttonFocusNode.requestFocus();
              Widget child = Card(
                clipBehavior: Clip.hardEdge,
                child: ComboFromZeroPopup<T>(
                  possibleValues: possibleValues!,
                  onSelected: widget.onSelected,
                  onCanceled: widget.onCanceled,
                  value: widget.value,
                  sort: widget.sort,
                  showSearchBox: widget.showSearchBox,
                  showViewActionOnDAOs: widget.showViewActionOnDAOs,
                  title: widget.title,
                  extraWidget: widget.extraWidget,
                  popupWidgetBuilder: widget.popupWidgetBuilder,
                ),
              );
              bool? accepted = await showDialog<bool>(
                context: context,
                barrierColor: Colors.black.withOpacity(0.2),
                builder: (context) {
                  final animation = CurvedAnimation(
                    parent: ModalRoute.of(context)!.animation!,
                    curve: Curves.easeInOutCubic,
                  );
                  Offset? referencePosition;
                  Size? referenceSize;
                  try {
                    RenderBox box = buttonKey.currentContext!.findRenderObject()! as RenderBox;
                    referencePosition = box.localToGlobal(Offset.zero); //this is global position
                    referenceSize = box.size;
                  } catch(_) {}
                  return CustomSingleChildLayout(
                    delegate: DropdownChildLayoutDelegate(
                      referencePosition: referencePosition,
                      referenceSize: referenceSize,
                    ),
                    child: AnimatedBuilder(
                      animation: animation,
                      builder: (context, child) {
                        return SizedBox(
                          width: referenceSize==null ? widget.popupWidth : (referenceSize.width+8).clamp(312, double.infinity),
                          child: ClipRect(
                            clipper: RectPercentageClipper(
                              widthPercent: (animation.value*2.0).clamp(0.0, 1),
                            ),
                            child: child, // TODO add AnimatedContainerFromChildSize
                          ),
                        );
                      },
                      child: SizeTransition(
                        sizeFactor: animation,
                        axis: Axis.vertical,
                        axisAlignment: 0,
                        child: child,
                      ),
                    ),
                  );
                },
              );
              if (accepted!=true) {
                widget.onCanceled?.call();
              }
            } : null,
          ),
          if (widget.enabled && widget.clearable)
            Positioned(
              right: 8, top: 0, bottom: 0,
              child: ExcludeFocus(
                child: Center(
                  child: AnimatedSwitcher(
                    duration: Duration(milliseconds: 300),
                    switchInCurve: Curves.easeOutCubic,
                    transitionBuilder: (child, animation) {
                      return SizeTransition(
                        sizeFactor: animation,
                        child: FadeTransition(
                          opacity: animation,
                          child: child,
                        ),
                      );
                    },
                    child: widget.value!=null ? IconButton(
                      icon: Icon(Icons.close),
                      tooltip: FromZeroLocalizations.of(context).translate('clear'),
                      splashRadius: 20,
                      onPressed: () {
                        widget.onSelected?.call(null);
                      },
                    ) : SizedBox.shrink(),
                  ),
                ),
              ),
            ),
        ],
      );
    }
    return result;
    // TODO apply transition switcher, solve problems with duplicate key and stack constraints
    return PageTransitionSwitcher(
      child: result,
      duration: Duration(milliseconds: 300,),
      transitionBuilder: (child, primaryAnimation, secondaryAnimation) {
        return FadeThroughTransition(
          child: child,
          fillColor: Colors.transparent,
          animation: primaryAnimation,
          secondaryAnimation: secondaryAnimation,
        );
      },
    );
  }

}



class ComboFromZeroPopup<T> extends StatefulWidget {

  final T? value;
  final List<T> possibleValues;
  final my_popup.PopupMenuCanceled? onCanceled;
  final OnPopupItemSelected<T>? onSelected;
  final bool showSearchBox;
  final bool showViewActionOnDAOs;
  final bool sort;
  final String? title;
  final ExtraWidgetBuilder<T>? extraWidget;
  final Widget Function(T value)? popupWidgetBuilder;

  ComboFromZeroPopup({
    required this.possibleValues,
    this.value,
    this.onSelected,
    this.onCanceled,
    this.showSearchBox = true,
    this.showViewActionOnDAOs = true,
    this.sort = true,
    this.title,
    this.extraWidget,
    this.popupWidgetBuilder,
  });

  @override
  _ComboFromZeroPopupState<T> createState() => _ComboFromZeroPopupState<T>();

}

class _ComboFromZeroPopupState<T> extends State<ComboFromZeroPopup<T>> {

  final ScrollController popupScrollController = ScrollController();
  String? searchQuery;
  TableController tableController = TableController();

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return ScrollbarFromZero(
      controller: popupScrollController,
      child: AnimatedContainerFromChildSize(
        child: CustomScrollView(
          controller: popupScrollController,
          shrinkWrap: true,
          slivers: [
            if (!widget.showSearchBox)
              SliverToBoxAdapter(child: SizedBox(height: 12,),),
            TableFromZero(
              tableController: tableController,
              layoutWidgetType: TableFromZero.sliverListViewBuilder,
              showHeaders: false,
              horizontalPadding: 8,
              initialSortedColumnIndex: widget.sort ? 0 : -1,
              cellBuilder: widget.popupWidgetBuilder==null ? null
                  : (context, row, col, j) => widget.popupWidgetBuilder!(row.id),
              onFilter: (filtered) {
                if (searchQuery!=null && searchQuery!.isNotEmpty) {
                  return filtered.where((e) => e.id.toString().toUpperCase().contains(searchQuery!.toUpperCase())).toList();
                }
                return filtered;
              },
              rows: widget.possibleValues.map((e) {
                return SimpleRowModel(
                  id: e,
                  values: [e.toString()],
                  backgroundColor: widget.value==e ? Theme.of(context).toggleableActiveColor.withOpacity(0.1) : null,
                  onRowTap: (value) {
                    _select(e);
                  },
                  actions: widget.showViewActionOnDAOs && e is DAO ? [IconButton(
                    icon: Icon(Icons.remove_red_eye),
                    onPressed: () {
                      e.pushViewDialog(context);
                    },
                  )] : null
                );
              }).toList(),
              headerAddon: widget.showSearchBox ? Container(
                color: Theme.of(context).cardColor,
                child: Column(
                  children: [
                    if (widget.title!=null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4.0),
                        child: Center(
                          child: Text(widget.title!,
                            style: Theme.of(context).textTheme.subtitle1,
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    if (widget.extraWidget!=null)
                      widget.extraWidget!(context, widget.onSelected,),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8.0, left: 12, right: 12,),
                      child: TextFormField(
                        initialValue: searchQuery,
                        autofocus: PlatformExtended.isDesktop,
                        decoration: InputDecoration(
                          contentPadding: EdgeInsets.only(left: 8, right: 80, bottom: 4, top: 8,),
                          labelText: FromZeroLocalizations.of(context).translate('search...'),
                          labelStyle: TextStyle(height: 1.5),
                          suffixIcon: Icon(Icons.search, color: Theme.of(context).textTheme.caption!.color!,),
                        ),
                        onChanged: (value) {
                          searchQuery = value;
                          tableController.filter();
                        },
                        onFieldSubmitted: (value) {
                          final filtered = tableController.filtered!;
                          if (filtered.length==1) {
                            _select(filtered.first.id);
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ) : null,
            ),
            SliverToBoxAdapter(child: SizedBox(height: 12,),),
          ],
        ),
      ),
    );
  }

  void _select(T e) {
    bool? pop = widget.onSelected?.call(e);
    if (pop??true) {
      Navigator.of(context).pop(true);
    }
  }

}


enum DropdownChildLayoutDelegateAlign {
  topLeft,
  bottomLeft,
  topRight,
  bottomRight,
}

// TODO make this a separate thing, since it is also used in DatePickerFromZero
class DropdownChildLayoutDelegate extends SingleChildLayoutDelegate {

  Offset? referencePosition;
  Size? referenceSize;
  DropdownChildLayoutDelegateAlign align;

  DropdownChildLayoutDelegate({
    this.referencePosition,
    this.referenceSize,
    this.align = DropdownChildLayoutDelegateAlign.bottomLeft,
  });

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) {
    return constraints.loosen();
  }

  @override
  Offset getPositionForChild(Size size, Size childSize) {
    if (referencePosition!=null && referenceSize!=null) {
      double x = (referencePosition!.dx-4).clamp(0, size.width-childSize.width);
      if (align==DropdownChildLayoutDelegateAlign.topRight || align==DropdownChildLayoutDelegateAlign.bottomRight) {
        x += referenceSize!.width-childSize.width;
      }
      double y = referencePosition!.dy;
      if (align==DropdownChildLayoutDelegateAlign.bottomLeft || align==DropdownChildLayoutDelegateAlign.bottomRight) {
        y += referenceSize!.height;
      }
      if (size.height-y < childSize.height) {
        y = size.height - childSize.height;
      }
      return Offset(x, y,);
    } else {
      return Offset(
        size.width/2-childSize.width/2,
        size.height/2-childSize.height/2,
      );
    }
  }

  @override
  bool shouldRelayout(covariant SingleChildLayoutDelegate oldDelegate) {
    return false;
  }

}

class RectPercentageClipper extends CustomClipper<Rect> {

  double heightPercent;
  double widthPercent;

  RectPercentageClipper({
    this.heightPercent = 1,
    this.widthPercent = 1,
  });

  @override
  getClip(Size size) {
    return Rect.fromLTWH(0, 0,
      size.width * widthPercent,
      size.height * heightPercent,
    );
  }

  @override
  bool shouldReclip(covariant CustomClipper oldClipper) {
    return true;
  }

}