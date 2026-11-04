import 'analytics_service.dart';
import 'money.dart';

/// Turns an [EventReport] into words. Free users get [RuleSummaryWriter];
/// Pro users also get an AI version through the job queue.
abstract interface class SummaryWriter {
  String write(EventReport report, {required String eventName});
}

class RuleSummaryWriter implements SummaryWriter {
  const RuleSummaryWriter();

  @override
  String write(EventReport r, {required String eventName}) {
    if (r.units == 0) return 'No sales logged at $eventName yet.';
    final parts = <String>[
      'You ${r.netCents >= 0 ? 'made' : 'lost'} ${Money.format(r.netCents.abs())} at $eventName after costs and the booth.',
    ];
    final best = r.best;
    if (best != null) parts.add('${best.name} led with ${best.units} sold and ${Money.signed(best.profitCents)} profit.');
    final worst = r.worst;
    if (worst != null && worst.profitCents < 0) {
      parts.add('${worst.name} lost ${Money.format(worst.profitCents.abs())} after materials. Raise the price or cut cost.');
    } else if (worst != null) {
      parts.add('${worst.name} moved slowest with ${worst.units} sold.');
    }
    return parts.join(' ');
  }
}
