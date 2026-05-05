/**
 * YABA accent palette — parity with editor highlighting / Compose `YabaColor.code` / Darwin `YabaColor`.
 * Single source for canonical hex digits (no `#`) stored in Markdown `{#rrggbb}` marks.
 */
/** Alpha for editor/preview highlight wash (matches `.yaba-md-mark` / colored `{#hex}` tint). */
export const YABA_HIGHLIGHT_BACKGROUND_ALPHA = 0.28

/** Default `{#rrggbb}` when inserting `==highlight==` from the toolbar (palette yellow, code 13). */
export const YABA_DEFAULT_HIGHLIGHT_HEX_DIGITS = "ffcc00"

export const YABA_ACCENT_PALETTE = [
  { code: 1, hex: "0088ff" },
  { code: 2, hex: "ac7f5e" },
  { code: 3, hex: "00c0e8" },
  { code: 4, hex: "8e8e93" },
  { code: 5, hex: "34c759" },
  { code: 6, hex: "6155f5" },
  { code: 7, hex: "00c8b3" },
  { code: 8, hex: "ff8d28" },
  { code: 9, hex: "ff2d55" },
  { code: 10, hex: "cb30e0" },
  { code: 11, hex: "ff383c" },
  { code: 12, hex: "00c3d0" },
  { code: 13, hex: "ffcc00" },
] as const

const HEX_BY_CODE = new Map<number, string>(YABA_ACCENT_PALETTE.map((e) => [e.code, e.hex]))

/** Six lowercase hex digits, no `#`. */
export function canonicalHexDigitsForYabaCode(code: number): string | undefined {
  return HEX_BY_CODE.get(code)
}

/** Resolve palette entry from `{#rrggbb}` digits (any case). */
export function yabaAccentCodeForHexDigits(digits: string): number | undefined {
  const n = digits.trim().toLowerCase().replace(/^#/, "")
  const hit = YABA_ACCENT_PALETTE.find((e) => e.hex === n)
  return hit?.code
}
