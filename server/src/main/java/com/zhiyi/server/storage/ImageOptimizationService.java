package com.zhiyi.server.storage;

import org.springframework.stereotype.Service;
import javax.imageio.ImageIO;
import java.awt.*;
import java.awt.image.BufferedImage;
import java.awt.image.RescaleOp;
import java.io.ByteArrayInputStream;
import java.io.ByteArrayOutputStream;
import java.io.IOException;

@Service
public class ImageOptimizationService {

  public byte[] crop(byte[] original, int x, int y, int w, int h) throws IOException {
    BufferedImage src = ImageIO.read(new ByteArrayInputStream(original));
    if (src == null) throw new IOException("无法解析图片");
    x = Math.max(0, Math.min(x, src.getWidth() - 1));
    y = Math.max(0, Math.min(y, src.getHeight() - 1));
    w = Math.min(w, src.getWidth() - x);
    h = Math.min(h, src.getHeight() - y);
    if (w <= 0 || h <= 0) return original;
    BufferedImage cropped = src.getSubimage(x, y, w, h);
    ByteArrayOutputStream out = new ByteArrayOutputStream();
    ImageIO.write(cropped, "jpg", out);
    return out.toByteArray();
  }

  public byte[] optimize(byte[] original) throws IOException {
    BufferedImage src = ImageIO.read(new ByteArrayInputStream(original));
    if (src == null) throw new IOException("无法解析图片");
    BufferedImage result = src;
    result = enhanceContrast(result);
    result = adjustBrightness(result);
    result = denoise(result);
    result = sharpen(result);
    result = enhanceVibrance(result);
    ByteArrayOutputStream out = new ByteArrayOutputStream();
    ImageIO.write(result, "jpg", out);
    return out.toByteArray();
  }

  private BufferedImage adjustBrightness(BufferedImage src) {
    float scale = 1.05f;
    float offset = 3f;
    RescaleOp op = new RescaleOp(scale, offset, null);
    return op.filter(src, null);
  }

  private BufferedImage enhanceContrast(BufferedImage src) {
    int w = src.getWidth(), h = src.getHeight();
    int[] hist = new int[256];
    for (int y = 0; y < h; y++)
      for (int x = 0; x < w; x++)
        hist[luminance(src.getRGB(x, y))]++;
    int total = w * h, pLow = 0, pHigh = 255, cum = 0;
    for (int i = 0; i < 256; i++) {
      cum += hist[i];
      if (cum < total * 0.02) pLow = i;
      if (cum < total * 0.98) pHigh = i;
    }
    if (pHigh <= pLow) return src;
    BufferedImage dst = new BufferedImage(w, h, src.getType());
    for (int y = 0; y < h; y++) {
      for (int x = 0; x < w; x++) {
        int rgb = src.getRGB(x, y);
        int r = stretch((rgb >> 16) & 0xFF, pLow, pHigh);
        int g = stretch((rgb >> 8) & 0xFF, pLow, pHigh);
        int b = stretch(rgb & 0xFF, pLow, pHigh);
        dst.setRGB(x, y, (0xFF << 24) | (r << 16) | (g << 8) | b);
      }
    }
    return dst;
  }

  private BufferedImage denoise(BufferedImage src) {
    int w = src.getWidth(), h = src.getHeight();
    BufferedImage dst = new BufferedImage(w, h, src.getType());
    int radius = 2;
    double sigmaColor = 25.0;
    for (int y = 0; y < h; y++) {
      for (int x = 0; x < w; x++) {
        double rSum = 0, gSum = 0, bSum = 0, wSum = 0;
        int cr = (src.getRGB(x, y) >> 16) & 0xFF;
        int cg = (src.getRGB(x, y) >> 8) & 0xFF;
        int cb = src.getRGB(x, y) & 0xFF;
        for (int dy = -radius; dy <= radius; dy++) {
          for (int dx = -radius; dx <= radius; dx++) {
            int nx = x + dx, ny = y + dy;
            if (nx < 0 || nx >= w || ny < 0 || ny >= h) continue;
            int nr = (src.getRGB(nx, ny) >> 16) & 0xFF;
            int ng = (src.getRGB(nx, ny) >> 8) & 0xFF;
            int nb = src.getRGB(nx, ny) & 0xFF;
            double dist = dx * dx + dy * dy;
            double colorDist = (cr - nr) * (cr - nr) + (cg - ng) * (cg - ng) + (cb - nb) * (cb - nb);
            double weight = Math.exp(-dist / (2 * 2.0)) * Math.exp(-colorDist / (2 * sigmaColor * sigmaColor));
            rSum += nr * weight; gSum += ng * weight; bSum += nb * weight; wSum += weight;
          }
        }
        int rr = clamp((int)(rSum / wSum)), rg = clamp((int)(gSum / wSum)), rb = clamp((int)(bSum / wSum));
        dst.setRGB(x, y, (0xFF << 24) | (rr << 16) | (rg << 8) | rb);
      }
    }
    return dst;
  }

  private BufferedImage sharpen(BufferedImage src) {
    float amount = 0.5f;
    int w = src.getWidth(), h = src.getHeight();
    BufferedImage blurred = gaussianBlur(src, 1.5f);
    BufferedImage dst = new BufferedImage(w, h, src.getType());
    for (int y = 0; y < h; y++) {
      for (int x = 0; x < w; x++) {
        for (int c = 0; c < 3; c++) {
          int orig = channel(src, x, y, c);
          int blur = channel(blurred, x, y, c);
          int diff = orig - blur;
          if (Math.abs(diff) < 2) setChannel(dst, x, y, c, orig);
          else setChannel(dst, x, y, c, clamp(orig + (int)(amount * diff)));
        }
      }
    }
    return dst;
  }

  private BufferedImage enhanceVibrance(BufferedImage src) {
    float strength = 0.2f;
    int w = src.getWidth(), h = src.getHeight();
    BufferedImage dst = new BufferedImage(w, h, src.getType());
    for (int y = 0; y < h; y++) {
      for (int x = 0; x < w; x++) {
        int rgb = src.getRGB(x, y);
        int r = (rgb >> 16) & 0xFF, g = (rgb >> 8) & 0xFF, b = rgb & 0xFF;
        float[] hsl = rgbToHsl(r, g, b);
        float sat = hsl[1];
        float skinProtect = skinProb(r, g, b);
        float adjusted = sat + strength * (1f - sat) * (sat < 0.4f ? 1.2f : 1f);
        adjusted = adjusted * (1f - skinProtect * 0.5f);
        hsl[1] = Math.min(1f, adjusted);
        int[] nrgb = hslToRgb(hsl[0], hsl[1], hsl[2]);
        dst.setRGB(x, y, (0xFF << 24) | (nrgb[0] << 16) | (nrgb[1] << 8) | nrgb[2]);
      }
    }
    return dst;
  }

  // --- helpers ---
  private int luminance(int rgb) { return (int)(0.299 * ((rgb >> 16) & 0xFF) + 0.587 * ((rgb >> 8) & 0xFF) + 0.114 * (rgb & 0xFF)); }
  private int stretch(int v, int low, int high) { return clamp((v - low) * 255 / (high - low)); }
  private int clamp(int v) { return Math.max(0, Math.min(255, v)); }
  private int channel(BufferedImage img, int x, int y, int c) { return (img.getRGB(x, y) >> (16 - 8 * c)) & 0xFF; }
  private void setChannel(BufferedImage img, int x, int y, int c, int v) {
    int rgb = img.getRGB(x, y);
    int mask = ~(0xFF << (16 - 8 * c));
    img.setRGB(x, y, (rgb & mask) | (clamp(v) << (16 - 8 * c)));
  }
  private BufferedImage gaussianBlur(BufferedImage src, float radius) {
    int r = (int)Math.ceil(radius);
    int w = src.getWidth(), h = src.getHeight();
    float[] kernel = new float[2 * r + 1];
    float sum = 0;
    for (int i = -r; i <= r; i++) { kernel[i + r] = (float)Math.exp(-i * i / (2 * radius * radius)); sum += kernel[i + r]; }
    for (int i = 0; i < kernel.length; i++) kernel[i] /= sum;
    BufferedImage tmp = new BufferedImage(w, h, src.getType());
    for (int y = 0; y < h; y++) for (int x = 0; x < w; x++) {
        float rs = 0, gs = 0, bs = 0;
        for (int k = -r; k <= r; k++) {
          int nx = Math.max(0, Math.min(w - 1, x + k));
          int rgb = src.getRGB(nx, y);
          rs += ((rgb >> 16) & 0xFF) * kernel[k + r];
          gs += ((rgb >> 8) & 0xFF) * kernel[k + r];
          bs += (rgb & 0xFF) * kernel[k + r];
        }
        tmp.setRGB(x, y, (0xFF << 24) | (clamp((int)rs) << 16) | (clamp((int)gs) << 8) | clamp((int)bs));
      }
    BufferedImage dst = new BufferedImage(w, h, src.getType());
    for (int x = 0; x < w; x++) for (int y = 0; y < h; y++) {
        float rs = 0, gs = 0, bs = 0;
        for (int k = -r; k <= r; k++) {
          int ny = Math.max(0, Math.min(h - 1, y + k));
          int rgb = tmp.getRGB(x, ny);
          rs += ((rgb >> 16) & 0xFF) * kernel[k + r];
          gs += ((rgb >> 8) & 0xFF) * kernel[k + r];
          bs += (rgb & 0xFF) * kernel[k + r];
        }
        dst.setRGB(x, y, (0xFF << 24) | (clamp((int)rs) << 16) | (clamp((int)gs) << 8) | clamp((int)bs));
      }
    return dst;
  }
  private float[] rgbToHsl(int r, int g, int b) {
    float rf = r / 255f, gf = g / 255f, bf = b / 255f;
    float max = Math.max(rf, Math.max(gf, bf)), min = Math.min(rf, Math.min(gf, bf));
    float l = (max + min) / 2f, s = 0, h = 0;
    if (max != min) {
      float d = max - min;
      s = l > 0.5f ? d / (2f - max - min) : d / (max + min);
      if (max == rf) h = ((gf - bf) / d + (gf < bf ? 6f : 0f)) / 6f;
      else if (max == gf) h = ((bf - rf) / d + 2f) / 6f;
      else h = ((rf - gf) / d + 4f) / 6f;
    }
    return new float[]{h, s, l};
  }
  private int[] hslToRgb(float h, float s, float l) {
    float r, g, b;
    if (s == 0) { r = g = b = l; }
    else {
      float q = l < 0.5f ? l * (1f + s) : l + s - l * s;
      float p = 2f * l - q;
      r = hueToRgb(p, q, h + 1f / 3f);
      g = hueToRgb(p, q, h);
      b = hueToRgb(p, q, h - 1f / 3f);
    }
    return new int[]{clamp(Math.round(r * 255)), clamp(Math.round(g * 255)), clamp(Math.round(b * 255))};
  }
  private float hueToRgb(float p, float q, float t) {
    if (t < 0) t += 1; if (t > 1) t -= 1;
    if (t < 1f / 6f) return p + (q - p) * 6f * t;
    if (t < 1f / 2f) return q;
    if (t < 2f / 3f) return p + (q - p) * (2f / 3f - t) * 6f;
    return p;
  }
  private float skinProb(int r, int g, int b) {
    if (r <= g || r <= b) return 0;
    float rg = (float)r / Math.max(1, g);
    if (rg < 1.1f || rg > 2.5f) return 0;
    return Math.min(1f, (rg - 1.1f) / 0.8f);
  }
}
