-- REVIEW ONLY: requires an explicit approved database backup/migration window.
-- Never executed automatically by the resource.
-- Pending/review journals must be reconciled first; this script fails closed
-- (no card movement) when any such journal or inconsistent personal owner exists.
CREATE TABLE IF NOT EXISTS bstar_personal_pile_migration (
    citizenid VARCHAR(50) NOT NULL PRIMARY KEY,
    pile_id CHAR(36) NOT NULL UNIQUE,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

START TRANSACTION;
SET @bstar_pile_migration_ready = (
    (SELECT COUNT(*) FROM bstar_pack_openings WHERE status IN ('prepared','review')) = 0
    AND (SELECT COUNT(*) FROM bstar_card_moves WHERE status IN ('prepared','review')) = 0
    AND (SELECT COUNT(*) FROM bstar_card_copies
         WHERE location='bulk' AND (citizenid='' OR container_id<>citizenid)) = 0
);

INSERT IGNORE INTO bstar_personal_pile_migration (citizenid,pile_id)
SELECT owners.citizenid,UUID()
FROM (SELECT DISTINCT citizenid FROM bstar_card_copies WHERE location='bulk') AS owners
WHERE @bstar_pile_migration_ready;

-- Each explicit character owner gets one recoverable, undelivered physical pile.
INSERT IGNORE INTO bstar_bulk_piles (id,pending_owner)
SELECT pile_id,citizenid FROM bstar_personal_pile_migration
WHERE @bstar_pile_migration_ready;

-- Move existing identities; do not insert, remove or recreate any card copy.
UPDATE bstar_card_copies c
JOIN bstar_personal_pile_migration m ON m.citizenid=c.citizenid
SET c.location='pile',c.container_id=m.pile_id,c.citizenid=''
WHERE @bstar_pile_migration_ready AND c.location='bulk' AND c.container_id=c.citizenid;

SELECT @bstar_pile_migration_ready AS preflight_passed,
       (SELECT COUNT(*) FROM bstar_card_copies WHERE location='bulk') AS personal_copies_remaining;
COMMIT;

-- Check total copy count and hashes of (id,card_id,info,entered_at) against backup.
-- On success: use /bstarpiles to deliver the migrated pile when one slot is free.
-- Repeating the migration reuses mappings and cannot duplicate card records.
