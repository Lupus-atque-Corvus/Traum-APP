import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../tools/gen_widget_catalog.dart';

/// Verifies the checked-in Kotlin/Swift catalog mirrors are up to date with the
/// Dart catalog. If these fail, run: `dart run tools/gen_widget_catalog.dart`.
void main() {
  String norm(String s) => s.replaceAll('\r\n', '\n').trim();

  test('WidgetCatalog.kt ist aktuell (kein Drift)', () {
    final onDisk = File(
      'android/app/src/main/kotlin/de/traum/traum/widget/WidgetCatalog.kt',
    ).readAsStringSync();
    expect(norm(onDisk), norm(generateKotlin()),
        reason: 'dart run tools/gen_widget_catalog.dart erneut ausführen');
  });

  test('WidgetCatalog.swift ist aktuell (kein Drift)', () {
    final onDisk =
        File('ios/TraumWidgets/WidgetCatalog.swift').readAsStringSync();
    expect(norm(onDisk), norm(generateSwift()),
        reason: 'dart run tools/gen_widget_catalog.dart erneut ausführen');
  });
}
