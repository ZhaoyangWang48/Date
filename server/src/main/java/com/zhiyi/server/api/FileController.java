package com.zhiyi.server.api;

import com.zhiyi.server.api.Dtos.ImageUploadResponse;
import com.zhiyi.server.storage.FileStorageService;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

@RestController @RequestMapping("/api/files")
public class FileController {
  private final FileStorageService storage;
  public FileController(FileStorageService storage) { this.storage = storage; }
  @PostMapping(value = "/images", consumes = "multipart/form-data") public ApiResponse<ImageUploadResponse> upload(@RequestPart("file") MultipartFile file) { return ApiResponse.ok("图片上传成功", new ImageUploadResponse(storage.store(file))); }
}
