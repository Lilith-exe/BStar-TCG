-- Missing tables are created automatically at BStar startup; manual provisioning is optional.
-- InnoDB is required, including the existing players table.
CREATE TABLE IF NOT EXISTS bstar_pack_openings (
    id CHAR(36) NOT NULL PRIMARY KEY,
    citizenid VARCHAR(50) NOT NULL,
    previous_id CHAR(36) NULL,
    pack_item VARCHAR(64) NOT NULL,
    pack_slot INT NOT NULL,
    pack_info LONGTEXT NOT NULL,
    pack_set VARCHAR(64) NOT NULL,
    status VARCHAR(16) NOT NULL DEFAULT 'prepared',
    rewards LONGTEXT NOT NULL,
    before_inventory LONGTEXT NOT NULL,
    after_inventory LONGTEXT NOT NULL,
    db_before_inventory LONGTEXT NOT NULL,
    review_inventory LONGTEXT NULL,
    viewed TINYINT(1) NOT NULL DEFAULT 0,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY one_successor (previous_id),
    KEY owner_recovery (citizenid, status, viewed)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Keep this ledger: copy IDs and packOpeningId/packPull identify each grant across storage.
-- 'review' rows require operator reconciliation against inventory/transfer history.
-- Never reset a review row or replay all six grants blindly. Other resources'
-- asynchronous inventory saves are outside this resource's per-player mutex.
