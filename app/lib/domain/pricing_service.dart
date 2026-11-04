/// Price Helper math. Pure; no IO.
class PriceSuggestion {
  const PriceSuggestion({
    required this.unitCostCents,
    required this.lowCents,
    required this.highCents,
    required this.breakEvenUnits,
  });

  final int unitCostCents;
  final int lowCents;
  final int highCents;

  /// Units at the midpoint price needed to cover the booth fee.
  final int breakEvenUnits;

  int get midCents => ((lowCents + highCents) / 2).round();
}

class PricingService {
  const PricingService({this.hourlyRateCents = 1500, this.markupLow = 2.0, this.markupHigh = 2.6});

  /// Maker time counts. $15/hour is the starting point; users can change it.
  final int hourlyRateCents;
  final double markupLow;
  final double markupHigh;

  PriceSuggestion suggest({
    required int materialCents,
    required int minutes,
    required int boothFeeCents,
  }) {
    final labor = (hourlyRateCents * minutes / 60).round();
    final base = materialCents + labor;
    final low = _roundToHalfDollar((base * markupLow).round());
    final high = _roundToHalfDollar((base * markupHigh).round());
    final mid = ((low + high) / 2).round();
    return PriceSuggestion(
      unitCostCents: materialCents,
      lowCents: low,
      highCents: high,
      breakEvenUnits: breakEven(
        boothFeeCents: boothFeeCents,
        priceCents: mid,
        unitCostCents: materialCents,
      ),
    );
  }

  int breakEven({required int boothFeeCents, required int priceCents, required int unitCostCents}) {
    final margin = priceCents - unitCostCents;
    if (margin <= 0) return -1; // never breaks even
    return (boothFeeCents / margin).ceil();
  }

  int _roundToHalfDollar(int cents) => ((cents / 50).ceil()) * 50;
}
