// Unit display conversion (domain/units.dart): local render-time math, the
// stored text untouched. The US-direction fixtures are lifted verbatim from
// the Southern Living blueberry-cake screenshots (Arnar, 2026-08-18) — the
// exact recipe the feature was asked to fix.

import 'package:flutter_test/flutter_test.dart';
import 'package:myrecibook/domain/units.dart';

void main() {
  group('parseUnitSystem', () {
    test('round-trips the three names and defaults corrupt to as-written', () {
      expect(parseUnitSystem('metric'), UnitSystem.metric);
      expect(parseUnitSystem('imperial'), UnitSystem.imperial);
      expect(parseUnitSystem('as_written'), UnitSystem.asWritten);
      expect(parseUnitSystem('garbage'), UnitSystem.asWritten);
      expect(parseUnitSystem(null), UnitSystem.asWritten);
      for (final s in UnitSystem.values) {
        expect(parseUnitSystem(unitSystemName(s)), s);
      }
    });
  });

  group('as-written', () {
    test('returns the text byte-identical', () {
      const line = '2 cups (about 8 1/2 oz.), plus 1 Tbsp. all-purpose flour';
      expect(convertUnits(line, UnitSystem.asWritten), line);
    });
  });

  group('US → metric, ingredient lines from the screenshot', () {
    String m(String s) => convertUnits(s, UnitSystem.metric);

    test('teaspoons and tablespoons stay as written — universal units', () {
      // Arnar, 2026-08-19: spoons are the same on both sides of the ocean;
      // "10 ml baking powder" was conversion noise.
      expect(m('2 tsp. baking powder'), '2 tsp. baking powder');
      expect(m('1/2 tsp. kosher salt'), '1/2 tsp. kosher salt');
      expect(m('1 Tbsp. all-purpose flour'), '1 Tbsp. all-purpose flour');
    });

    test('cups, with the parenthetical weight converted too', () {
      expect(m('2 cups (about 8 1/2 oz.) all-purpose flour'),
          '480 ml (about 240 g) all-purpose flour');
      expect(m('1 cup granulated sugar'), '240 ml granulated sugar');
      expect(m('1/2 cup (4 oz.) unsalted butter, softened'),
          '120 ml (115 g) unsalted butter, softened');
      expect(m('1 1/2 cups fresh blueberries (7 1/2 oz.), divided'),
          '360 ml fresh blueberries (215 g), divided');
    });

    test('pounds round to kitchen grams', () {
      expect(m('2 lb. chicken thighs'), '910 g chicken thighs');
      expect(m('3 pounds potatoes'), '1.4 kg potatoes');
    });

    test('unconvertible lines pass through untouched', () {
      expect(m('2 large eggs, at room temperature'),
          '2 large eggs, at room temperature');
      expect(m('Cooking spray'), 'Cooking spray');
      expect(m('a pinch of salt'), 'a pinch of salt');
      expect(m('1 stick butter'), '1 stick butter');
    });
  });

  group('US → metric, step prose from the screenshot', () {
    String m(String s) => convertUnits(s, UnitSystem.metric);

    test('oven temperature and pan size in one sentence', () {
      expect(
          m('Preheat oven to 350°F. Coat an 8-inch metal square baking pan '
              'with cooking spray; line using parchment paper, leaving a '
              '2-inch overhang on 2 sides.'),
          'Preheat oven to 175°C. Coat an 20 cm metal square baking pan '
          'with cooking spray; line using parchment paper, leaving a '
          '5 cm overhang on 2 sides.');
    });

    test('durations are not units and stay untouched', () {
      const step = 'until light and fluffy, 3 to 4 minutes. Add eggs, 1 at a '
          'time, beating well after each addition, about 30 seconds total.';
      expect(m(step), step);
    });

    test('quantities inside prose convert, bare numbers do not', () {
      expect(m('Toss together 1 cup of the blueberries and remaining 1 '
              'tablespoon flour in a small bowl'),
          'Toss together 240 ml of the blueberries and remaining 1 '
          'tablespoon flour in a small bowl');
    });

    test('fluid ounces, pints, quarts, gallons', () {
      expect(m('add 8 fl oz milk'), 'add 240 ml milk');
      expect(m('1 pint heavy cream'), '475 ml heavy cream');
      expect(m('2 quarts water'), '1.9 l water');
      expect(m('1 gallon stock'), '3.8 l stock');
    });

    test('unicode fractions parse', () {
      expect(m('add ½ cup sugar'), 'add 120 ml sugar');
      expect(m('add 1½ cups flour'), 'add 360 ml flour');
    });
  });

  group('metric → US', () {
    String i(String s) => convertUnits(s, UnitSystem.imperial);

    test('millilitres pick the natural US measure', () {
      expect(i('5 ml vanilla'), '1 tsp vanilla');
      expect(i('15 ml oil'), '1 tbsp oil');
      expect(i('240 ml milk'), '1 cup milk');
      expect(i('120 ml cream'), '½ cup cream');
      expect(i('1 dl cream'), '½ cup cream'); // Nordic decilitres
    });

    test('grams and kilograms', () {
      expect(i('115 g butter'), '4 oz butter');
      expect(i('1 kg potatoes'), '2¼ lb potatoes');
    });

    test('oven temperature snaps to the 25°F dial', () {
      expect(i('bake at 175°C for 45 minutes'), 'bake at 350°F for 45 minutes');
      expect(i('220°C oven'), '425°F oven');
    });

    test('centimetres', () {
      expect(i('a 20 cm springform'), 'a 8 in springform');
    });

    test('already-imperial text passes through untouched', () {
      const line = '2 cups (about 8 1/2 oz.) all-purpose flour';
      expect(i(line), line);
    });
  });
}
