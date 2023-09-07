import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
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






abstract class ContainsValue<T> {
  T? get value;
}

class SimpleValueString<T> implements ContainsValue<T> {
  @override
  T? value;
  Object string;
  SimpleValueString(this.value, this.string);
  @override
  String toString() {
    return string.toString();
  }
}




class ValueString<T> implements Comparable, ContainsValue<T> {

  @override
  T? value;
  Object string;

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
  int compareTo(other) => other is ValueString  ? _compare(other.value)
                                                : other is T ? _compare(other)
                                                : 1;

  int _compare(T? other) {
    if (value==null) {
      if (other==null) {
        return 0;
      } else {
        return 1;
      }
    } else if (other==null) {
      return -1;
    }
    if (value is Comparable) {
      return (value! as Comparable).compareTo(other);
    } else {
      return (value.toString()).compareTo(other.toString());
    }
  }

}


class ValueStringNum<T extends num> extends ValueString<T> {

  ValueStringNum(T? value, NumberFormat formatter)
      : super(value ?? (0.0 as T), value==null ? '' : formatter.format(value));

}


class ValueStringReference<T> extends ValueString<T> {

  String Function(T value) toStringFunction;

  ValueStringReference(T value, this.toStringFunction)
      : super (value, '');

  @override
  String toString() {
    return value==null ? '' : toStringFunction(value as T);
  }

}






class NumGroupComparingBySum implements ValueString<num>  {

  @override
  num? value = 0;
  List<num?> values;
  NumberFormat? formatter;

  NumGroupComparingBySum(this.values, [this.formatter]){
    for (final element in values) {
      value = value! + (element??0);
    }
  }

  @override
  late Object string = toString();
  @override
  String toString() {
    return formatter==null ? value.toString() : formatter!.format(value);
  }
  @override
  bool operator == (dynamic other) => other is NumGroupComparingBySum && value==other.value || value==other;
  @override
  int get hashCode => value.hashCode;
  @override
  @override
  int compareTo(other) => other is ValueString<num> ? _compare(other.value)
      : other is num ? _compare(other)
      : 1;

  @override
  int _compare(num? other) {
    if (value==null) {
      if (other==null) {
        return 0;
      } else {
        return 1;
      }
    } else if (other==null) {
      return -1;
    }
    if (value is Comparable) {
      return (value!).compareTo(other);
    } else {
      return (value.toString()).compareTo(other.toString());
    }
  }

}

class NumGroupComparingByAverage extends NumGroupComparingBySum {

  NumGroupComparingByAverage(List<num> values, NumberFormat formatter) : super(values, formatter) {
    value = value! / values.length;
  }

}




bool isVisibleInScrollable(BuildContext currentContext, double currentScrollPixels){
  var renderObject = currentContext.findRenderObject()!;
  RenderAbstractViewport viewport = RenderAbstractViewport.of(renderObject);
  var offsetToRevealBottom = viewport.getOffsetToReveal(renderObject, 1.0);
  var offsetToRevealTop = viewport.getOffsetToReveal(renderObject, 0.0);
  if (offsetToRevealBottom.offset > currentScrollPixels ||
      currentScrollPixels > offsetToRevealTop.offset) {
    return false;
  }
  return true;
}