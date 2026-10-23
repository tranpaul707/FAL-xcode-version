# Manual simulator OCR fixtures

These PNGs are synthetic test inputs, not photographs of products, training data,
or source evidence for an additive claim. They are outside both app bundles and
are not copied into the test target. No model output is embedded in them.

- `ingredient-label.png`: 1600 × 900, high-contrast text. It is marked synthetic
  above `INGREDIENTS:`; the existing OCR cleaner discards that heading. Expected
  cleaned ingredients: `WATER, CALCIUM PROPIONATE, ASCORBIC ACID`. This is the same
  simple input used by the direct-lookup UI test, with two known supplied records.
- `no-text.png`: 1200 × 900, geometric shapes without text, for the no-text error.

After pulling, boot the chosen simulator, then import both images from the repo:

```bash
xcrun simctl addmedia 89CA5AC4-8662-4AB0-8D53-0F1B7A355A30 Tests/Fixtures/ingredient-label.png Tests/Fixtures/no-text.png
```

Rebuild/run the normal FoodAdditiveLens scheme in Xcode. Use Scan Ingredients →
Choose Photo and select the label image. Review the OCR text, then tap Identify &
Analyze Additives. Expect ascorbic acid and calcium propionate. Scroll down to the
Calcium Propionate result, find CFR Links, and open **21 CFR 184.1221**. Its link
should resolve to `https://www.ecfr.gov/current/title-21/section-184.1221`.
There is no separate CFR browser screen in the app.

In a simulator, Take Photo must open the same photo picker. Real camera capture
requires a physical device. Canceling selection should preserve the existing
input. Selecting `no-text.png` should show an error and restore editing; it should
not erase prior ingredients. Saving the successful OCR lookup should work with
the existing history flow.

Passing with these fixtures establishes a controlled image-import/OCR integration
check. Real packaging photos, lighting, rotation, and physical-camera behavior
still require separate validation; a synthetic image is not evidence of those.
