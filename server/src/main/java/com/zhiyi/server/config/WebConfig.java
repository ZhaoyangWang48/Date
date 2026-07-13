package com.zhiyi.server.config;

import com.zhiyi.server.storage.FileStorageService;
import org.springframework.context.annotation.Configuration;
import org.springframework.web.servlet.config.annotation.*;

@Configuration
public class WebConfig implements WebMvcConfigurer {
  private final FileStorageService storage;
  public WebConfig(FileStorageService storage) { this.storage = storage; }
  @Override public void addResourceHandlers(ResourceHandlerRegistry registry) { registry.addResourceHandler("/uploads/**").addResourceLocations(storage.root().toUri().toString()); }
}
