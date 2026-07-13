package com.zhiyi.server.api;

import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.http.*;
import org.springframework.http.converter.HttpMessageNotReadableException;
import org.springframework.web.HttpMediaTypeNotSupportedException;
import org.springframework.web.bind.MethodArgumentNotValidException;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MaxUploadSizeExceededException;
import org.springframework.web.multipart.MultipartException;
import org.springframework.web.multipart.support.MissingServletRequestPartException;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

@RestControllerAdvice
public class GlobalExceptionHandler {
  private static final Logger log = LoggerFactory.getLogger(GlobalExceptionHandler.class);

  @ExceptionHandler(ApiException.class)
  ResponseEntity<ApiResponse<Void>> api(ApiException error) {
    return ResponseEntity.status(error.getStatus()).body(ApiResponse.error(error.getStatus().value(), error.getMessage()));
  }

  @ExceptionHandler(MethodArgumentNotValidException.class)
  ResponseEntity<ApiResponse<Void>> invalid(MethodArgumentNotValidException error) {
    String message = error.getBindingResult().getFieldErrors().isEmpty()
      ? "请求参数不正确"
      : error.getBindingResult().getFieldErrors().getFirst().getDefaultMessage();
    return ResponseEntity.badRequest().body(ApiResponse.error(400, message));
  }

  @ExceptionHandler(MaxUploadSizeExceededException.class)
  ResponseEntity<ApiResponse<Void>> tooLarge() {
    return ResponseEntity.status(HttpStatus.PAYLOAD_TOO_LARGE).body(ApiResponse.error(413, "图片不能超过 10MB"));
  }

  @ExceptionHandler(HttpMediaTypeNotSupportedException.class)
  ResponseEntity<ApiResponse<Void>> unsupportedMediaType() {
    return ResponseEntity.status(HttpStatus.UNSUPPORTED_MEDIA_TYPE)
      .body(ApiResponse.error(415, "请使用 multipart/form-data 上传图片"));
  }

  @ExceptionHandler(MissingServletRequestPartException.class)
  ResponseEntity<ApiResponse<Void>> missingPart() {
    return ResponseEntity.badRequest().body(ApiResponse.error(400, "上传请求缺少 file 字段"));
  }

  @ExceptionHandler(MultipartException.class)
  ResponseEntity<ApiResponse<Void>> invalidMultipart() {
    return ResponseEntity.badRequest().body(ApiResponse.error(400, "multipart 上传请求不正确"));
  }

  @ExceptionHandler(HttpMessageNotReadableException.class)
  ResponseEntity<ApiResponse<Void>> unreadableBody() {
    return ResponseEntity.badRequest().body(ApiResponse.error(400, "请求内容不正确"));
  }

  @ExceptionHandler(DataIntegrityViolationException.class)
  ResponseEntity<ApiResponse<Void>> conflict() {
    return ResponseEntity.status(HttpStatus.CONFLICT).body(ApiResponse.error(409, "数据冲突，请勿重复提交"));
  }

  @ExceptionHandler(Exception.class)
  ResponseEntity<ApiResponse<Void>> unexpected(Exception error) {
    log.error("Unhandled server error", error);
    return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(ApiResponse.error(500, "服务器处理失败"));
  }
}
