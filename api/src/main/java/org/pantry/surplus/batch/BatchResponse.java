package org.pantry.surplus.batch;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.temporal.ChronoUnit;

public record BatchResponse(
        Long id,
        String itemName,
        BigDecimal quantity,
        Unit unit,
        LocalDate expiryDate,
        String collectionNote,
        long daysToExpiry) {

    // Worked out per request against the server date so it never goes stale in the database.
    static BatchResponse of(FoodBatch batch, LocalDate today) {
        return new BatchResponse(batch.getId(), batch.getItemName(), batch.getQuantity(), batch.getUnit(),
                batch.getExpiryDate(), batch.getCollectionNote(),
                ChronoUnit.DAYS.between(today, batch.getExpiryDate()));
    }
}
