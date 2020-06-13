import '../../context.dart';
import '../../exceptions.dart';
import '../../runtime.dart';
import '../core.dart';

abstract class SetStatement extends Statement {
  String get target;
  String get field;

  void assign(Context context, Object value) {
    if (field != null) {
      final nameSpace = context[target];

      if (nameSpace is NameSpace) {
        nameSpace[field] = value;
        return;
      }

      throw TemplateRuntimeError('non-namespace object');
    }

    context[target] = value;
  }
}

class SetInlineStatement extends SetStatement {
  SetInlineStatement(this.target, this.value, {this.field});

  @override
  final target;

  @override
  final field;

  final Expression value;

  @override
  void accept(StringSink outSink, Context context) {
    assign(context, value.resolve(context));
  }

  @override
  String toDebugString([int level = 0]) {
    return '${' ' * level}set $target = ${value.toDebugString()}';
  }

  @override
  String toString() {
    return 'Set($target, $value})';
  }
}

class SetBlockStatement extends SetStatement {
  SetBlockStatement(this.target, this.body, {this.field});

  @override
  final target;

  @override
  final field;

  final Node body;

  @override
  void accept(StringSink outSink, Context context) {
    assign(context, body);
  }

  @override
  String toDebugString([int level = 0]) {
    final buffer = StringBuffer(' ' * level);
    buffer.write('set $target');

    // TODO: проверить: Set.toDebugString() = check: Set.toDebugString()
    // if (filter != null) {
    //   buffer.writeln(' | ${filter.toDebugString()}');
    // } else {
    //   buffer.writeln();
    // }

    buffer.write(body.toDebugString(level + 1));
    return buffer.toString();
  }

  @override
  String toString() {
    return 'Set($target, $body})';
  }
}
