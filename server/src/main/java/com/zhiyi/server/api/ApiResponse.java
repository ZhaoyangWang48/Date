package com.zhiyi.server.api;

public record ApiResponse<T>(int code, String message, T data) {
  public static <T> ApiResponse<T> ok(String message, T data) { return new ApiResponse<>(200, message, data); }
  public static ApiResponse<Void> error(int code, String message) { return new ApiResponse<>(code, message, null); }
}
