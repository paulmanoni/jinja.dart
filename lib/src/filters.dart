import 'dart:math' show Random, pow;

import 'environment.dart';
import 'markup.dart';
import 'runtime.dart';
import 'utils.dart';

final Expando<FilterType> _filterTypes = Expando<FilterType>();

enum FilterType {
  context,
  environment,
}

extension FilterFunction on Function {
  FilterType get filterType {
    return _filterTypes[this];
  }

  set filterType(FilterType type) {
    _filterTypes[this] = type;
  }
}

typedef AttrGetter = Object Function(Object object);

AttrGetter makeAttribute(Environment environment, String attribute,
    {Object Function(Object) postprocess, Object d}) {
  final attributes = prepareAttributeParts(attribute);

  Object attributeGetter(Object item) {
    for (var part in attributes) {
      item = doAttr(environment, item, part);

      if (item is Undefined) {
        if (d != null) {
          item = d;
        }

        break;
      }
    }

    if (postprocess != null) {
      item = postprocess(item);
    }

    return item;
  }

  return attributeGetter;
}

List<String> prepareAttributeParts(String attribute) {
  return attribute.split('.');
}

final Map<String, Function> filters = <String, Function>{
  'attr': doAttr..filterType = FilterType.environment,
  'join': doJoin..filterType = FilterType.environment,
  'sum': doSum..filterType = FilterType.environment,

  'abs': doAbs,
  'batch': doBatch,
  'capitalize': doCapitalize,
  'center': doCenter,
  'count': doCount,
  'd': doDefault,
  'default': doDefault,
  'e': doEscape,
  'escape': doEscape,
  'filesizeformat': doFileSizeFormat,
  'first': doFirst,
  'float': doFloat,
  'forceescape': doForceEscape,
  'int': doInt,
  'last': doLast,
  'length': doCount,
  'list': doList,
  'lower': doLower,
  'random': doRandom,
  'string': doString,
  'trim': doTrim,
  'upper': doUpper,

  // 'dictsort': doDictSort,
  // 'format': doFormat,
  // 'groupby': doGroupBy,
  // 'indent': doIndent,
  // 'map': doMap,
  // 'max': doMax,
  // 'min': doMin,
  // 'pprint': doPPrint,
  // 'reject': doReject,
  // 'rejectattr': doRejectAttr,
  // 'replace': doReplace,
  // 'reverse': doReverse,
  // 'round': doRound,
  // 'safe': doMarkSafe,
  // 'select': doSelect,
  // 'selectattr': doSelectAttr,
  // 'slice': doSlice,
  // 'sort': doSort,
  // 'striptags': doStripTags,
  // 'title': doTitle,
  // 'tojson': doToJson,
  // 'truncate': doTruncate,
  // 'unique': doUnique,
  // 'urlencode': doURLEncode,
  // 'urlize': doURLize,
  // 'wordcount': doWordCount,
  // 'wordwrap': doWordwrap,
  // 'xmlattr': doXMLAttr,
};

num doAbs(num n) => n.abs();

Object doAttr(Environment environment, Object value, String attribute) {
  try {
    return environment.getItem(value, attribute) ??
        environment.getField(value, attribute) ??
        environment.undefined;
  } catch (_) {
    return environment.undefined;
  }
}

Iterable<List<Object>> doBatch(Iterable<Object> values, int lineCount,
    [Object fillWith]) sync* {
  var tmp = <Object>[];

  for (var item in values) {
    if (tmp.length == lineCount) {
      yield tmp;
      tmp = <Object>[];
    }

    tmp.add(item);
  }

  if (tmp.isNotEmpty) {
    if (fillWith != null) {
      tmp.addAll(List<Object>.filled(lineCount - tmp.length, fillWith));
    }

    yield tmp;
  }
}

String doCapitalize(String value) {
  return value.substring(0, 1).toUpperCase() + value.substring(1).toLowerCase();
}

String doCenter(String value, int width) {
  if (value.length >= width) {
    return value;
  }

  final padLength = (width - value.length) ~/ 2;
  final pad = ' ' * padLength;
  return pad + value + pad;
}

int doCount(Object value) {
  if (value is String) {
    return value.length;
  }

  if (value is Iterable) {
    return value.length;
  }

  if (value is Map) {
    return value.length;
  }

  return null;
}

Object doDefault(Object value, [Object d = '', bool boolean = false]) {
  if (boolean) {
    return toBool(value) ? value : d;
  }

  return value is! Undefined ? value : d;
}

Markup doEscape(Object value) {
  return value is Markup ? value : Markup.escape(value.toString());
}

// TODO: проверить: текст ошибки = check: error message
String doFileSizeFormat(Object value, [bool binary = false]) {
  final bytes =
      value is num ? value.toDouble() : double.parse(value.toString());
  final base = binary ? 1024 : 1000;

  const prefixes = <List<String>>[
    <String>['KiB', 'kB'],
    <String>['MiB', 'MB'],
    <String>['GiB', 'GB'],
    <String>['TiB', 'TB'],
    <String>['PiB', 'PB'],
    <String>['EiB', 'EB'],
    <String>['ZiB', 'ZB'],
    <String>['YiB', 'YB'],
  ];

  if (bytes == 1.0) {
    return '1 Byte';
  } else if (bytes < base) {
    final size = bytes.toStringAsFixed(1);
    return '${size.endsWith('.0') ? size.substring(0, size.length - 2) : size} Bytes';
  } else {
    final k = binary ? 0 : 1;
    num unit;

    for (var i = 0; i < prefixes.length; i++) {
      unit = pow(base, i + 2);

      if (bytes < unit) {
        return '${(base * bytes / unit).toStringAsFixed(1)} ${prefixes[i][k]}';
      }
    }

    return '${(base * bytes / unit).toStringAsFixed(1)} ${prefixes.last[k]}';
  }
}

Object doFirst(Iterable<Object> values) {
  return values.first;
}

double doFloat(Object value, [double d = 0.0]) {
  if (value is num) {
    return value.toDouble();
  }

  return double.tryParse(value.toString()) ?? d;
}

Markup doForceEscape(Object value) {
  return Markup.escape(value.toString());
}

int doInt(Object value, [int d = 0, int base = 10]) {
  if (value is num) {
    return value.toInt();
  }

  return int.tryParse(value.toString(), radix: base) ?? d;
}

String doJoin(Environment environment, Iterable<Object> values,
    [String d = '', String attribute]) {
  if (attribute != null) {
    return values.map<Object>(makeAttribute(environment, attribute)).join(d);
  }

  return values.join(d);
}

Object doLast(Iterable<Object> values) {
  return values.last;
}

List<Object> doList(Object value) {
  if (value is Iterable) {
    return value.toList();
  }

  if (value is String) {
    return value.split('');
  }

  return <Object>[value];
}

String doLower(Object value) {
  return repr(value, false).toLowerCase();
}

final Random _rnd = Random();
Object doRandom(List<Object> values) {
  final length = values.length;
  return values[_rnd.nextInt(length)];
}

String doString(Object value) {
  return repr(value, false);
}

num doSum(Environment environment, Iterable<Object> values,
    {String attribute, num start = 0}) {
  if (attribute != null) {
    values = values.map<Object>(makeAttribute(environment, attribute));
  }

  return values.cast<num>().fold<num>(start, (num s, num n) => s + n);
}

String doTrim(Object value) {
  return repr(value, false).trim();
}

String doUpper(Object value) {
  return repr(value, false).toUpperCase();
}
