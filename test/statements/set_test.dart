import 'package:jinja/jinja.dart';
import 'package:jinja/get_field.dart';
import 'package:jinja/src/exceptions.dart';
import 'package:test/test.dart';

void main() {
  group('set', () {
    final envTrim = Environment(getField: getField, trimBlocks: true);

    test('simple', () {
      final template = envTrim.fromString('{% set foo = 1 %}{{ foo }}');
      expect(template.renderMap(), equals('1'));
      // TODO: добавить тест: module foo == 1 = add test ..
    });

    test('block', () {
      final template =
          envTrim.fromString('{% set foo %}42{% endset %}{{ foo }}');
      expect(template.renderMap(), equals('42'));
      // TODO: добавить тест: module foo == '42' = add test ..
    });

    test('block escaping', () {
      final env = Environment(autoEscape: true);
      final template = env.fromString('{% set foo %}<em>{{ test }}</em>'
          '{% endset %}foo: {{ foo }}');
      expect(template.render(test: '<unsafe>'),
          equals('foo: <em>&lt;unsafe&gt;</em>'));
    });

    test('set invalid', () {
      expect(() => envTrim.fromString('{% set foo["bar"] = 1 %}'),
          throwsA(isA<TemplateSyntaxError>()));

      final template = envTrim.fromString('{% set foo.bar = 1 %}');
      expect(
          () => template.render(foo: <Object, Object>{}),
          throwsA(predicate<Object>((Object e) =>
              e is TemplateRuntimeError &&
              e.message == 'non-namespace object')));
    });

    test('namespace redefined', () {
      final template = envTrim.fromString('{% set ns = namespace() %}'
          '{% set ns.bar = "hi" %}');
      expect(
          () => template.render(namespace: () => <Object, Object>{}),
          throwsA(predicate<Object>((Object e) =>
              e is TemplateRuntimeError &&
              e.message == 'non-namespace object')));
    });

    test('namespace', () {
      final template = envTrim.fromString('{% set ns = namespace() %}'
          '{% set ns.bar = "42" %}'
          '{{ ns.bar }}');
      expect(template.renderMap(), equals('42'));
    });

    test('namespace block', () {
      final template = envTrim.fromString('{% set ns = namespace() %}'
          '{% set ns.bar %}42{% endset %}'
          '{{ ns.bar }}');
      expect(template.renderMap(), equals('42'));
    });

    test('init namespace', () {
      final template = envTrim.fromString('{% set ns = namespace(d, self=37) %}'
          '{% set ns.b = 42 %}'
          '{{ ns.a }}|{{ ns.self }}|{{ ns.b }}');
      expect(template.render(d: <String, Object>{'a': 13}), equals('13|37|42'));
    });

    test('namespace loop', () {
      final template =
          envTrim.fromString('{% set ns = namespace(found=false) %}'
              '{% for x in range(4) %}'
              '{% if x == v %}'
              '{% set ns.found = true %}'
              '{% endif %}'
              '{% endfor %}'
              '{{ ns.found }}');
      expect(template.render(v: 3), equals('true'));
      expect(template.render(v: 4), equals('false'));
    });

    // TODO: добавить тест: namespace macro = add test ..

    test('block escapeing filtered', () {
      final env = Environment(autoEscape: true);
      final template =
          env.fromString('{% set foo | trim %}<em>{{ test }}</em>    '
              '{% endset %}foo: {{ foo }}');
      expect(template.render(test: '<unsafe>'),
          equals('foo: <em>&lt;unsafe&gt;</em>'));
    });

    test('block filtered', () {
      final template = envTrim.fromString(
          '{% set foo | trim | length | string %} 42    {% endset %}'
          '{{ foo }}');
      expect(template.renderMap(), equals('2'));
      // TODO: добавить тест: module foo == '2' = add test ..
    });

    test('block filtered set', () {
      dynamic myfilter(Object value, Object arg) {
        assert(arg == ' xxx ');
        return value;
      }

      envTrim.filters['myfilter'] = myfilter;
      final template = envTrim.fromString('{% set a = " xxx " %}'
          '{% set foo | myfilter(a) | trim | length | string %}'
          ' {% set b = " yy " %} 42 {{ a }}{{ b }}   '
          '{% endset %}'
          '{{ foo }}');
      expect(template.renderMap(), equals('11'));
      // TODO: добавить тест: module foo == '11' = add test ..
    });
  });
}
