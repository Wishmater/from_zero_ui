import 'package:animations/animations.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:from_zero_ui/from_zero_ui.dart';
import 'package:from_zero_ui/util/my_popup_menu.dart' as my_popup;

typedef Widget ButtonChildBuilder<T>(BuildContext context, String? title, String? hint, T? value, bool enabled, bool clearable,);
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
  final ButtonChildBuilder<T>? buttonChildBuilder;
  final double popupWidth;
  final DAOGetter? daoGetter;
  final ExtraWidgetBuilder<T>? extraWidget;

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
    this.popupWidth = 312,
    this.daoGetter,
    this.extraWidget,
  }) :  assert(possibleValues!=null || futurePossibleValues!=null);

  @override
  _ComboFromZeroState<T> createState() => _ComboFromZeroState<T>();

  static Widget defaultButtonChildBuilder(BuildContext context, String? title, String? hint, dynamic value, bool enabled, bool clearable,) {
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
                child: MaterialKeyValuePair(
                  title: title,
                  value: value==null ? (hint ?? '') : value.toString(),
                  valueStyle: Theme.of(context).textTheme.subtitle1!.copyWith(
                    height: 1,
                    color: value==null ? Theme.of(context).textTheme.caption!.color!
                        : Theme.of(context).textTheme.bodyText1!.color!,
                  ),
                ),
              ),
              SizedBox(width: 4,),
              if (enabled && !clearable)
                Icon(Icons.arrow_drop_down),
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
    possibleValues = widget.possibleValues;
    if (widget.futurePossibleValues!=null) {
      widget.futurePossibleValues!.then((value) {
        setState(() {
          possibleValues = value;
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (possibleValues==null) {
      return Center(child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2,)));
    }
    Widget child;
    if (widget.buttonChildBuilder==null) {
      dynamic value = widget.value;
      if (value!=null && widget.daoGetter!=null) {
        value = widget.daoGetter!(value);
      }
      child = ComboFromZero.defaultButtonChildBuilder(context, widget.title, widget.hint, value, widget.enabled, widget.clearable);
    } else {
      child = widget.buttonChildBuilder!(context, widget.title, widget.hint, widget.value, widget.enabled, widget.clearable);
    }
    return Stack(
      children: [
        OutlineButton(
          key: buttonKey,
          child: child,
          onPressed: widget.enabled ? () async {
            Widget child = Card(
              clipBehavior: Clip.hardEdge,
              child: ComboFromZeroPopup<T>(
                possibleValues: possibleValues!,
                onSelected: widget.onSelected,
                onCanceled: widget.onCanceled,
                value: widget.value,
                showSearchBox: widget.showSearchBox,
                title: widget.title,
                daoGetter: widget.daoGetter,
                extraWidget: widget.extraWidget,
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
                          child: child,
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
                )
              ),
            ),
          ),
      ],
    );
  }

}



class ComboFromZeroPopup<T> extends StatefulWidget {

  final T? value;
  final List<T> possibleValues;
  final my_popup.PopupMenuCanceled? onCanceled;
  final OnPopupItemSelected<T>? onSelected;
  final bool showSearchBox;
  final String? title;
  final DAOGetter? daoGetter;
  final ExtraWidgetBuilder<T>? extraWidget;

  ComboFromZeroPopup({
    required this.possibleValues,
    this.value,
    this.onSelected,
    this.onCanceled,
    this.showSearchBox=true,
    this.title,
    this.daoGetter,
    this.extraWidget,
  });

  @override
  _ComboFromZeroPopupState<T> createState() => _ComboFromZeroPopupState<T>();

}

class _ComboFromZeroPopupState<T> extends State<ComboFromZeroPopup<T>> {

  final ScrollController popupScrollController = ScrollController();
  late List<T> filtered;
  String? searchQuery;

  @override
  void initState() {
    super.initState();
    filter();
  }

  void filter() {
    filtered = widget.possibleValues as List<T>;
    if (searchQuery!=null) {
      filtered = filtered.where((element) => element.toString().toUpperCase().contains(searchQuery!.toUpperCase())).toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ScrollbarFromZero(
      controller: popupScrollController,
      child: ListView.builder(
        controller: popupScrollController,
        shrinkWrap: true,
        itemCount: filtered.length + 1,
        padding: EdgeInsets.only(bottom: 12,),
        itemBuilder: (context, index) {
          if (index==0) {
            if (widget.showSearchBox) {
              return Column(
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
                        setState(() {
                          searchQuery = value;
                          filter();
                        });
                      },
                    ),
                  ),
                ],
              );
            } else{
              return SizedBox(height: 12,);
            }
          } else {
            index--;
          }
          dynamic value = filtered[index];
          if (widget.daoGetter!=null) {
            value = widget.daoGetter!(value);
          }
          return ListTile(
            title: Text(value.toString(), style: Theme.of(context).textTheme.subtitle1,),
            dense: true,
            selected: widget.value==filtered[index],
            selectedTileColor: Theme.of(context).primaryColor.withOpacity(0.1),
            onTap: (){
              bool? pop = widget.onSelected?.call(filtered[index]);
              if (pop??true) {
                Navigator.of(context).pop(true);
              }
            },
          );
        },
      ),
    );
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
        x += referenceSize!.width;
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