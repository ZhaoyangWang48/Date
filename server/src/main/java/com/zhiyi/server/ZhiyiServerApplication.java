package com.zhiyi.server;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.boot.context.properties.ConfigurationPropertiesScan;

@SpringBootApplication
@ConfigurationPropertiesScan
public class ZhiyiServerApplication {
  public static void main(String[] args) {
    SpringApplication.run(ZhiyiServerApplication.class, args);
  }
}
