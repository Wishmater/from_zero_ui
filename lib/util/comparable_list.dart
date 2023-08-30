import 'package:collection/collection.dart';
import 'package:from_zero_ui/from_zero_ui.dart';


/// for passing lists into a provider familiy and maintaining equality of arguments
class DeepEqualityList<T> extends ComparableListBase<T> {

  DeepEqualityList({
    super.list,
  });

  @override
  bool operator == (dynamic other) => other is DeepEqualityList<T>
      && const DeepCollectionEquality().equals(list, other.list);

  @override
  int get hashCode => Object.hashAll(list);

  @override
  int compareTo(other) {
    if (other is! DeepEqualityList) return -1;
    return const DeepCollectionEquality().equals(list, other.list) ? 0
        : list.length.compareTo(other.list.length);
  }

}


/// for use in ListField, elements have to also be Comparable
class ComparableList<T extends Comparable> extends ComparableListBase<T> {

  ComparableList({
    super.list,
  });

  ComparableList<T> copyWith({
    List<T>? list,
    bool deepCopy = false,
  }) {
    return ComparableList<T>(
      list: list ?? (!deepCopy
                        ? List.from(this.list)
                        : this.list.map((dynamic e) {
                          try {
                            return e.copyWith() as T;
                          } catch(_) {}
                          return e as T;
                        }).toList()),
    );
  }

  @override
  bool operator == (dynamic other) => other is ComparableList<T>
      && (list.isEmpty&&other.list.isEmpty || other.list==list);

  @override
  int get hashCode => list.hashCode;

  @override
  int compareTo(other) {
    if (other is! ComparableList) return -1;
    return list.length.compareTo(other.list.length);
  }

  ComparableList<T> clone() {
    return ComparableList<T>(list: List.from(list));
  }

}


abstract class ComparableListBase<T> implements Comparable, ContainsValue<List<T>> {

  final List<T> list;
  @override
  List<T>? get value => list;

  ComparableListBase({
    List<T>? list,
  })  : list = list ?? [];

  @override
  String toString() {
    return '$runtimeType: $list';
  }

  T get first => list.first;

  T get last => list.last;

  int get length => list.length;

  List operator +(List other) => list + (other as List<T>);

  T operator [](int index) => list[index];

  void operator []=(int index, value) => list[index] = value;

  void add(T value) => list.add(value);

  void insert(int index, T value) => list.insert(index, value);

  void addAll(Iterable iterable) => list.addAll(iterable.cast<T>());

  bool remove(T value) => list.remove(value);

  T removeAt(int index) => list.removeAt(index);

  void clear() => list.clear();

  bool contains(Object? element) => list.contains(element);

  bool get isEmpty => list.isEmpty;

  bool get isNotEmpty => list.isNotEmpty;

  Iterable where(bool Function(T element) test) => list.where(test);

  int indexOf(T element) => list.indexOf(element);

}