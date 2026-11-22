package org.pantry.surplus.batch;

import jakarta.persistence.AttributeConverter;
import jakarta.persistence.Converter;

// Stores the readable label ("kg") so the database check constraint matches what users see.
@Converter(autoApply = true)
public class UnitConverter implements AttributeConverter<Unit, String> {

    @Override
    public String convertToDatabaseColumn(Unit unit) {
        return unit == null ? null : unit.label();
    }

    @Override
    public Unit convertToEntityAttribute(String label) {
        return label == null ? null : Unit.fromLabel(label);
    }
}
