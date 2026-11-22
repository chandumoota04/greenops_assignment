package org.pantry.surplus.web;

// A rule that needs more than the request itself (here: today's date), reported
// in the same per-field shape as bean validation errors.
public class FieldRejectedException extends RuntimeException {

    private final String field;

    public FieldRejectedException(String field, String message) {
        super(message);
        this.field = field;
    }

    public String field() {
        return field;
    }
}
