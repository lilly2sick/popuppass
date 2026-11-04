import { type RawSignal, SignalConnector, type TimeWindow } from "../signals.ts";

/**
 * Placeholder for the official Google Trends API (alpha, access by application).
 * Enabled only when GOOGLE_TRENDS_API_KEY is set; until the API shape is known it
 * returns nothing instead of guessing. We do not scrape trends.google.com.
 */
export class GoogleTrendsConnector extends SignalConnector {
  readonly id = "google_trends";

  constructor(private apiKey: string) {
    super();
  }

  fetch(_w: TimeWindow): Promise<RawSignal[]> {
    return Promise.resolve([]);
  }
}
