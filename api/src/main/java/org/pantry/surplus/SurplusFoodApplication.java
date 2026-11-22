package org.pantry.surplus;

import java.time.Clock;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.context.annotation.Bean;

@SpringBootApplication
public class SurplusFoodApplication {

    public static void main(String[] args) {
        SpringApplication.run(SurplusFoodApplication.class, args);
    }

    // The pantry works on Irish dates, so "expires today" changes at local midnight.
    @Bean
    Clock clock() {
        return Clock.system(java.time.ZoneId.of("Europe/Dublin"));
    }
}
