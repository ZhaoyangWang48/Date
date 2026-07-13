package com.zhiyi.server.domain;

import jakarta.persistence.*;
import java.time.LocalDateTime;

@Entity
@Table(name = "memory_embeddings")
public class MemoryEmbeddingEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "memory_id", nullable = false)
    private MemoryEntity memory;

    @Column(nullable = false, columnDefinition = "TEXT")
    private String embedding;

    @Column(name = "embedding_model", nullable = false, length = 100)
    private String embeddingModel;

    @Column(name = "created_at", nullable = false)
    private LocalDateTime createdAt;

    protected MemoryEmbeddingEntity() {}

    public MemoryEmbeddingEntity(MemoryEntity memory, String embedding, String embeddingModel) {
        this.memory = memory;
        this.embedding = embedding;
        this.embeddingModel = embeddingModel;
    }

    @PrePersist
    private void onCreate() {
        this.createdAt = LocalDateTime.now();
    }

    public Long getId() { return id; }
    public MemoryEntity getMemory() { return memory; }
    public String getEmbedding() { return embedding; }
    public String getEmbeddingModel() { return embeddingModel; }
    public LocalDateTime getCreatedAt() { return createdAt; }
}
