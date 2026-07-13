CREATE TABLE users (
  id BIGINT PRIMARY KEY AUTO_INCREMENT,
  username VARCHAR(64) NOT NULL,
  password_hash VARCHAR(100) NOT NULL,
  nickname VARCHAR(64) NOT NULL,
  avatar_url VARCHAR(500),
  created_at DATETIME(6) NOT NULL,
  updated_at DATETIME(6) NOT NULL,
  CONSTRAINT uk_users_username UNIQUE (username)
);

CREATE TABLE tree_holes (
  id BIGINT PRIMARY KEY AUTO_INCREMENT,
  name VARCHAR(100) NOT NULL,
  invite_code VARCHAR(20) NOT NULL,
  creator_id BIGINT NOT NULL,
  created_at DATETIME(6) NOT NULL,
  updated_at DATETIME(6) NOT NULL,
  CONSTRAINT uk_tree_holes_invite_code UNIQUE (invite_code),
  CONSTRAINT fk_tree_holes_creator FOREIGN KEY (creator_id) REFERENCES users(id)
);

CREATE TABLE tree_members (
  id BIGINT PRIMARY KEY AUTO_INCREMENT,
  tree_hole_id BIGINT NOT NULL,
  user_id BIGINT NOT NULL,
  role VARCHAR(16) NOT NULL,
  joined_at DATETIME(6) NOT NULL,
  CONSTRAINT uk_tree_members_tree_user UNIQUE (tree_hole_id, user_id),
  CONSTRAINT fk_tree_members_tree FOREIGN KEY (tree_hole_id) REFERENCES tree_holes(id) ON DELETE CASCADE,
  CONSTRAINT fk_tree_members_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

CREATE TABLE memories (
  id BIGINT PRIMARY KEY AUTO_INCREMENT,
  author_id BIGINT NOT NULL,
  tree_hole_id BIGINT NULL,
  content TEXT NOT NULL,
  image_url VARCHAR(500),
  mood VARCHAR(30) NOT NULL,
  memory_date DATE NOT NULL,
  memory_hour INT NOT NULL,
  created_at DATETIME(6) NOT NULL,
  updated_at DATETIME(6) NOT NULL,
  CONSTRAINT ck_memories_hour CHECK (memory_hour BETWEEN 0 AND 23),
  CONSTRAINT fk_memories_author FOREIGN KEY (author_id) REFERENCES users(id),
  CONSTRAINT fk_memories_tree FOREIGN KEY (tree_hole_id) REFERENCES tree_holes(id) ON DELETE CASCADE
);

CREATE INDEX idx_memories_author_created ON memories(author_id, created_at);
CREATE INDEX idx_memories_tree_date_hour ON memories(tree_hole_id, memory_date, memory_hour);
CREATE INDEX idx_tree_members_user ON tree_members(user_id);
