package com.zhiyi.server.service;

import com.zhiyi.server.api.ApiException;
import com.zhiyi.server.api.Dtos;
import com.zhiyi.server.domain.*;
import com.zhiyi.server.repository.MemoryRepository;
import com.zhiyi.server.repository.RecallCardRepository;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;

@Service
@Transactional
public class RecallCardService {
  private static final Logger log = LoggerFactory.getLogger(RecallCardService.class);
  private final MemoryRepository memoryRepo;
  private final RecallCardRepository recallCardRepo;
  private final RecallSummaryAgent summaryAgent;

  public RecallCardService(MemoryRepository memoryRepo, RecallCardRepository recallCardRepo,
                           RecallSummaryAgent summaryAgent) {
    this.memoryRepo = memoryRepo;
    this.recallCardRepo = recallCardRepo;
    this.summaryAgent = summaryAgent;
  }

  public Dtos.RecallCardResponse generate(UserAccount user, Long treeHoleId) {
    // Determine the scan start time: last card's end time, or 7 days ago if no cards
    LocalDateTime lastScan = recallCardRepo
        .findFirstByUserIdAndTreeHoleIsNullOrderByCreatedAtDesc(user.getId())
        .map(card -> card.getCreatedAt())
        .orElse(LocalDateTime.now().minusDays(7));

    // Query new memories since last scan
    List<MemoryEntity> newMemories;
    if (treeHoleId == null || treeHoleId <= 0) {
      newMemories = memoryRepo.findByAuthorIdAndTreeHoleIsNullOrderByCreatedAtDesc(user.getId())
          .stream()
          .filter(m -> m.getCreatedAt().isAfter(lastScan))
          .sorted((a, b) -> a.getCreatedAt().compareTo(b.getCreatedAt()))
          .toList();
    } else {
      newMemories = memoryRepo.findByTreeHoleIdOrderByCreatedAtDesc(treeHoleId)
          .stream()
          .filter(m -> m.getCreatedAt().isAfter(lastScan))
          .sorted((a, b) -> a.getCreatedAt().compareTo(b.getCreatedAt()))
          .toList();
    }

    if (newMemories.isEmpty()) {
      return null; // signals "no new memories" to controller
    }

    // AI summarization
    RecallSummaryAgent.SummaryResult result = summaryAgent.summarize(newMemories);

    // Find representative image
    String repImageUrl = newMemories.stream()
        .filter(m -> m.getImageUrl() != null && !m.getImageUrl().isBlank())
        .findFirst()
        .map(MemoryEntity::getImageUrl)
        .orElse(null);

    // Time range
    LocalDate rangeStart = newMemories.get(0).getMemoryDate();
    LocalDate rangeEnd = newMemories.get(newMemories.size() - 1).getMemoryDate();

    // Save card
    TreeHoleEntity treeHole = treeHoleId != null && treeHoleId > 0 ? newMemories.get(0).getTreeHole() : null;
    String moodTagsStr = result.moodTags() != null ? String.join(",", result.moodTags()) : "";
    RecallCardEntity card = new RecallCardEntity(user, treeHole, result.title(), result.summary(),
        moodTagsStr, repImageUrl, rangeStart, rangeEnd, newMemories.size());
    recallCardRepo.save(card);

    log.info("Recall card generated: id={} userId={} memories={}", card.getId(), user.getId(), newMemories.size());
    return Dtos.RecallCardResponse.from(card);
  }

  public List<Dtos.RecallCardResponse> list(UserAccount user, Long treeHoleId) {
    List<RecallCardEntity> cards;
    if (treeHoleId == null || treeHoleId <= 0) {
      cards = recallCardRepo.findByUserIdAndTreeHoleIsNullOrderByCreatedAtDesc(user.getId());
    } else {
      cards = recallCardRepo.findByUserIdAndTreeHoleIdOrderByCreatedAtDesc(user.getId(), treeHoleId);
    }
    return cards.stream().map(Dtos.RecallCardResponse::from).toList();
  }

  public Dtos.RecallCardResponse detail(Long cardId) {
    RecallCardEntity card = recallCardRepo.findById(cardId)
        .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "回忆卡片不存在"));
    return Dtos.RecallCardResponse.from(card);
  }
}
