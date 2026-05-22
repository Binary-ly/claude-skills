# Color — color-mix() and Perceptually Uniform Color

Sources:
- https://developer.mozilla.org/en-US/docs/Web/CSS/color_value/color-mix
- https://developer.mozilla.org/en-US/docs/Web/CSS/color_value/oklch
- https://developer.mozilla.org/en-US/docs/Web/CSS/hue-interpolation-method

---

## Color Space Selection (MDN)

> "If colors need to be evenly spaced perceptually (such as in a gradient), the Oklab (and older Lab) color spaces are appropriate, because they are designed to be perceptually uniform. If avoiding graying out in color mixing is desired, i.e., maximizing chroma throughout the transition, the Oklch (and older LCH) color spaces work well."

And in a separate paragraph on the same page:

> "Only use sRGB if you need to match the behavior of a specific device or software that uses sRGB. The sRGB color space is neither linear-light nor perceptually uniform, and produces poorer results such as overly dark or grayish mixes."

| Use case | Recommended color space |
|---|---|
| Perceptually uniform gradients | `oklab` or `lab` |
| Avoid desaturation / "muddy middle" | `oklch` or `lch` |
| Physical light simulation | `srgb-linear` or `xyz` |
| Avoid unless forced | `srgb` — "produces poorer results such as overly dark or grayish mixes" (MDN) |

```css
/* WRONG — sRGB produces muddy, grayish midpoints per MDN */
color-mix(in srgb, #C9A84C 45%, transparent)

/* CORRECT — oklch preserves chroma throughout the transition */
color-mix(in oklch, #C9A84C 45%, transparent)
```

---

## Percentage Behavior (MDN)

> "If both `p1` and `p2` are omitted, then `p1 = p2 = 50%`. If `p1` is omitted, then `p1 = 100% - p2`. If `p2` is omitted, then `p2 = 100% - p1`. If `p1 + p2 ≠ 100%`, then `p1' = p1 / (p1 + p2)` and `p2' = p2 / (p1 + p2)`. If `p1 + p2 < 100%`, then an alpha multiplier of `p1 + p2` is applied to the resulting color."

```css
/* Both explicit */
color-mix(in oklch, gold 30%, blue 70%)

/* One omitted — auto-calculated to reach 100% */
color-mix(in oklch, gold 30%, blue)  /* blue = 70% */

/* Both omitted — each defaults to 50% */
color-mix(in oklch, gold, blue)

/* Doesn't total 100% — alpha multiplier applied */
color-mix(in oklch, gold 30%, blue 30%)  /* = 50/50 mix at 60% opacity */
```

---

## Hue Interpolation in Polar Spaces (MDN)

Applies to polar color spaces: `hsl`, `hwb`, `lch`, `oklch`.

> "With these you can optionally follow the color space name with a `<hue-interpolation-method>`. This value defaults to `shorter hue`, but can also be set to `longer hue`, `increasing hue`, or `decreasing hue`."

```css
/* shorter hue (default) — shortest path around the color wheel */
color-mix(in oklch, red, blue)

/* longer hue — longest path (rainbow-through effect) */
color-mix(in oklch longer hue, red, blue)

/* increasing hue — hue values always increase */
color-mix(in oklch increasing hue, red, blue)
```

---

## Browser Support (MDN)

> "Baseline Widely available — This feature is well established and works across many devices and browser versions. It's been available across browsers since May 2023."

No prefixes needed. Safe to use without fallback for any project targeting modern browsers.
