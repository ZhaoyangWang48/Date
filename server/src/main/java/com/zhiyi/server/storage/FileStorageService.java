package com.zhiyi.server.storage;

import com.zhiyi.server.api.ApiException;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;
import java.io.BufferedInputStream;
import java.io.IOException;
import java.io.InputStream;
import java.nio.file.*;
import java.util.*;

@Service
public class FileStorageService {
  private final Path root;
  public FileStorageService(@Value("${zhiyi.storage.upload-dir}") String root) { this.root = Paths.get(root).toAbsolutePath().normalize(); }
  public String store(MultipartFile file) {
    if (file == null || file.isEmpty()) throw new ApiException(HttpStatus.BAD_REQUEST, "请选择一张图片");
    if (file.getSize() > 10 * 1024 * 1024) throw new ApiException(HttpStatus.PAYLOAD_TOO_LARGE, "图片不能超过 10MB");
    try (InputStream raw = file.getInputStream(); BufferedInputStream input = new BufferedInputStream(raw)) {
      input.mark(16);
      ImageType type = detectType(input.readNBytes(12));
      input.reset();
      if (type == null) throw new ApiException(HttpStatus.UNSUPPORTED_MEDIA_TYPE, "仅支持 JPG、PNG、WEBP 图片");
      Files.createDirectories(root);
      String name = UUID.randomUUID() + type.suffix();
      Files.copy(input, root.resolve(name), StandardCopyOption.REPLACE_EXISTING);
      return "/uploads/" + name;
    }
    catch (IOException error) { throw new ApiException(HttpStatus.INTERNAL_SERVER_ERROR, "图片保存失败"); }
  }
  public void delete(String imageUrl) {
    if (imageUrl == null || !imageUrl.startsWith("/uploads/")) return;
    Path candidate = root.resolve(imageUrl.substring("/uploads/".length())).normalize();
    try { if (candidate.startsWith(root)) Files.deleteIfExists(candidate); } catch (IOException ignored) { }
  }
  public Path root() { return root; }

  private ImageType detectType(byte[] header) {
    if (header.length >= 3 && unsigned(header[0]) == 0xFF && unsigned(header[1]) == 0xD8 && unsigned(header[2]) == 0xFF) {
      return new ImageType(".jpg");
    }
    if (header.length >= 8 && unsigned(header[0]) == 0x89 && header[1] == 0x50 && header[2] == 0x4E && header[3] == 0x47
      && header[4] == 0x0D && header[5] == 0x0A && header[6] == 0x1A && header[7] == 0x0A) {
      return new ImageType(".png");
    }
    if (header.length >= 12 && header[0] == 'R' && header[1] == 'I' && header[2] == 'F' && header[3] == 'F'
      && header[8] == 'W' && header[9] == 'E' && header[10] == 'B' && header[11] == 'P') {
      return new ImageType(".webp");
    }
    return null;
  }

  private int unsigned(byte value) { return value & 0xFF; }
  private record ImageType(String suffix) { }
}
