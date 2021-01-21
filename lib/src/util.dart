import 'package:intl/intl.dart';



class FormattedNum with Comparable{

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

class ValueString<T extends Comparable> with Comparable{

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




class NumGroupComparingBySum with Comparable{

  num value = 0;
  List<num> values;
  NumberFormat? formatter;

  NumGroupComparingBySum(this.values, [this.formatter]){
    values.forEach((element) {
      value += element;
    });
  }

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

class NumGroupComparingByAverage extends NumGroupComparingBySum{

  NumGroupComparingByAverage(List<num> values, NumberFormat formatter) : super(values, formatter){
    value /= values.length;
  }

}

class NumGroupAlwaysBiggest extends NumGroupComparingBySum{

  NumGroupAlwaysBiggest(List<num> values, NumberFormat formatter) : super(values, formatter){
    value = double.infinity;
  }

}


class NumGroupAlwaysSmallest extends NumGroupComparingBySum{

  NumGroupAlwaysSmallest(List<num> values, NumberFormat formatter) : super(values, formatter){
    value = -double.infinity;
  }

}