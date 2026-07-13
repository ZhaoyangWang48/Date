CREATE TABLE memory_embeddings (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    memory_id BIGINT NOT NULL,
    embedding TEXT NOT NULL,
    embedding_model VARCHAR(100) NOT NULL,
    created_at DATETIME(6) NOT NULL,
    CONSTRAINT fk_embedding_memory FOREIGN KEY (memory_id) REFERENCES memories(id) ON DELETE CASCADE
);
CREATE UNIQUE INDEX idx_embedding_memory_model ON memory_embeddings(memory_id, embedding_model);
