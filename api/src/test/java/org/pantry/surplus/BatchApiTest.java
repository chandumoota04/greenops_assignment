package org.pantry.surplus;

import static org.hamcrest.Matchers.hasSize;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.delete;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.put;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import java.math.BigDecimal;
import java.time.Clock;
import java.time.Instant;
import java.time.LocalDate;
import java.time.ZoneId;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.pantry.surplus.batch.BatchRequest;
import org.pantry.surplus.batch.FoodBatch;
import org.pantry.surplus.batch.FoodBatchRepository;
import org.pantry.surplus.batch.Unit;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.test.context.TestConfiguration;
import org.springframework.boot.webmvc.test.autoconfigure.AutoConfigureMockMvc;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Primary;
import org.springframework.http.MediaType;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.ResultActions;

@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles("test")
class BatchApiTest {

    // Fixed "today" so days-to-expiry assertions do not depend on when the tests run.
    @TestConfiguration
    static class FixedClock {
        @Bean
        @Primary
        Clock testClock() {
            return Clock.fixed(Instant.parse("2026-11-10T12:00:00Z"), ZoneId.of("Europe/Dublin"));
        }
    }

    @Autowired
    MockMvc mvc;

    @Autowired
    FoodBatchRepository repository;

    @BeforeEach
    void clean() {
        repository.deleteAll();
    }

    private ResultActions send(org.springframework.test.web.servlet.request.MockHttpServletRequestBuilder request,
                               String json) throws Exception {
        return mvc.perform(request.contentType(MediaType.APPLICATION_JSON).content(json));
    }

    private String batch(String name, String quantity, String unit, String expiry) {
        return """
                {"itemName":"%s","quantity":%s,"unit":"%s","expiryDate":"%s","collectionNote":"Back door, after 4pm"}
                """.formatted(name, quantity, unit, expiry);
    }

    private long create(String name, String expiry) throws Exception {
        String body = send(post("/api/batches"), batch(name, "5", "kg", expiry))
                .andExpect(status().isCreated())
                .andReturn().getResponse().getContentAsString();
        return Long.parseLong(body.replaceAll(".*\"id\":(\\d+).*", "$1"));
    }

    @Test
    void createsAndReadsBatch() throws Exception {
        long id = create("Carrots", "2026-11-13");
        mvc.perform(get("/api/batches/" + id))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.itemName").value("Carrots"))
                .andExpect(jsonPath("$.quantity").value(5.0))
                .andExpect(jsonPath("$.unit").value("kg"))
                .andExpect(jsonPath("$.daysToExpiry").value(3));
    }

    @Test
    void listsBatchesBySoonestExpiry() throws Exception {
        create("Bread", "2026-11-12");
        create("Apples", "2026-11-11");
        create("Rice", "2026-12-01");
        mvc.perform(get("/api/batches"))
                .andExpect(jsonPath("$", hasSize(3)))
                .andExpect(jsonPath("$[0].itemName").value("Apples"))
                .andExpect(jsonPath("$[2].itemName").value("Rice"));
    }

    // Expired batches can no longer be created through the API, so this one is stored directly.
    private long storeExpired(String name, String expiry) {
        FoodBatch batch = new FoodBatch();
        batch.apply(new BatchRequest(name, new BigDecimal("5"), Unit.KG, LocalDate.parse(expiry), null));
        return repository.save(batch).getId();
    }

    @Test
    void searchesByNameAndHidesExpired() throws Exception {
        storeExpired("Brown bread", "2026-11-09");
        create("White bread", "2026-11-12");
        create("Milk", "2026-11-12");
        mvc.perform(get("/api/batches").param("q", "BREAD"))
                .andExpect(jsonPath("$", hasSize(2)));
        mvc.perform(get("/api/batches").param("q", "bread").param("hideExpired", "true"))
                .andExpect(jsonPath("$", hasSize(1)))
                .andExpect(jsonPath("$[0].itemName").value("White bread"));
    }

    @Test
    void updatesBatch() throws Exception {
        long id = create("Yoghurt", "2026-11-14");
        send(put("/api/batches/" + id), batch("Yoghurt pots", "12", "items", "2026-11-15"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.unit").value("items"));
        mvc.perform(get("/api/batches/" + id))
                .andExpect(jsonPath("$.itemName").value("Yoghurt pots"))
                .andExpect(jsonPath("$.quantity").value(12.0))
                .andExpect(jsonPath("$.expiryDate").value("2026-11-15"));
    }

    @Test
    void deletesBatch() throws Exception {
        long id = create("Soup", "2026-11-20");
        mvc.perform(delete("/api/batches/" + id)).andExpect(status().isNoContent());
        mvc.perform(get("/api/batches/" + id)).andExpect(status().isNotFound());
        mvc.perform(delete("/api/batches/" + id)).andExpect(status().isNotFound());
    }

    @Test
    void rejectsMissingAndInvalidFields() throws Exception {
        send(post("/api/batches"), "{\"itemName\":\"  \",\"quantity\":0}")
                .andExpect(status().isUnprocessableContent())
                .andExpect(jsonPath("$.fields.itemName").exists())
                .andExpect(jsonPath("$.fields.quantity").value("Quantity must be more than zero"))
                .andExpect(jsonPath("$.fields.unit").value("Choose a unit"))
                .andExpect(jsonPath("$.fields.expiryDate").value("Expiry date is required"));
        send(post("/api/batches"), batch("Pasta", "-2", "kg", "2026-11-20"))
                .andExpect(status().isUnprocessableContent());
        send(post("/api/batches"), batch("Pasta", "1.555", "kg", "2026-11-20"))
                .andExpect(jsonPath("$.fields.quantity").value("Quantity can have at most 2 decimal places"));
        org.assertj.core.api.Assertions.assertThat(repository.count()).isZero();
    }

    @Test
    void rejectsPastExpiryForNewBatchesOnly() throws Exception {
        send(post("/api/batches"), batch("Soup", "4", "litres", "2026-11-09"))
                .andExpect(status().isUnprocessableContent())
                .andExpect(jsonPath("$.fields.expiryDate").value("Expiry date cannot be in the past"));
        create("Soup", "2026-11-10");
        long expired = storeExpired("Rolls", "2026-11-08");
        send(put("/api/batches/" + expired), batch("Bread rolls", "6", "items", "2026-11-08"))
                .andExpect(status().isOk());
    }

    @Test
    void rejectsUnknownUnitAndImpossibleDate() throws Exception {
        send(post("/api/batches"), batch("Beans", "3", "tonnes", "2026-11-20"))
                .andExpect(status().isUnprocessableContent());
        send(post("/api/batches"), batch("Beans", "3", "kg", "2026-02-30"))
                .andExpect(status().isUnprocessableContent());
    }

    @Test
    void returnsNotFoundForMissingOrBadId() throws Exception {
        mvc.perform(get("/api/batches/999999")).andExpect(status().isNotFound());
        mvc.perform(get("/api/batches/abc")).andExpect(status().isNotFound());
        send(put("/api/batches/999999"), batch("Tea", "1", "packs", "2027-01-01"))
                .andExpect(status().isNotFound());
    }

    @Test
    void healthReportsDatabaseAndRelease() throws Exception {
        mvc.perform(get("/api/health"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.status").value("ok"))
                .andExpect(jsonPath("$.release").value("local"));
    }
}
