import 'package:flutter_test/flutter_test.dart';
import 'package:popup_pass/domain/money.dart';
import 'package:popup_pass/domain/pricing_service.dart';

void main() {
  const pricing = PricingService();

  test('break-even rounds up', () {
    expect(pricing.breakEven(boothFeeCents: 12000, priceCents: 700, unitCostCents: 90), 20);
  });

  test('never breaks even when price <= cost', () {
    expect(pricing.breakEven(boothFeeCents: 12000, priceCents: 500, unitCostCents: 600), -1);
  });

  test('suggestion counts maker time and stays ordered', () {
    final s = pricing.suggest(materialCents: 90, minutes: 3, boothFeeCents: 12000);
    expect(s.lowCents, greaterThan(90));
    expect(s.highCents, greaterThanOrEqualTo(s.lowCents));
  });

  test('Money.signed always carries a sign', () {
    expect(Money.signed(21200), '+\$212');
    expect(Money.signed(-1800), '-\$18');
  });
}
