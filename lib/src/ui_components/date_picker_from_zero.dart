import 'package:animations/animations.dart';
import 'package:dartx/dartx.dart';
import 'package:flutter/material.dart';
import 'package:from_zero_ui/from_zero_ui.dart';
import 'package:from_zero_ui/src/ui_utility/popup_from_zero.dart';
import 'package:intl/intl.dart';
import 'package:from_zero_ui/util/time_picker_dialog_from_zero.dart' as timePickerDialogFromZero;

typedef Widget DatePickerButtonChildBuilder<T>(BuildContext context, String? title, String? hint, DateTime? value, DateFormat formatter, bool enabled, bool clearable,);
/// returns true if navigator should pop after (default true)
typedef bool? OnDateSelected(DateTime? value);

enum DateTimePickerType {
  date,
  time,
}

class DatePickerFromZero extends StatefulWidget {

  final DateTime? value;
  final DateTime firstDate;
  final DateTime lastDate;
  final DateFormat formatter;
  final VoidCallback? onCanceled;
  final OnDateSelected? onSelected;
  final String? title;
  final String? hint;
  final bool enabled;
  final DatePickerButtonChildBuilder? buttonChildBuilder;
  final double? popupWidth;
  final bool clearable;
  final FocusNode? focusNode;
  final EdgeInsets? buttonPadding;
  final DateTimePickerType type;

  DatePickerFromZero({
    this.value,
    required this.firstDate,
    required this.lastDate,
    DateFormat? formatter,
    this.onSelected,
    this.onCanceled,
    this.title,
    this.hint,
    this.buttonChildBuilder,
    this.enabled = true,
    this.clearable = true,
    this.popupWidth,
    this.focusNode,
    this.buttonPadding,
    this.type = DateTimePickerType.date,
  }) :  this.formatter = formatter ?? DateFormat(DateFormat.YEAR_MONTH_DAY);

  @override
  _DatePickerFromZeroState createState() => _DatePickerFromZeroState();

  static Widget defaultButtonChildBuilder(BuildContext context, String? title, String? hint, dynamic value, DateTimePickerType type, DateFormat formatter, bool enabled, bool clearable) {
    final formattedValue = value==null ? null : type==DateTimePickerType.time
        ? TimeOfDay.fromDateTime(value).format(context)
        : formatter.format(value);
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
                      value: value==null ? (hint ?? '') : formattedValue,
                      valueStyle: Theme.of(context).textTheme.subtitle1!.copyWith(
                        height: 1,
                        color: value==null ? Theme.of(context).textTheme.caption!.color!
                            : Theme.of(context).textTheme.bodyText1!.color!.withOpacity(enabled ? 1 : 0.75),
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

class _DatePickerFromZeroState extends State<DatePickerFromZero> {

  GlobalKey buttonKey = GlobalKey();

  late final buttonFocusNode = widget.focusNode ?? FocusNode();
  @override
  Widget build(BuildContext context) {
    Widget child;
    if (widget.buttonChildBuilder==null) {
      child = DatePickerFromZero.defaultButtonChildBuilder(context, widget.title, widget.hint, widget.value, widget.type, widget.formatter, widget.enabled, widget.clearable);
    } else {
      child = widget.buttonChildBuilder!(context, widget.title, widget.hint, widget.value, widget.formatter, widget.enabled, widget.clearable);
    }
    return Stack(
      children: [
        TextButton(
          key: buttonKey,
          style: TextButton.styleFrom(
            padding: widget.buttonPadding,
          ),
          child: child,
          focusNode: buttonFocusNode,
          onPressed: widget.enabled ? () async {
            buttonFocusNode.requestFocus();
            bool? accepted = await showPopupFromZero<bool>(
              context: context,
              anchorKey: buttonKey,
              builder: (context) {
                return DatePickerFromZeroPopup(
                  title: widget.title,
                  value: widget.value,
                  firstDate: widget.firstDate,
                  lastDate: widget.lastDate,
                  onSelected: widget.onSelected,
                  type: widget.type,
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
                    child: widget.value!=null ? TooltipFromZero(
                      message: FromZeroLocalizations.of(context).translate('clear'),
                      child: IconButton(
                        icon: Icon(Icons.close),
                        splashRadius: 20,
                        onPressed: () {
                          widget.onSelected?.call(null);
                        },
                      ),
                    ) : SizedBox.shrink(),
                  )
              ),
            ),
          ),
      ],
    );
  }

}



class DatePickerFromZeroPopup extends StatefulWidget {

  final DateTime? value;
  final DateTime firstDate;
  final DateTime lastDate;
  final OnDateSelected? onSelected;
  final String? title;
  final DateTimePickerType type;

  DatePickerFromZeroPopup({
    this.value,
    required this.firstDate,
    required this.lastDate,
    this.onSelected,
    this.title,
    this.type = DateTimePickerType.date,
  });

  @override
  _DatePickerFromZeroPopupState createState() => _DatePickerFromZeroPopupState();

}

class _DatePickerFromZeroPopupState extends State<DatePickerFromZeroPopup> {

  @override
  Widget build(BuildContext context) {
    switch (widget.type) {

      case DateTimePickerType.time:
        return timePickerDialogFromZero.TimePickerDialog(
          initialTime: TimeOfDay.fromDateTime(widget.value ?? DateTime.now().copyWith(minute: 0)),
          includeDialog: false,
          useLayoutBuilderInsteadOfMediaQuery: true,
          helpText: widget.title,
          onSelected: (v) {
            bool? pop = widget.onSelected?.call((widget.value??DateTime.now()).copyWith(hour: v.hour, minute: v.minute));
            if (pop??true) {
              Navigator.of(context).pop(true);
            }
          },
        );

      case DateTimePickerType.date:
        return Column(
          mainAxisSize: MainAxisSize.min,
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
            ResponsiveHorizontalInsets(
              bigPadding: 8,
              child: CalendarDatePicker( //DatePickerDialog shows a material one, but it's just unnecessarily more complicated
                initialDate: widget.value ?? DateTime.now(),
                firstDate: widget.value==null ? widget.firstDate
                    : widget.value!.isBefore(widget.firstDate) ? widget.value! : widget.firstDate,
                lastDate: widget.value==null ? widget.lastDate
                    : widget.value!.isAfter(widget.lastDate) ? widget.value! : widget.lastDate,
                onDateChanged: (v) {
                  bool? pop = widget.onSelected?.call(v);
                  if (pop??true) {
                    Navigator.of(context).pop(true);
                  }
                },
              ),
            ),
            SizedBox(height: 16,)
          ],
        );

    }
  }

}

