package org.pantry.surplus.web;

import java.util.Map;
import org.springframework.beans.factory.annotation.Value;
import javax.sql.DataSource;
import org.springframework.http.ResponseEntity;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
public class HealthController {

    private final JdbcTemplate jdbc;
    private final String release;

    // Own template built from the pool, so no shared mutable object is kept (SpotBugs EI_EXPOSE_REP2).
    public HealthController(DataSource dataSource, @Value("${app.release}") String release) {
        this.jdbc = new JdbcTemplate(dataSource);
        this.release = release;
    }

    // Queries the database so a lost connection reports unhealthy, not just a running JVM.
    @GetMapping("/api/health")
    public ResponseEntity<Map<String, String>> health() {
        try {
            jdbc.queryForObject("select 1", Integer.class);
            return ResponseEntity.ok(Map.of("status", "ok", "release", release));
        } catch (RuntimeException ex) {
            return ResponseEntity.status(503).body(Map.of("status", "database unavailable", "release", release));
        }
    }
}
