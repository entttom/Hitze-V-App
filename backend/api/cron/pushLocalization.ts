/** Language codes of the legacy `warngebiet_<GKZ>_<lang>` topics (the 25 app languages). */
export const SUPPORTED_PUSH_LANGUAGES = [
  "bg",
  "da",
  "de",
  "en",
  "et",
  "fi",
  "fr",
  "el",
  "ga",
  "it",
  "hr",
  "lv",
  "lt",
  "mt",
  "nl",
  "pl",
  "pt",
  "ro",
  "sv",
  "sk",
  "sl",
  "es",
  "cs",
  "hu",
  "tr",
] as const;

export type SupportedPushLanguage = (typeof SUPPORTED_PUSH_LANGUAGES)[number];

export const DEFAULT_PUSH_LANGUAGE: SupportedPushLanguage = "en";

export function listSupportedPushLanguages(): SupportedPushLanguage[] {
  return [...SUPPORTED_PUSH_LANGUAGES];
}

export function parseSupportedPushLanguage(value: string | null | undefined): SupportedPushLanguage | null {
  const normalized = value?.trim().toLowerCase();
  if (!normalized) {
    return null;
  }

  return (SUPPORTED_PUSH_LANGUAGES as readonly string[]).includes(normalized)
    ? (normalized as SupportedPushLanguage)
    : null;
}

export function normalizeSupportedPushLanguage(value: string | null | undefined): SupportedPushLanguage {
  return parseSupportedPushLanguage(value) ?? DEFAULT_PUSH_LANGUAGE;
}
