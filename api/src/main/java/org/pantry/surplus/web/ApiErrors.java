package org.pantry.surplus.web;

import java.util.LinkedHashMap;
import java.util.Map;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.http.converter.HttpMessageNotReadableException;
import org.springframework.web.bind.MethodArgumentNotValidException;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;
import org.springframework.web.method.annotation.MethodArgumentTypeMismatchException;
import org.springframework.web.server.ResponseStatusException;

// One error shape for the frontend: a message plus, for validation, one message per field.
@RestControllerAdvice
public class ApiErrors {

    @ExceptionHandler(MethodArgumentNotValidException.class)
    ResponseEntity<Map<String, Object>> invalid(MethodArgumentNotValidException ex) {
        Map<String, String> fields = new LinkedHashMap<>();
        ex.getBindingResult().getFieldErrors()
                .forEach(error -> fields.putIfAbsent(error.getField(), error.getDefaultMessage()));
        return body(HttpStatus.UNPROCESSABLE_CONTENT, "Some fields need attention", fields);
    }

    @ExceptionHandler(FieldRejectedException.class)
    ResponseEntity<Map<String, Object>> rejected(FieldRejectedException ex) {
        return body(HttpStatus.UNPROCESSABLE_CONTENT, "Some fields need attention", Map.of(ex.field(), ex.getMessage()));
    }

    // Malformed JSON, an unknown unit or an impossible date such as 2026-02-30 end up here.
    @ExceptionHandler(HttpMessageNotReadableException.class)
    ResponseEntity<Map<String, Object>> unreadable(HttpMessageNotReadableException ex) {
        return body(HttpStatus.UNPROCESSABLE_CONTENT, "Check the quantity, unit and date values", Map.of());
    }

    @ExceptionHandler(MethodArgumentTypeMismatchException.class)
    ResponseEntity<Map<String, Object>> badParameter(MethodArgumentTypeMismatchException ex) {
        return body(HttpStatus.NOT_FOUND, "Batch not found", Map.of());
    }

    @ExceptionHandler(ResponseStatusException.class)
    ResponseEntity<Map<String, Object>> status(ResponseStatusException ex) {
        return body(HttpStatus.valueOf(ex.getStatusCode().value()), ex.getReason(), Map.of());
    }

    private ResponseEntity<Map<String, Object>> body(HttpStatus status, String message, Map<String, String> fields) {
        Map<String, Object> body = new LinkedHashMap<>();
        body.put("message", message);
        body.put("fields", fields);
        return ResponseEntity.status(status).body(body);
    }
}
