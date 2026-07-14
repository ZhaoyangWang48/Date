package com.zhiyi.server.storage;

/**
 * Tunable parameters for the 5-step image enhancement pipeline.
 * Each parameter maps to a specific step in ImageOptimizationService.
 * Defaults match the previously hardcoded values.
 */
public record EnhanceParams(
    // Step 1 — Histogram stretch: clip percentiles [0.0, 1.0]
    double contrastLowClip,
    double contrastHighClip,

    // Step 2 — Linear brightness: pixel * scale + offset
    float brightnessScale,
    float brightnessOffset,

    // Step 3 — Bilateral denoise
    int denoiseRadius,
    double denoiseSigmaColor,
    double denoiseSigmaSpace,

    // Step 4 — Unsharp mask
    float sharpenAmount,
    float sharpenBlurSigma,
    int sharpenThreshold,

    // Step 5 — HSL vibrance boost
    float vibranceStrength,
    float vibranceLowSatThreshold,
    float vibranceSkinProtectFactor
) {

  public static final EnhanceParams DEFAULT = new EnhanceParams(
      0.02, 0.98,          // contrast
      1.05f, 3f,           // brightness
      2, 25.0, 2.0,        // denoise
      0.5f, 1.5f, 2,       // sharpen
      0.2f, 0.4f, 0.5f     // vibrance
  );
}
