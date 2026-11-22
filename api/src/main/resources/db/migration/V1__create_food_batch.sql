CREATE TABLE food_batch (
    id              BIGSERIAL PRIMARY KEY,
    item_name       VARCHAR(80)    NOT NULL,
    quantity        NUMERIC(10, 2) NOT NULL CHECK (quantity > 0),
    unit            VARCHAR(10)    NOT NULL
        CHECK (unit IN ('kg', 'g', 'litres', 'ml', 'items', 'packs', 'boxes', 'trays')),
    expiry_date     DATE           NOT NULL,
    collection_note VARCHAR(300),
    created_at      TIMESTAMPTZ    NOT NULL DEFAULT now(),
    updated_at      TIMESTAMPTZ    NOT NULL DEFAULT now()
);

CREATE INDEX idx_food_batch_expiry ON food_batch (expiry_date);
