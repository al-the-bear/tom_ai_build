import 'package:test/test.dart';
import 'package:tom_doc_specs/src/schema/schema_expander.dart';

void main() {
  group('SchemaExpander', () {
    group('generators (with separator)', () {
      test('expands simple list key', () {
        final expander = SchemaExpander({
          'colors': ['red', 'green', 'blue'],
        });
        final result = expander.expand({
          'value': '[[colors;, ]]',
        });
        expect(result['value'], 'red, green, blue');
      });

      test('expands key:field from list of maps', () {
        final expander = SchemaExpander({
          'endpoints': [
            {'name': 'users', 'method': 'GET'},
            {'name': 'orders', 'method': 'POST'},
          ],
        });
        final result = expander.expand({
          'value': '[[endpoints:name;, ]]',
        });
        expect(result['value'], 'users, orders');
      });

      test('expands with filter', () {
        final expander = SchemaExpander({
          'items': [
            {'name': 'a', 'status': 'active'},
            {'name': 'b', 'status': 'inactive'},
            {'name': 'c', 'status': 'active'},
          ],
        });
        final result = expander.expand({
          'value': '[[items:name?status=active;, ]]',
        });
        expect(result['value'], 'a, c');
      });

      test('expands with uppercase transform', () {
        final expander = SchemaExpander({
          'tags': ['alpha', 'beta'],
        });
        final result = expander.expand({
          'value': '[[tags|uppercase;-]]',
        });
        expect(result['value'], 'ALPHA-BETA');
      });

      test('returns original for unknown key', () {
        final expander = SchemaExpander({});
        final result = expander.expand({
          'value': '[[unknown;, ]]',
        });
        expect(result['value'], '[[unknown;, ]]');
      });
    });

    group('placeholders (without separator)', () {
      test('expands key.field', () {
        final expander = SchemaExpander({
          'config': {'name': 'test', 'version': '1.0'},
        });
        final result = expander.expand({
          'value': '[[config.name]]',
        });
        expect(result['value'], 'test');
      });

      test('expands key.index.field', () {
        final expander = SchemaExpander({
          'items': [
            {'name': 'first'},
            {'name': 'second'},
          ],
        });
        final result = expander.expand({
          'value': '[[items.0.name]]',
        });
        expect(result['value'], 'first');
      });

      test('expands key.length for list', () {
        final expander = SchemaExpander({
          'items': [1, 2, 3],
        });
        final result = expander.expand({
          'value': '[[items.length]]',
        });
        expect(result['value'], '3');
      });

      test('returns default value with |default', () {
        final expander = SchemaExpander({});
        final result = expander.expand({
          'value': '[[missing.field|N/A]]',
        });
        expect(result['value'], 'N/A');
      });

      test('returns original for missing key without default', () {
        final expander = SchemaExpander({});
        final result = expander.expand({
          'value': '[[missing.field]]',
        });
        expect(result['value'], '[[missing.field]]');
      });
    });

    group('reserved keys', () {
      test('ignores reserved keys as data sources', () {
        final expander = SchemaExpander({
          'section-types': {'req': {}},
          'colors': ['red'],
        });
        final result = expander.expand({
          'value': '[[colors;, ]]',
        });
        expect(result['value'], 'red');
      });
    });

    group('escaping', () {
      test('handles escaped brackets', () {
        final expander = SchemaExpander({
          'items': ['a'],
        });
        final result = expander.expand({
          'value': r'Use \[\[items;, ]] for expansion',
        });
        expect(result['value'], 'Use [[items;, ]] for expansion');
      });
    });

    group('recursive expansion', () {
      test('expands in nested maps', () {
        final expander = SchemaExpander({
          'tags': ['a', 'b'],
        });
        final result = expander.expand({
          'outer': {
            'inner': '[[tags;, ]]',
          },
        });
        expect(
          (result['outer'] as Map<String, dynamic>)['inner'],
          'a, b',
        );
      });

      test('expands in lists', () {
        final expander = SchemaExpander({
          'items': ['x', 'y'],
        });
        final result = expander.expand({
          'list': ['[[items;-]]', 'static'],
        });
        expect(result['list'], ['x-y', 'static']);
      });
    });

    group('nested fields', () {
      test('extracts nested field from list entries', () {
        final expander = SchemaExpander({
          'components': [
            {
              'name': 'widget',
              'config': {'color': 'red'},
            },
            {
              'name': 'button',
              'config': {'color': 'blue'},
            },
          ],
        });
        final result = expander.expand({
          'value': '[[components:config.color;, ]]',
        });
        expect(result['value'], 'red, blue');
      });
    });
  });
}
