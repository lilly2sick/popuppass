// Keyword normalisation shared by every signal source.

export const SYNONYMS: Record<string, string> = {
  frogs: "frog",
  mushrooms: "mushroom",
  kitty: "cat",
  kitten: "cat",
};

export const NICHE_HINTS: Record<string, string> = {
  frog: "cottagecore",
  mushroom: "cottagecore",
  cat: "cute",
  strawberry: "cute",
  y2k: "y2k",
};

/** Lowercase, trim, collapse whitespace, then map known synonyms. */
export function normalizeKeyword(raw: string): string {
  const k = raw.toLowerCase().trim().replace(/\s+/g, " ");
  return SYNONYMS[k] ?? k;
}

export function nicheFor(keyword: string, hint?: string): string {
  return hint ?? NICHE_HINTS[keyword] ?? "general";
}

/** Stable slug used as the primary key of a published trend. */
export function trendId(keyword: string): string {
  return keyword.toLowerCase().replace(/[^a-z0-9]+/g, "-").replace(/^-|-$/g, "");
}
