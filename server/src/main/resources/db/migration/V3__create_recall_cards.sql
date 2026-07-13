CREATE TABLE recall_cards (
  id BIGINT PRIMARY KEY AUTO_INCREMENT,
  user_id BIGINT NOT NULL,
  tree_hole_id BIGINT NULL,
  title VARCHAR(200) NOT NULL,
  summary TEXT NOT NULL,
  mood_tags VARCHAR(500),
  representative_image_url VARCHAR(500),
  time_range_start DATE NOT NULL,
  time_range_end DATE NOT NULL,
  memory_count INT NOT NULL DEFAULT 0,
  created_at DATETIME(6) NOT NULL,
  CONSTRAINT fk_recall_cards_user FOREIGN KEY (user_id) REFERENCES users(id),
  CONSTRAINT fk_recall_cards_tree FOREIGN KEY (tree_hole_id) REFERENCES tree_holes(id) ON DELETE CASCADE
);

CREATE INDEX idx_recall_cards_user_created ON recall_cards(user_id, created_at);
