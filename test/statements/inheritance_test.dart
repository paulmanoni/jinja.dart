import 'package:jinja/jinja.dart';
import 'package:jinja/src/exceptions.dart';
import 'package:jinja/src/utils.dart';
import 'package:test/test.dart';

const String layout = '''|{% block block1 %}block 1 from layout{% endblock %}
|{% block block2 %}block 2 from layout{% endblock %}
|{% block block3 %}
{% block block4 %}nested block 4 from layout{% endblock %}
{% endblock %}|''';

const String level1 = '''{% extends "layout" %}
{% block block1 %}block 1 from level1{% endblock %}''';

const String level2 = '''{% extends "level1" %}
{% block block2 %}{% block block5 %}nested block 5 from level2{%
endblock %}{% endblock %}''';

const String level3 = '''{% extends "level2" %}
{% block block5 %}block 5 from level3{% endblock %}
{% block block4 %}block 4 from level3{% endblock %}''';

const String level4 = '''{% extends "level3" %}
{% block block3 %}block 3 from level4{% endblock %}''';

const String working = '''{% extends "layout" %}
{% block block1 %}
  {% if false %}
    {% block block2 %}
      this should workd
    {% endblock %}
  {% endif %}
{% endblock %}''';

const String doubleextends = '''{% extends "layout" %}
{% extends "layout" %}
{% block block1 %}
  {% if false %}
    {% block block2 %}
      this should workd
    {% endblock %}
  {% endif %}
{% endblock %}''';

void main() {
  group('inheritance', () {
    final env = Environment(
      loader: MapLoader(<String, String>{
        'layout': layout,
        'level1': level1,
        'level2': level2,
        'level3': level3,
        'level4': level4,
        'working': working,
      }),
      trimBlocks: true,
    );

    test('layout', () {
      final template = env.getTemplate('layout');
      expect(
          template.renderMap(),
          equals('|block 1 from layout|block 2 from '
              'layout|nested block 4 from layout|'));
    });

    test('level1', () {
      final template = env.getTemplate('level1');
      expect(
          template.renderMap(),
          equals('|block 1 from level1|block 2 from '
              'layout|nested block 4 from layout|'));
    });

    test('level2', () {
      final template = env.getTemplate('level2');
      expect(
          template.renderMap(),
          equals('|block 1 from level1|nested block 5 from '
              'level2|nested block 4 from layout|'));
    });

    test('level3', () {
      final template = env.getTemplate('level3');
      expect(
          template.renderMap(),
          equals('|block 1 from level1|block 5 from level3|'
              'block 4 from level3|'));
    });

    test('level4', () {
      final template = env.getTemplate('level4');
      expect(
          template.renderMap(),
          equals('|block 1 from level1|block 5 from '
              'level3|block 3 from level4|'));
    });

    test('super', () {
      final env = Environment(
        loader: MapLoader(<String, String>{
          'a': '{% block intro %}INTRO{% endblock %}|'
              'BEFORE|{% block data %}INNER{% endblock %}|AFTER',
          'b': '{% extends "a" %}{% block data %}({{ '
              'super() }}){% endblock %}',
          'c': '{% extends "b" %}{% block intro %}--{{ '
              'super() }}--{% endblock %}\n{% block data '
              '%}[{{ super() }}]{% endblock %}',
        }),
      );

      final template = env.getTemplate('c');
      expect(template.renderMap(), equals('--INTRO--|BEFORE|[(INNER)]|AFTER'));
    });

    test('working', () {
      final template = env.getTemplate('working');
      expect(template, isNotNull);
    });

    test('reuse blocks', () {
      final template = env.fromString('{{ self.foo() }}|{% block foo %}42'
          '{% endblock %}|{{ self.foo() }}');
      expect(template.renderMap(), equals('42|42|42'));
    });

    test('preserve blocks', () {
      final env = Environment(
        loader: MapLoader(<String, String>{
          'a': '{% if false %}{% block x %}A{% endblock %}'
              '{% endif %}{{ self.x() }}',
          'b': '{% extends "a" %}{% block x %}B{{ super() }}{% endblock %}',
        }),
      );

      final template = env.getTemplate('b');
      expect(template.renderMap(), equals('BA'));
    });

    test('dynamic inheritance', () {
      final env = Environment(
        loader: MapLoader(<String, String>{
          'master1': 'MASTER1{% block x %}{% endblock %}',
          'master2': 'MASTER2{% block x %}{% endblock %}',
          'child': '{% extends master %}{% block x %}CHILD{% endblock %}',
        }),
      );

      final template = env.getTemplate('child');

      for (var i in <int>[1, 2]) {
        expect(template.render(master: 'master$i'), equals('MASTER${i}CHILD'));
      }
    });

    test('multi inheritance', () {
      final env = Environment(
        loader: MapLoader(<String, String>{
          'master1': 'MASTER1{% block x %}{% endblock %}',
          'master2': 'MASTER2{% block x %}{% endblock %}',
          'child': '''{% if master %}{% extends master %}{% else %}{% extends
                'master1' %}{% endif %}{% block x %}CHILD{% endblock %}''',
        }),
      );

      final template = env.getTemplate('child');
      expect(template.render(master: 'master1'), equals('MASTER1CHILD'));
      expect(template.render(master: 'master2'), equals('MASTER2CHILD'));
      expect(template.renderMap(), equals('MASTER1CHILD'));
    });

    test('scoped block', () {
      final env = Environment(
        loader: MapLoader(<String, String>{
          'master.html': '{% for item in seq %}[{% block item scoped %}'
              '{% endblock %}]{% endfor %}',
        }),
      );

      final template =
          env.fromString('{% extends "master.html" %}{% block item %}'
              '{{ item }}{% endblock %}');
      expect(template.render(seq: range(5)), equals('[0][1][2][3][4]'));
    });

    test('super in scoped block', () {
      final env = Environment(
        loader: MapLoader(<String, String>{
          'master.html': '{% for item in seq %}[{% block item scoped %}'
              '{{ item }}{% endblock %}]{% endfor %}',
        }),
      );

      final template =
          env.fromString('{% extends "master.html" %}{% block item %}'
              '{{ super() }}|{{ item * 2 }}{% endblock %}');
      expect(
          template.render(seq: range(5)), equals('[0|0][1|2][2|4][3|6][4|8]'));
    });

    // TODO: добавить тест: scoped block after inheritance = add test ..
    // TODO: добавить тест: fixed macro scoping bug = add test ..

    test('double extends', () {
      expect(() => Template(doubleextends),
          throwsA(predicate<Object>((Object e) => e is TemplateError)));
    });
  });
}
