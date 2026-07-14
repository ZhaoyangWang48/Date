package com.zhiyi.server.api;

import com.zhiyi.server.api.Dtos.ImageOptimizeResponse;
import com.zhiyi.server.storage.FileStorageService;
import com.zhiyi.server.storage.ImageOptimizationService;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;
import java.awt.image.BufferedImage;
import java.io.*;
import javax.imageio.ImageIO;
import java.util.Map;

@RestController @RequestMapping("/api/files")
public class FileController {
  private static final Logger log = LoggerFactory.getLogger(FileController.class);
  private final FileStorageService storage;
  private final ImageOptimizationService optimizer;

  public FileController(FileStorageService storage, ImageOptimizationService optimizer) {
    this.storage = storage; this.optimizer = optimizer;
  }

  @PostMapping(value = "/images", consumes = "multipart/form-data")
  public ApiResponse<ImageOptimizeResponse> upload(@RequestPart("file") MultipartFile file,
      @RequestHeader(value = "X-Optimize", defaultValue = "false") boolean optimize,
      @RequestHeader(value = "X-Crop-X", defaultValue = "0") double cropX,
      @RequestHeader(value = "X-Crop-Y", defaultValue = "0") double cropY,
      @RequestHeader(value = "X-Crop-W", defaultValue = "0") double cropW,
      @RequestHeader(value = "X-Crop-H", defaultValue = "0") double cropH) {
    try {
      boolean cropped = cropW > 0 && cropH > 0;
      if (!optimize && !cropped) {
        String url = storage.store(file);
        return ApiResponse.ok("图片上传成功", new ImageOptimizeResponse(url, false));
      }
      byte[] bytes = file.getBytes();
      if (cropped) bytes = applyCrop(bytes, cropX, cropY, cropW, cropH);
      if (optimize) bytes = optimizer.optimize(bytes);
      String url = storage.store(bytes, file.getOriginalFilename());
      return ApiResponse.ok("图片上传成功", new ImageOptimizeResponse(url, true));
    } catch (Exception e) {
      log.error("Upload failed: {}", e.getMessage());
      return ApiResponse.ok("图片上传失败", new ImageOptimizeResponse(null, false));
    }
  }

  @PostMapping("/crop")
  public ApiResponse<ImageOptimizeResponse> crop(@RequestBody Map<String, Object> body) {
    try {
      String imageUrl = (String) body.get("imageUrl");
      double cx = toDouble(body, "cropX");
      double cy = toDouble(body, "cropY");
      double cw = toDouble(body, "cropW");
      double ch = toDouble(body, "cropH");
      log.info("Crop: {} → ({},{},{},{})", imageUrl, cx, cy, cw, ch);

      byte[] bytes = storage.read(imageUrl);
      bytes = applyCrop(bytes, cx, cy, cw, ch);
      String newUrl = storage.store(bytes, deriveName(imageUrl, "crop"));
      return ApiResponse.ok("裁剪成功", new ImageOptimizeResponse(newUrl, true));
    } catch (Exception e) {
      log.error("Crop failed: {}", e.getMessage());
      return ApiResponse.ok("裁剪失败", new ImageOptimizeResponse(null, false));
    }
  }

  @PostMapping("/enhance")
  public ApiResponse<ImageOptimizeResponse> enhance(@RequestBody Map<String, Object> body) {
    try {
      String imageUrl = (String) body.get("imageUrl");
      log.info("Enhance: {}", imageUrl);
      byte[] bytes = storage.read(imageUrl);
      bytes = optimizer.optimize(bytes);
      String newUrl = storage.store(bytes, deriveName(imageUrl, "enhanced"));
      return ApiResponse.ok("增强成功", new ImageOptimizeResponse(newUrl, true));
    } catch (Exception e) {
      log.error("Enhance failed: {}", e.getMessage());
      return ApiResponse.ok("增强失败", new ImageOptimizeResponse(null, false));
    }
  }

  private byte[] applyCrop(byte[] bytes, double cx, double cy, double cw, double ch) throws IOException {
    BufferedImage src = ImageIO.read(new ByteArrayInputStream(bytes));
    if (src == null) return bytes;
    int iw = src.getWidth(), ih = src.getHeight();
    int px = (cx <= 1 && cw <= 1) ? Math.max(0, (int)(cx * iw)) : (int)cx;
    int py = (cy <= 1 && ch <= 1) ? Math.max(0, (int)(cy * ih)) : (int)cy;
    int pw = (cw <= 1) ? Math.max(1, Math.min(iw - px, (int)(cw * iw))) : (int)cw;
    int ph = (ch <= 1) ? Math.max(1, Math.min(ih - py, (int)(ch * ih))) : (int)ch;
    log.info("Crop: %({},{},{},{})→px({},{},{},{}) img={}x{}", cx, cy, cw, ch, px, py, pw, ph, iw, ih);
    return optimizer.crop(bytes, px, py, pw, ph);
  }

  private double toDouble(Map<String, Object> body, String key) {
    Object v = body.get(key);
    if (v instanceof Number n) return n.doubleValue();
    if (v instanceof String s) return Double.parseDouble(s);
    return 0;
  }

  private String deriveName(String url, String suffix) {
    String name = url.substring(url.lastIndexOf('/') + 1);
    int dot = name.lastIndexOf('.');
    String ext = dot >= 0 ? name.substring(dot) : ".jpg";
    return name.substring(0, dot >= 0 ? dot : name.length()) + "-" + suffix + ext;
  }
}
