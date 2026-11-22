package org.pantry.surplus.batch;

import com.fasterxml.jackson.annotation.JsonCreator;
import com.fasterxml.jackson.annotation.JsonValue;

public enum Unit {
    KG("kg"), G("g"), LITRES("litres"), ML("ml"), ITEMS("items"), PACKS("packs"), BOXES("boxes"), TRAYS("trays");

    private final String label;

    Unit(String label) {
        this.label = label;
    }

    @JsonValue
    public String label() {
        return label;
    }

    @JsonCreator
    public static Unit fromLabel(String value) {
        for (Unit unit : values()) {
            if (unit.label.equals(value)) {
                return unit;
            }
        }
        throw new IllegalArgumentException("Unknown unit: " + value);
    }
}
