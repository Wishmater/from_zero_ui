

class ComparableList<T extends Comparable> with Comparable {

  final List<T> list;

  ComparableList({
    List<T>? list,
  })  : this.list = list ?? [];

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
      && (list.length==0&&other.list.length==0 || other.list==this.list);

  @override
  int get hashCode => list.hashCode;

  @override
  int compareTo(other) {
    if (other is! ComparableList) return -1;
    return list.length.compareTo(other.list.length);
  }

  T get first => list.first;

  T get last => list.last;

  int get length => list.length;

  List operator +(List other) => list + (other as List<T>);

  operator [](int index) => list[index];

  void operator []=(int index, value) => list[index] = value;

  void add(T value) => list.add(value);

  void insert(int index, T value) => list.insert(index, value);

  void addAll(Iterable iterable) => list.addAll(iterable as Iterable<T>);

  bool remove(T value) => list.remove(value);

  T removeAt(int index) => list.removeAt(index);

  void clear() => list.clear();

  bool contains(Object? element) => list.contains(element);

  bool get isEmpty => list.isEmpty;

  bool get isNotEmpty => list.isNotEmpty;

  Iterable where(bool Function(T element) test) => list.where(test);

  int indexOf(T element) => list.indexOf(element);

}