CREATE TABLE time_capsules (
  id BIGINT PRIMARY KEY AUTO_INCREMENT,
  author_id BIGINT NOT NULL,
  content TEXT NOT NULL,
  mood VARCHAR(30) NOT NULL,
  seal_date DATE NOT NULL,
  open_date DATE NOT NULL,
  actual_open_date DATE NULL,
  opened BOOLEAN NOT NULL DEFAULT FALSE,
  created_at DATETIME(6) NOT NULL,
  updated_at DATETIME(6) NOT NULL,
  CONSTRAINT fk_time_capsules_author FOREIGN KEY (author_id) REFERENCES users(id) ON DELETE CASCADE
);

CREATE INDEX idx_time_capsules_author_open ON time_capsules(author_id, open_date);

CREATE TABLE drift_bottles (
  id BIGINT PRIMARY KEY AUTO_INCREMENT,
  author_id BIGINT NOT NULL,
  memory_id BIGINT NULL,
  content TEXT NOT NULL,
  mood VARCHAR(30) NOT NULL,
  thrown_at DATETIME(6) NOT NULL,
  expire_at DATETIME(6) NOT NULL,
  created_at DATETIME(6) NOT NULL,
  CONSTRAINT fk_drift_bottles_author FOREIGN KEY (author_id) REFERENCES users(id) ON DELETE CASCADE,
  CONSTRAINT fk_drift_bottles_memory FOREIGN KEY (memory_id) REFERENCES memories(id) ON DELETE SET NULL
);

CREATE INDEX idx_drift_bottles_author_thrown ON drift_bottles(author_id, thrown_at);
CREATE INDEX idx_drift_bottles_expire ON drift_bottles(expire_at);

CREATE TABLE bottle_pickups (
  id BIGINT PRIMARY KEY AUTO_INCREMENT,
  bottle_id BIGINT NOT NULL,
  user_id BIGINT NOT NULL,
  picked_at DATETIME(6) NOT NULL,
  CONSTRAINT uk_bottle_pickups_bottle_user UNIQUE (bottle_id, user_id),
  CONSTRAINT fk_bottle_pickups_bottle FOREIGN KEY (bottle_id) REFERENCES drift_bottles(id) ON DELETE CASCADE,
  CONSTRAINT fk_bottle_pickups_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

CREATE INDEX idx_bottle_pickups_user_time ON bottle_pickups(user_id, picked_at);

CREATE TABLE bottle_resonances (
  id BIGINT PRIMARY KEY AUTO_INCREMENT,
  bottle_id BIGINT NOT NULL,
  responder_id BIGINT NOT NULL,
  mood VARCHAR(30) NOT NULL,
  created_at DATETIME(6) NOT NULL,
  CONSTRAINT uk_bottle_resonances_bottle_user UNIQUE (bottle_id, responder_id),
  CONSTRAINT fk_bottle_resonances_bottle FOREIGN KEY (bottle_id) REFERENCES drift_bottles(id) ON DELETE CASCADE,
  CONSTRAINT fk_bottle_resonances_responder FOREIGN KEY (responder_id) REFERENCES users(id) ON DELETE CASCADE
);

CREATE INDEX idx_bottle_resonances_bottle ON bottle_resonances(bottle_id);
