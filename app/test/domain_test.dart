import 'package:flutter_test/flutter_test.dart';
import 'package:popup_pass/connectors/events/ics_codec.dart';
import 'package:popup_pass/domain/money.dart';
import 'package:popup_pass/domain/pricing_service.dart';

void main() {
  group('PricingService', () {
    const pricing = PricingService();

    test('break-even rounds up', () {
      expect(pricing.breakEven(boothFeeCents: 12000, priceCents: 700, unitCostCents: 90), 20);
    });

    test('never breaks even when price <= cost', () {
      expect(pricing.breakEven(boothFeeCents: 12000, priceCents: 500, unitCostCents: 600), -1);
    });

    test('suggestion counts maker time', () {
      final s = pricing.suggest(materialCents: 90, minutes: 3, boothFeeCents: 12000);
      expect(s.lowCents, greaterThan(90));
      expect(s.highCents, greaterThanOrEqualTo(s.lowCents));
    });
  });

  test('Money.signed always carries a sign', () {
    expect(Money.signed(21200), '+\$212');
    expect(Money.signed(-1800), '-\$18');
  });

  test('IcsCodec parses folded lines and UTC dates', () {
    const ics = 'BEGIN:VCALENDAR\r\nBEGIN:VEVENT\r\nUID:abc\r\nSUMMARY:Anime\r\n  Fest\r\n'
        'DTSTART:20261106T170000Z\r\nDTEND:20261108T020000Z\r\nEND:VEVENT\r\nEND:VCALENDAR\r\n';
    final codec = const IcsCodec();
    final events = codec.parse(ics);
    expect(events, hasLength(1));
    expect(events.first['SUMMARY'], 'Anime Fest');
    expect(codec.parseDate(events.first['DTSTART'])!.toUtc(), DateTime.utc(2026, 11, 6, 17));
  });
}
