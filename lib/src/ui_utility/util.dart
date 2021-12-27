import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';


final fromZeroDefaultShortcuts = {
  LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyF): SearchIntent(),
  LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyZ): UndoIntent(),
  LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyY): RedoIntent(),
  LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.shift, LogicalKeyboardKey.keyZ): RedoIntent(),
};
class SearchIntent extends Intent {}
class UndoIntent extends Intent {}
class RedoIntent extends Intent {}




@deprecated
class FormattedNum with Comparable implements ContainsValue{

  num value;
  NumberFormat formatter;
  bool? alwaysBigger;

  FormattedNum(this.value, this.formatter, {this.alwaysBigger});

  @override
  String toString() {
    return formatter.format(value);
  }
  @override
  bool operator == (dynamic other) => other is FormattedNum && this.value==other.value || value==other;
  @override
  int get hashCode => value.hashCode;
  @override
  int compareTo(other) =>
      alwaysBigger==true ? 1 : alwaysBigger==false ? -1
          : other is FormattedNum
          ? other.alwaysBigger==true ? -1
          : other.alwaysBigger==false ? 1
          : value.compareTo(other.value)
          : other is num ? value.compareTo(other) : 1;

  bool get isEmpty => false;
  bool get isNotEmpty => true;

}


abstract class ContainsValue {
  dynamic get value;
}

class SimpleValueString implements ContainsValue {
  var value;
  var string;
  SimpleValueString(this.value, this.string);
  @override
  String toString() {
    return string.toString();
  }
}




class ValueString<T extends Comparable> with Comparable implements ContainsValue {

  T value;
  var string;

  ValueString(this.value, this.string);

  @override
  String toString() {
    return string.toString();
  }
  @override
  bool operator == (dynamic other) => other is ValueString && this.value==other.value || value==other;
  @override
  int get hashCode => value.hashCode;
  @override
  int compareTo(other) => other is ValueString ? value.compareTo(other.value)
      : other is T ? value.compareTo(other) : 1;

}

class NumValueString<T extends num> extends ValueString<T> {

  NumValueString(T? value, NumberFormat formatter)
      : super(value ?? (0.0 as T), value==null ? '' : formatter.format(value));

}










class NumGroupComparingBySum with Comparable implements ValueString<num>  {

  num value = 0;
  List<num> values;
  NumberFormat? formatter;

  NumGroupComparingBySum(this.values, [this.formatter]){
    values.forEach((element) {
      value += element;
    });
  }

  late dynamic string = toString();
  @override
  String toString() {
    return formatter==null ? value.toString() : formatter!.format(value);
  }
  @override
  bool operator == (dynamic other) => other is NumGroupComparingBySum && this.value==other.value || value==other;
  @override
  int get hashCode => value.hashCode;
  @override
  int compareTo(other) => other is NumGroupComparingBySum ? value.compareTo(other.value)
      : other is num ? value.compareTo(other) : 1;

}

class NumGroupComparingByAverage extends NumGroupComparingBySum {

  NumGroupComparingByAverage(List<num> values, NumberFormat formatter) : super(values, formatter){
    value /= values.length;
  }

}
