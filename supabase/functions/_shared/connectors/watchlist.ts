// Day-one keyword lists maintained by the team. The curated connector emits
// these with their weights; API-backed connectors use them as the search terms.
export type WatchItem = { keyword: string; niche: string; weight: number };

export const CURATED_ITEMS: WatchItem[] = [
  { keyword: "frog", niche: "cottagecore", weight: 8 },
  { keyword: "mushroom", niche: "cottagecore", weight: 7 },
  { keyword: "strawberry milk", niche: "cute", weight: 6 },
  { keyword: "black cat", niche: "cute", weight: 6 },
];
