
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:from_zero_ui/from_zero_ui.dart';
import 'package:from_zero_ui/util/my_tooltip.dart';
import 'package:intl/intl.dart';


abstract class ConditionFilter<T> {
  ConditionFilter({required this.extra});
  bool extra;
  String getUiName(BuildContext context);
  String getExtraUiName(BuildContext context);
  String getExtraUiTooltipFromZero(BuildContext context);
  bool isAllowed(dynamic value, Map<dynamic, T> values, dynamic key);
  late FocusNode focusNode = FocusNode();
  Widget buildFormWidget({required BuildContext context, VoidCallback? onValueChanged, VoidCallback? onDelete,});
}


// class FilterIsEmpty extends ConditionFilter {
//   FilterIsEmpty({
//     bool inverse = false,
//   }) : super(extra: inverse);
//   @override
//   String getUiName(BuildContext context) => 'Vacío'; //Is Empty
//   @override
//   String getExtraUiName(BuildContext context) => 'Invertir'; //Reverse
//   @override
//   bool isAllowed(value) {
//     bool result = value==null || value.toString().isEmpty;
//     if (extra) result = !result;
//     return result;
//   }
// }


abstract class FilterText extends ConditionFilter {
  String query;
  FilterText({
    required bool extra,
    required this.query,
  }) : super(extra: extra,);

  @override
  Widget buildFormWidget({required BuildContext context, VoidCallback? onValueChanged, VoidCallback? onDelete,}) {
    return Container(
      height: 42,
      padding: EdgeInsets.only(top: 4,),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          TextFormField(
            autofocus: PlatformExtended.isDesktop,
            focusNode: focusNode,
            initialValue: query,
            onChanged: (v) {
              query = v;
              onValueChanged?.call();
            },
            decoration: InputDecoration(
              labelText: getUiName(context),
              floatingLabelBehavior: FloatingLabelBehavior.always,
              labelStyle: TextStyle(height: 0.75,),
              contentPadding: EdgeInsets.only(top: 30, left: 12, right: 80),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Theme.of(context).accentColor, width: 1,),
              ),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Theme.of(context).disabledColor, width: 1,),
              ),
            ),
          ),
          Positioned(
            right: 38, top: 0, bottom: 0,
            child: Center(
              child: TooltipFromZero(
                message: getExtraUiTooltipFromZero(context),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Positioned(
                      top: 0, left: -32, right: -32,
                      child: Center(
                        child: Text(getExtraUiName(context),
                          style: Theme.of(context).textTheme.caption!.copyWith(height: 1.2),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: StatefulBuilder(
                        builder: (context, checkboxSetState) {
                          return Checkbox(
                            value: extra,
                            onChanged: (value) {
                              extra = value??false;
                              checkboxSetState((){});
                              onValueChanged?.call();
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            right: 2, top: 0, bottom: 0,
            child: Center(
              child: TooltipFromZero(
                message: '${FromZeroLocalizations.of(context).translate('delete')} ${FromZeroLocalizations.of(context).translate('filter')}',
                child: IconButton(
                  icon: Icon(Icons.close),
                  splashRadius: 20,
                  onPressed: onDelete,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// class FilterTextExactly extends ConditionFilter {
//   String query;
//   FilterTextExactly({
//     bool inverse = false,
//     this.query = '',
//   }) : super(extra: inverse);
//   @override
//   String getUiName(BuildContext context) => 'Texto es exactamente'; //Text is exactly
//   @override
//   String getExtraUiName(BuildContext context) => 'Invertir'; //Reverse
//   @override
//   bool isAllowed(value) {
//     bool result = value.toString().toUpperCase()==query.toUpperCase();
//     if (extra) result = !result;
//     return result;
//   }
// }


class FilterTextContains extends FilterText {
  FilterTextContains({
    bool inverse = false,
    String query = '',
  }) : super(extra: inverse, query: query,);
  @override
  String getUiName(BuildContext context) => FromZeroLocalizations.of(context).translate('filter_text_contains');
  @override
  String getExtraUiName(BuildContext context) => FromZeroLocalizations.of(context).translate('reverse');
  @override
  String getExtraUiTooltipFromZero(BuildContext context) => FromZeroLocalizations.of(context).translate('reverse_tooltip');
  @override
  bool isAllowed(value, values, index) {
    bool result = value.toString().toUpperCase().contains(query.toUpperCase());
    if (extra) result = !result;
    return result;
  }
}


class FilterTextStartsWith extends FilterText {
  FilterTextStartsWith({
    bool inverse = false,
    String query = '',
  }) : super(extra: inverse, query: query,);
  @override
  String getUiName(BuildContext context) => FromZeroLocalizations.of(context).translate('filter_text_begins');
  @override
  String getExtraUiName(BuildContext context) => FromZeroLocalizations.of(context).translate('reverse');
  @override
  String getExtraUiTooltipFromZero(BuildContext context) => FromZeroLocalizations.of(context).translate('reverse_tooltip');
  @override
  bool isAllowed(value, values, index) {
    bool result = value.toString().toUpperCase().startsWith(query.toUpperCase());
    if (extra) result = !result;
    return result;
  }
}


class FilterTextEndsWith extends FilterText {
  FilterTextEndsWith({
    bool inverse = false,
    String query = '',
  }) : super(extra: inverse, query: query,);
  @override
  String getUiName(BuildContext context) => FromZeroLocalizations.of(context).translate('filter_text_ends');
  @override
  String getExtraUiName(BuildContext context) => FromZeroLocalizations.of(context).translate('reverse');
  @override
  String getExtraUiTooltipFromZero(BuildContext context) => FromZeroLocalizations.of(context).translate('reverse_tooltip');
  @override
  bool isAllowed(value, values, index) {
    bool result = value.toString().toUpperCase().endsWith(query.toUpperCase());
    if (extra) result = !result;
    return result;
  }
}


abstract class FilterNumber extends ConditionFilter {
  num? query;
  FilterNumber({
    required bool extra,
    required  this.query,
  }) : super(extra: extra,);

  @override
  Widget buildFormWidget({required BuildContext context, VoidCallback? onValueChanged, VoidCallback? onDelete,}) {
    return Container(
      height: 42,
      padding: EdgeInsets.only(top: 4,),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          TextFormField(
            autofocus: PlatformExtended.isDesktop,
            focusNode: focusNode,
            initialValue: query==null ? '' : query.toString(),
            onChanged: (v) {
              try {
                query = num.parse(v);
              } catch (_){
                query = null;
              }
              onValueChanged?.call();
            },
            keyboardType: TextInputType.number,
            inputFormatters: <TextInputFormatter>[FilteringTextInputFormatter.allow(RegExp( r'[0-9.]')),],
            decoration: InputDecoration(
              labelText: getUiName(context),
              floatingLabelBehavior: FloatingLabelBehavior.always,
              labelStyle: TextStyle(height: 0.75,),
              contentPadding: EdgeInsets.only(top: 30, left: 12, right: 80),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Theme.of(context).accentColor, width: 1,),
              ),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Theme.of(context).disabledColor, width: 1,),
              ),
            ),
          ),
          Positioned(
            right: 38, top: 0, bottom: 0,
            child: Center(
              child: TooltipFromZero(
                message: getExtraUiTooltipFromZero(context),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Positioned(
                      top: 0, left: -32, right: -32,
                      child: Center(
                        child: Text(getExtraUiName(context),
                          style: Theme.of(context).textTheme.caption!.copyWith(height: 1.2),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: StatefulBuilder(
                        builder: (context, checkboxSetState) {
                          return Checkbox(
                            value: extra,
                            onChanged: (value) {
                              extra = value??false;
                              checkboxSetState((){});
                              onValueChanged?.call();
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            right: 2, top: 0, bottom: 0,
            child: Center(
              child: TooltipFromZero(
                message: '${FromZeroLocalizations.of(context).translate('delete')} ${FromZeroLocalizations.of(context).translate('filter')}',
                child: IconButton(
                  icon: Icon(Icons.close),
                  splashRadius: 20,
                  onPressed: onDelete,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}


// class FilterNumberEqualTo extends FilterNumber {
//   FilterNumberEqualTo({
//     bool inverse = false,
//     num? query,
//   }) : super(inverse: inverse, query: query,);
//   @override
//   String getUiName(BuildContext context) => 'Número igual a'; //Number equal to
//   @override
//   String getExtraUiName(BuildContext context) => 'Invertir'; //Reverse
//   @override
//   bool isAllowed(value) {
//     if (query==null) return true;
//     if (!(value is num)) return false;
//     bool result = value==query;
//     if (extra) result = !result;
//     return result;
//   }
// }


class FilterNumberGreaterThan extends FilterNumber {
  FilterNumberGreaterThan({
    bool inclusive = true,
    num? query,
  }) : super(extra: inclusive, query: query,);
  @override
  String getUiName(BuildContext context) => FromZeroLocalizations.of(context).translate('filter_number_greater');
  @override
  String getExtraUiName(BuildContext context) => FromZeroLocalizations.of(context).translate('include');
  @override
  String getExtraUiTooltipFromZero(BuildContext context) => FromZeroLocalizations.of(context).translate('include_tooltip');
  @override
  bool isAllowed(v, values, index) {
    if (query==null) return true;
    final value = (v is ContainsValue) ? v.value : v;
    if (!(value is num)) return false;
    bool result = extra ? value>=query! : value>query!;
    return result;
  }
}


class FilterNumberLessThan extends FilterNumber {
  FilterNumberLessThan({
    bool inclusive = true,
    num? query,
  }) : super(extra: inclusive, query: query,);
  @override
  String getUiName(BuildContext context) => FromZeroLocalizations.of(context).translate('filter_number_less');
  @override
  String getExtraUiName(BuildContext context) => FromZeroLocalizations.of(context).translate('include');
  @override
  String getExtraUiTooltipFromZero(BuildContext context) => FromZeroLocalizations.of(context).translate('include_tooltip');
  @override
  bool isAllowed(v, values, index) {
    if (query==null) return true;
    final value = (v is ContainsValue) ? v.value : v;
    if (!(value is num)) return false;
    bool result = extra ? value<=query! : value<query!;
    return result;
  }
}


abstract class FilterDate extends ConditionFilter {
  DateTime? query;
  FilterDate({
    required bool extra,
    required this.query,
  }) : super(extra: extra,);

  @override
  Widget buildFormWidget({required BuildContext context, VoidCallback? onValueChanged, VoidCallback? onDelete,}) {
    return Container(
      height: 40,
      padding: EdgeInsets.only(bottom: 2,),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          StatefulBuilder(
            builder: (context, datePickerSetState) {
              return DatePickerFromZero(
                value: query,
                clearable: false,
                focusNode: focusNode,
                title: getUiName(context),
                formatter: DateFormat.yMMMMd(),
                firstDate: DateTime(1900),
                lastDate: DateTime(2200),
                onSelected: (v) {
                  onValueChanged?.call();
                  datePickerSetState((){
                    query = v;
                  });
                },
                buttonChildBuilder: (context, title, hint, value, formatter, enabled, clearable) {
                  return Container(
                    height: 38,
                    alignment: Alignment.centerLeft,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        SizedBox(width: 4,),
                        Expanded(
                          child: MaterialKeyValuePair(
                            title: title,
                            titleStyle: Theme.of(context).textTheme.caption!.copyWith(height: 0.8),
                            value: value==null ? '' : formatter.format(value),
                            valueStyle: TextStyle(fontSize: 15,),
                          ),
                        ),
                        SizedBox(width: 4,),
                      ],
                    ),
                  );
                },
              );
            },
          ),
          Positioned(
            right: 38, top: 0, bottom: 0,
            child: Center(
              child: TooltipFromZero(
                message: getExtraUiTooltipFromZero(context),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Positioned(
                      top: 0, left: -32, right: -32,
                      child: Center(
                        child: Text(getExtraUiName(context),
                          style: Theme.of(context).textTheme.caption!.copyWith(height: 1.2),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: StatefulBuilder(
                        builder: (context, checkboxSetState) {
                          return Checkbox(
                            value: extra,
                            onChanged: (value) {
                              extra = value??false;
                              checkboxSetState((){});
                              onValueChanged?.call();
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            right: 2, top: 0, bottom: 0,
            child: Center(
              child: TooltipFromZero(
                message: '${FromZeroLocalizations.of(context).translate('delete')} ${FromZeroLocalizations.of(context).translate('filter')}',
                child: IconButton(
                  icon: Icon(Icons.close),
                  splashRadius: 20,
                  onPressed: onDelete,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
bool isSameDay(DateTime a, DateTime b) {
  return a.year == b.year && a.month == b.month && a.day == b.day;
}


// class FilterDateExactDay extends ConditionFilter {
//   DateTime? query;
//   FilterDateExactDay({
//     bool inverse = false,
//     this.query,
//   }) : super(extra: inverse);
//   @override
//   String getUiName(BuildContext context) => 'Fecha es día exacto'; //Date is exact day
//   @override
//   String getExtraUiName(BuildContext context) => 'Invertir'; //Reverse
//   @override
//   bool isAllowed(value) {
//     if (query==null) return true;
//     if (!(value is DateTime)) return false;
//     bool result = isSameDay(value, query!) ;
//     if (extra) result = !result;
//     return result;
//   }
// }


class FilterDateAfter extends FilterDate {
  FilterDateAfter({
    bool inclusive = true,
    DateTime? query,
  }) : super(extra: inclusive, query: query,);
  @override
  String getUiName(BuildContext context) => FromZeroLocalizations.of(context).translate('filter_date_after');
  @override
  String getExtraUiName(BuildContext context) => FromZeroLocalizations.of(context).translate('include');
  @override
  String getExtraUiTooltipFromZero(BuildContext context) => FromZeroLocalizations.of(context).translate('include_tooltip');
  @override
  bool isAllowed(v, values, index) {
    if (query==null) return true;
    final value = (v is ContainsValue) ? v.value : v;
    if (!(value is DateTime)) return false;
    bool result = value.isAfter(query!) || (extra&&isSameDay(value, query!));
    return result;
  }
}


class FilterDateBefore extends FilterDate {
  FilterDateBefore({
    bool inclusive = true,
    DateTime? query,
  }) : super(extra: inclusive, query: query,);
  @override
  String getUiName(BuildContext context) => FromZeroLocalizations.of(context).translate('filter_date_before');
  @override
  String getExtraUiName(BuildContext context) => FromZeroLocalizations.of(context).translate('include');
  @override
  String getExtraUiTooltipFromZero(BuildContext context) => FromZeroLocalizations.of(context).translate('include_tooltip');
  @override
  bool isAllowed(v, values, index) {
    if (query==null) return true;
    final value = (v is ContainsValue) ? v.value : v;
    if (!(value is DateTime)) return false;
    bool result = value.isBefore(query!) || (extra&&isSameDay(value, query!));
    return result;
  }
}