ALTER TABLE time_capsules ADD COLUMN open_at DATETIME(6) NULL;

UPDATE time_capsules
SET open_at = TIMESTAMPADD(HOUR, 9, open_date)
WHERE open_at IS NULL;

ALTER TABLE time_capsules MODIFY COLUMN open_at DATETIME(6) NOT NULL;

CREATE INDEX idx_time_capsules_author_open_at ON time_capsules(author_id, open_at);
