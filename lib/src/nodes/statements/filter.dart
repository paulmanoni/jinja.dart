import '../../context.dart';
import '../core.dart';
import '../expressions/filter.dart';

class FilterBlockStatement extends Statement {
  FilterBlockStatement(this.filters, this.body);

  final List<Filter> filters;

  final Node body;

  @override
  void accept(StringSink outSink, Context context) {
    var result;

    if (body is Expression) {
      result = (body as Expression).resolve(context);
    } else {
      final temp = StringBuffer();
      body.accept(temp, context);
      result = temp.toString();
    }

    for (final filter in filters) {
      result = filter.filter(context, result);
    }

    outSink.write(result);
  }

  @override
  String toDebugString([int level = 0]) {
    final buffer = StringBuffer(' ' * level);
    buffer..write('filter ')..write(filters.first.toDebugString());

    for (final filter in filters.sublist(1)) {
      buffer..write(' | ')..write(filter.toDebugString());
    }

    buffer
      ..writeln()
      ..write(body.toDebugString(level + 1));
    return buffer.toString();
  }

  @override
  String toString() {
    return 'FilterBlock($filters, $body)';
  }
}
