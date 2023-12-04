import 'package:dartx/dartx.dart';
import 'package:flutter/material.dart';
import 'package:from_zero_ui/from_zero_ui.dart';
import 'package:from_zero_ui/util/copied_flutter_widgets/time_picker_dialog_from_zero.dart' as time_picker_dialog_from_zero;
import 'package:intl/intl.dart';

typedef DatePickerButtonChildBuilder = Widget Function(BuildContext context, String? title, String? hint, DateTime? value, DateFormat formatter, bool enabled, bool showClearButton,);
/// returns true if navigator should pop after (default true)
typedef OnDateSelected = bool? Function(DateTime? value);

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
  final bool showClearButton;
  final FocusNode? focusNode;
  final ButtonStyle? buttonStyle; /// if null, an InkWell will be used instead
  final DateTimePickerType type;

  DatePickerFromZero({
    required this.firstDate,
    required this.lastDate,
    this.value,
    DateFormat? formatter,
    this.onSelected,
    this.onCanceled,
    this.title,
    this.hint,
    this.buttonChildBuilder,
    this.enabled = true,
    this.clearable = true,
    bool? showClearButton,
    this.popupWidth,
    this.focusNode,
    this.buttonStyle = const ButtonStyle(
      padding: MaterialStatePropertyAll(EdgeInsets.zero),
    ),
    this.type = DateTimePickerType.date,
    super.key,
  })  : showClearButton = showClearButton ?? clearable,
        formatter = formatter ?? DateFormat(DateFormat.YEAR_MONTH_DAY);

  @override
  DatePickerFromZeroState createState() => DatePickerFromZeroState();

  static Widget defaultButtonChildBuilder(BuildContext context, String? title, String? hint, dynamic value, DateTimePickerType type, DateFormat formatter, bool enabled, bool showClearButton) {
    final theme = Theme.of(context);
    final formattedValue = value==null ? null : type==DateTimePickerType.time
        ? TimeOfDay.fromDateTime(value).format(context)
        : formatter.format(value);
    return IntrinsicWidth(
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          minHeight: 38, minWidth: 192,
        ),
        child: Padding(
          padding: EdgeInsets.only(right: enabled&&showClearButton ? 32 : 0),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const SizedBox(width: 8,),
              Expanded(
                child: value==null&&hint==null&&title!=null
                    ? Text(title, style: theme.textTheme.titleMedium!.copyWith(
                        color: enabled&&value!=null ? theme.textTheme.bodyLarge!.color : theme.disabledColor,
                      ),)
                    : MaterialKeyValuePair(
                        title: title,
                        value: value==null ? (hint ?? '') : formattedValue,
                        valueStyle: theme.textTheme.titleMedium!.copyWith(
                          height: 1,
                          color: enabled&&value!=null ? theme.textTheme.bodyLarge!.color : theme.disabledColor,
                        ),
                      ),
                  ),
              const SizedBox(width: 4,),
              if (enabled && !showClearButton)
                const Icon(Icons.arrow_drop_down),
              const SizedBox(width: 4,),
            ],
          ),
        ),
      ),
    );
  }

}

class DatePickerFromZeroState extends State<DatePickerFromZero> {

  final buttonKey = GlobalKey();
  late FocusNode buttonFocusNode = widget.focusNode ?? FocusNode();
  bool _isPushedPopup = false;

  @override
  void didUpdateWidget(covariant DatePickerFromZero oldWidget) {
    super.didUpdateWidget(oldWidget);
    buttonFocusNode = widget.focusNode ?? buttonFocusNode;
    if (!widget.enabled && _isPushedPopup) {
      final thisRoute = ModalRoute.of(context);
      if (thisRoute!=null) {
        Navigator.of(context).popUntil((route) {
          return route==thisRoute;
        });
      } else {
        Navigator.of(context).pop();
      }
      // _popPopup();
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget child;
    if (widget.buttonChildBuilder==null) {
      child = DatePickerFromZero.defaultButtonChildBuilder(context, widget.title, widget.hint, widget.value, widget.type, widget.formatter, widget.enabled, widget.clearable&&widget.showClearButton);
    } else {
      child = widget.buttonChildBuilder!(context, widget.title, widget.hint, widget.value, widget.formatter, widget.enabled, widget.clearable&&widget.showClearButton);
    }
    final onPressed = widget.enabled ? () async {
      buttonFocusNode.requestFocus();
      _isPushedPopup = true;
      bool? accepted = await showPopupFromZero<bool>(
        context: context,
        anchorKey: buttonKey,
        builder: (context) {
          return DatePickerFromZeroPopup(
            title: widget.title,
            value: widget.value,
            firstDate: widget.firstDate,
            lastDate: widget.lastDate,
            clearable: widget.clearable,
            onSelected: (value) {
              if (widget.enabled) {
                widget.onSelected?.call(value);
              }
            },
            type: widget.type,
          );
        },
      );
      _isPushedPopup = false;
      if (accepted!=true) {
        widget.onCanceled?.call();
      }
    } : null;
    if (widget.buttonStyle!=null) {
      child = TextButton(
        key: buttonKey,
        style: widget.buttonStyle,
        focusNode: buttonFocusNode,
        onPressed: onPressed,
        child: child,
      );
    } else {
      child = InkWell(
        key: buttonKey,
        focusNode: buttonFocusNode,
        onTap: onPressed,
        child: child,
      );
    }
    return Stack(
      children: [
        child,
        if (widget.enabled && widget.clearable && widget.showClearButton)
          Positioned(
            right: 8, top: 0, bottom: 0,
            child: ExcludeFocus(
              child: Center(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
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
                        icon: const Icon(Icons.close),
                        splashRadius: 20,
                        onPressed: () {
                          if (widget.enabled) {
                            widget.onSelected?.call(null);
                          }
                        },
                      ),
                    ) : const SizedBox.shrink(),
                  ),
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
  final bool clearable;

  const DatePickerFromZeroPopup({
    required this.firstDate,
    required this.lastDate,
    this.value,
    this.onSelected,
    this.title,
    this.type = DateTimePickerType.date,
    this.clearable = true,
    super.key,
  });

  @override
  DatePickerFromZeroPopupState createState() => DatePickerFromZeroPopupState();

}

class DatePickerFromZeroPopupState extends State<DatePickerFromZeroPopup> {

  @override
  Widget build(BuildContext context) {
    switch (widget.type) {

      case DateTimePickerType.time:
        return time_picker_dialog_from_zero.TimePickerDialog(
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
                    style: Theme.of(context).textTheme.titleMedium,
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
            if (widget.clearable)
              Container(
                alignment: Alignment.bottomRight,
                padding: const EdgeInsets.only(right: 16),
                child: TextButton(
                  style: TextButton.styleFrom(
                    foregroundColor: Theme.of(context).textTheme.bodyLarge!.color!.withOpacity(0.9),
                  ),
                  onPressed: () {
                    bool? pop = widget.onSelected?.call(null);
                    if (pop??true) {
                      Navigator.of(context).pop(true);
                    }
                  },
                  child: const Text('Sin Fecha'), // TODO 3 internationalize
                ),
              ),
            const SizedBox(height: 16,),
          ],
        );

    }
  }

}

