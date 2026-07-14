package com.zhiyi.server.config;

import java.time.Clock;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

@Configuration
public class TimeConfig {
  @Bean Clock applicationClock() { return Clock.systemDefaultZone(); }
}
