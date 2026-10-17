-- Created automatically at BStar startup; also available for manual provisioning.
-- Existing tables are preserved. Legacy pile rows retain their ownership evidence.
CREATE TABLE IF NOT EXISTS bstar_bulk_piles (
    id CHAR(36) NOT NULL PRIMARY KEY,
    pending_owner VARCHAR(50) NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    KEY pending_delivery (pending_owner)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Per-copy storage overlays the existing aggregate Deck Box table; never mirror
-- these copies into bstar_deckbox_cards (that would double-count them).
CREATE TABLE IF NOT EXISTS bstar_card_copies (
    id VARCHAR(80) NOT NULL PRIMARY KEY,
    card_id VARCHAR(100) NOT NULL,
    info LONGTEXT NOT NULL,
    location VARCHAR(12) NOT NULL,
    container_id VARCHAR(100) NOT NULL,
    citizenid VARCHAR(50) NOT NULL DEFAULT '',
    entered_at BIGINT NOT NULL,
    KEY container_cards (location, container_id, citizenid, card_id),
    KEY owner_cards (citizenid, location)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Write-ahead receipts for pocket <-> Deck Box moves; legacy delivery evidence is retained.
CREATE TABLE IF NOT EXISTS bstar_card_moves (
    id CHAR(36) NOT NULL PRIMARY KEY,
    citizenid VARCHAR(50) NOT NULL,
    status VARCHAR(16) NOT NULL DEFAULT 'prepared',
    operation LONGTEXT NOT NULL,
    before_inventory LONGTEXT NOT NULL,
    after_inventory LONGTEXT NOT NULL,
    db_before_inventory LONGTEXT NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    KEY recovery (citizenid, status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Existing collection storage, for installations without its original schema.
-- Per-copy overlay rows are never mirrored into this aggregate table.
CREATE TABLE IF NOT EXISTS bstar_deckbox_cards (
    id INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    citizenid VARCHAR(50) NOT NULL,
    deck_box_id VARCHAR(100) NOT NULL,
    card_id VARCHAR(100) NOT NULL,
    amount INT NOT NULL DEFAULT 1,
    updated_at TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY unique_box_card (citizenid, deck_box_id, card_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
