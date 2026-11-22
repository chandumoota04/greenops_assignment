package org.pantry.surplus.batch;

import jakarta.validation.Valid;
import java.time.Clock;
import java.time.LocalDate;
import java.util.List;
import org.pantry.surplus.web.FieldRejectedException;
import org.springframework.http.HttpStatus;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.server.ResponseStatusException;

@RestController
@RequestMapping("/api/batches")
public class BatchController {

    // A floor below any real expiry date; PostgreSQL cannot type a null date parameter here.
    private static final LocalDate ALL_DATES = LocalDate.of(1900, 1, 1);

    private final FoodBatchRepository repository;
    private final Clock clock;

    public BatchController(FoodBatchRepository repository, Clock clock) {
        this.repository = repository;
        this.clock = clock;
    }

    @GetMapping
    public List<BatchResponse> list(@RequestParam(defaultValue = "") String q,
                                    @RequestParam(defaultValue = "false") boolean hideExpired) {
        LocalDate today = LocalDate.now(clock);
        String search = q.strip();
        if (search.length() > 80) {
            throw new ResponseStatusException(HttpStatus.UNPROCESSABLE_CONTENT, "Search text is too long");
        }
        return repository.search(search, hideExpired ? today : ALL_DATES).stream()
                .map(batch -> BatchResponse.of(batch, today))
                .toList();
    }

    @GetMapping("/{id}")
    public BatchResponse get(@PathVariable long id) {
        return BatchResponse.of(find(id), LocalDate.now(clock));
    }

    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    @Transactional
    public BatchResponse create(@Valid @RequestBody BatchRequest request) {
        LocalDate today = LocalDate.now(clock);
        // New batches only: food already past its date should not be offered for
        // collection, but an existing batch that has expired can still be corrected.
        if (request.expiryDate().isBefore(today)) {
            throw new FieldRejectedException("expiryDate", "Expiry date cannot be in the past");
        }
        FoodBatch batch = new FoodBatch();
        batch.apply(request);
        return BatchResponse.of(repository.save(batch), today);
    }

    @PutMapping("/{id}")
    @Transactional
    public BatchResponse update(@PathVariable long id, @Valid @RequestBody BatchRequest request) {
        FoodBatch batch = find(id);
        batch.apply(request);
        return BatchResponse.of(repository.saveAndFlush(batch), LocalDate.now(clock));
    }

    @DeleteMapping("/{id}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    @Transactional
    public void delete(@PathVariable long id) {
        repository.delete(find(id));
    }

    private FoodBatch find(long id) {
        return repository.findById(id)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Batch not found"));
    }
}
