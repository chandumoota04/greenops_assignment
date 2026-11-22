package org.pantry.surplus.batch;

import jakarta.validation.constraints.DecimalMax;
import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.Digits;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import java.math.BigDecimal;
import java.time.LocalDate;

public record BatchRequest(
        @NotBlank(message = "Item name is required")
        @Size(min = 2, max = 80, message = "Item name must be 2 to 80 characters")
        String itemName,

        @NotNull(message = "Quantity is required")
        @DecimalMin(value = "0.01", message = "Quantity must be more than zero")
        @DecimalMax(value = "99999", message = "Quantity is too large")
        @Digits(integer = 5, fraction = 2, message = "Quantity can have at most 2 decimal places")
        BigDecimal quantity,

        @NotNull(message = "Choose a unit")
        Unit unit,

        @NotNull(message = "Expiry date is required")
        LocalDate expiryDate,

        @Size(max = 300, message = "Collection note must be at most 300 characters")
        String collectionNote) {

    // Trim text so whitespace-only input fails the checks instead of being saved.
    public BatchRequest {
        itemName = itemName == null ? null : itemName.strip();
        collectionNote = collectionNote == null || collectionNote.isBlank() ? null : collectionNote.strip();
    }
}
