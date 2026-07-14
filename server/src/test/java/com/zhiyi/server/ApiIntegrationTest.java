package com.zhiyi.server;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.BeforeEach;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.MediaType;
import org.springframework.mock.web.MockMultipartFile;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import org.springframework.test.web.servlet.MockMvc;
import java.time.Clock;
import java.time.Instant;
import java.time.LocalDateTime;
import java.time.ZoneId;
import java.util.Base64;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;
import static org.mockito.Mockito.when;

@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles("test")
class ApiIntegrationTest {
  @Autowired MockMvc mvc;
  @Autowired ObjectMapper json;
  @MockitoBean Clock clock;
  private static final Instant TEST_NOW = Instant.parse("2026-07-14T09:00:00Z");
  private static final ZoneId TEST_ZONE = ZoneId.of("Asia/Hong_Kong");

  @BeforeEach void resetClock() {
    when(clock.instant()).thenReturn(TEST_NOW);
    when(clock.getZone()).thenReturn(TEST_ZONE);
  }

  @Test void protectsTreeHoleMemoriesAndGroupsCommonDayByTree() throws Exception {
    String alice = register("alice", "Alice");
    String bob = register("bobby", "Bob");
    String outsider = register("outsider", "外部用户");
    String treeBody = mvc.perform(post("/api/tree-holes").header("Authorization", alice).contentType(MediaType.APPLICATION_JSON).content("{\"name\":\"测试树洞\"}"))
      .andExpect(status().isCreated()).andExpect(jsonPath("$.code").value(200)).andReturn().getResponse().getContentAsString();
    JsonNode tree = json.readTree(treeBody).path("data"); long treeId = tree.path("id").asLong(); String inviteCode = tree.path("inviteCode").asText();
    mvc.perform(post("/api/tree-holes/join").header("Authorization", bob).contentType(MediaType.APPLICATION_JSON).content("{\"inviteCode\":\"" + inviteCode + "\"}"))
      .andExpect(status().isOk()).andExpect(jsonPath("$.code").value(200));
    mvc.perform(post("/api/memories").header("Authorization", bob).contentType(MediaType.APPLICATION_JSON)
        .content("{\"content\":\"下午三点的共同记忆\",\"mood\":\"calm\",\"date\":\"2026-07-11\",\"hour\":15,\"treeHoleId\":" + treeId + "}"))
      .andExpect(status().isCreated()).andExpect(jsonPath("$.data.authorName").value("Bob"));
    mvc.perform(get("/api/tree-holes/{id}/common-day", treeId).param("date", "2026-07-11").header("Authorization", alice))
      .andExpect(status().isOk()).andExpect(jsonPath("$.data[0].hour").value(15));
    mvc.perform(get("/api/tree-holes/{id}/memories", treeId).header("Authorization", outsider))
      .andExpect(status().isForbidden()).andExpect(jsonPath("$.code").value(403));
  }

  @Test void rejectsDuplicateRegistrationAndUnauthenticatedCalls() throws Exception {
    register("duplicate", "重复用户");
    mvc.perform(post("/api/auth/register").contentType(MediaType.APPLICATION_JSON).content("{\"username\":\"duplicate\",\"password\":\"REMOVED_SECRET\",\"nickname\":\"重复用户\"}"))
      .andExpect(status().isConflict()).andExpect(jsonPath("$.code").value(409));
    mvc.perform(get("/api/memories")).andExpect(status().isUnauthorized()).andExpect(jsonPath("$.code").value(401));
  }

  @Test void uploadsImageCreatesMemoryAndServesImage() throws Exception {
    String token = register("uploader", "上传测试");
    byte[] png = Base64.getDecoder().decode(
      "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=");
    MockMultipartFile image = new MockMultipartFile("file", "memory.jpg", MediaType.IMAGE_JPEG_VALUE, png);

    String uploadBody = mvc.perform(multipart("/api/files/images").file(image).header("Authorization", token))
      .andExpect(status().isOk())
      .andExpect(jsonPath("$.code").value(200))
      .andExpect(jsonPath("$.data.imageUrl").value(org.hamcrest.Matchers.endsWith(".png")))
      .andReturn().getResponse().getContentAsString();
    String imageUrl = json.readTree(uploadBody).path("data").path("imageUrl").asText();

    mvc.perform(get(imageUrl))
      .andExpect(status().isOk())
      .andExpect(content().contentType(MediaType.IMAGE_PNG))
      .andExpect(content().bytes(png));

    mvc.perform(post("/api/memories").header("Authorization", token).contentType(MediaType.APPLICATION_JSON)
        .content("{\"content\":\"带照片的记忆\",\"imageUrl\":\"" + imageUrl +
          "\",\"mood\":\"calm\",\"date\":\"2026-07-13\",\"hour\":16}"))
      .andExpect(status().isCreated())
      .andExpect(jsonPath("$.code").value(200))
      .andExpect(jsonPath("$.data.imageUrl").value(imageUrl));

    mvc.perform(get("/api/memories").header("Authorization", token))
      .andExpect(status().isOk())
      .andExpect(jsonPath("$.data[0].imageUrl").value(imageUrl));
  }

  @Test void reportsUploadProtocolErrorsPrecisely() throws Exception {
    String token = register("uploaderrors", "上传错误测试");
    byte[] png = Base64.getDecoder().decode(
      "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=");

    mvc.perform(post("/api/files/images").header("Authorization", token)
        .contentType(MediaType.APPLICATION_JSON).content("{}"))
      .andExpect(status().isUnsupportedMediaType())
      .andExpect(jsonPath("$.code").value(415));

    MockMultipartFile wrongField = new MockMultipartFile("photo", "memory.png", MediaType.IMAGE_PNG_VALUE, png);
    mvc.perform(multipart("/api/files/images").file(wrongField).header("Authorization", token))
      .andExpect(status().isBadRequest())
      .andExpect(jsonPath("$.code").value(400));
  }

  @Test void protectsTimeCapsulesUntilTheirOpenTimeAndOpensAfterOneMinute() throws Exception {
    String owner = register("capsuleowner", "胶囊主人");
    String visitor = register("capsulevisitor", "访客");
    String openAt = LocalDateTime.ofInstant(TEST_NOW, TEST_ZONE).plusMinutes(1).toString();

    String body = mvc.perform(post("/api/time-capsules").header("Authorization", owner)
        .contentType(MediaType.APPLICATION_JSON)
        .content("{\"content\":\"一分钟后的我，请记得今天的勇气\",\"mood\":\"calm\",\"openAt\":\"" + openAt + "\"}"))
      .andExpect(status().isCreated())
      .andExpect(jsonPath("$.code").value(200))
      .andExpect(jsonPath("$.data.openAt").value(openAt + ":00"))
      .andReturn().getResponse().getContentAsString();
    long capsuleId = json.readTree(body).path("data").path("id").asLong();

    mvc.perform(get("/api/time-capsules").header("Authorization", owner))
      .andExpect(status().isOk()).andExpect(jsonPath("$.data[0].id").value(capsuleId));
    mvc.perform(get("/api/time-capsules/{id}", capsuleId).header("Authorization", visitor))
      .andExpect(status().isForbidden()).andExpect(jsonPath("$.code").value(403));
    mvc.perform(patch("/api/time-capsules/{id}/open", capsuleId).header("Authorization", owner))
      .andExpect(status().isConflict()).andExpect(jsonPath("$.code").value(409));

    when(clock.instant()).thenReturn(TEST_NOW.plusSeconds(61));
    mvc.perform(patch("/api/time-capsules/{id}/open", capsuleId).header("Authorization", owner))
      .andExpect(status().isOk())
      .andExpect(jsonPath("$.code").value(200))
      .andExpect(jsonPath("$.data.isOpened").value(true));
  }

  @Test void keepsDriftBottleAnonymousAndRequiresPickupBeforeResonance() throws Exception {
    String author = register("bottleauthor", "投瓶人");
    String picker = register("bottlepicker", "捞瓶人");

    String body = mvc.perform(post("/api/bottles").header("Authorization", author)
        .contentType(MediaType.APPLICATION_JSON)
        .content("{\"content\":\"今天的风很温柔，愿你也被好好拥抱。\",\"mood\":\"hopeful\"}"))
      .andExpect(status().isCreated()).andExpect(jsonPath("$.code").value(200))
      .andReturn().getResponse().getContentAsString();
    long bottleId = json.readTree(body).path("data").path("id").asLong();

    mvc.perform(post("/api/bottles/{id}/resonance", bottleId).header("Authorization", picker)
        .contentType(MediaType.APPLICATION_JSON).content("{\"mood\":\"warm\"}"))
      .andExpect(status().isForbidden()).andExpect(jsonPath("$.code").value(403));

    mvc.perform(get("/api/bottles/random").header("Authorization", picker))
      .andExpect(status().isOk())
      .andExpect(jsonPath("$.data.id").value(bottleId))
      .andExpect(jsonPath("$.data.content").value("今天的风很温柔，愿你也被好好拥抱。"));

    mvc.perform(post("/api/bottles/{id}/resonance", bottleId).header("Authorization", picker)
        .contentType(MediaType.APPLICATION_JSON).content("{\"mood\":\"warm\"}"))
      .andExpect(status().isCreated()).andExpect(jsonPath("$.code").value(200));
    mvc.perform(post("/api/bottles/{id}/resonance", bottleId).header("Authorization", picker)
        .contentType(MediaType.APPLICATION_JSON).content("{\"mood\":\"warm\"}"))
      .andExpect(status().isConflict()).andExpect(jsonPath("$.code").value(409));

    mvc.perform(get("/api/bottles/mine/resonances").header("Authorization", author))
      .andExpect(status().isOk()).andExpect(jsonPath("$.data[0].bottleId").value(bottleId));
    mvc.perform(get("/api/bottles/pickup-count").header("Authorization", picker))
      .andExpect(status().isOk()).andExpect(jsonPath("$.data.count").value(1));
  }

  private String register(String username, String nickname) throws Exception {
    String body = mvc.perform(post("/api/auth/register").contentType(MediaType.APPLICATION_JSON).content("{\"username\":\"" + username + "\",\"password\":\"REMOVED_SECRET\",\"nickname\":\"" + nickname + "\"}"))
      .andExpect(status().isOk()).andExpect(jsonPath("$.code").value(200)).andReturn().getResponse().getContentAsString();
    return "Bearer " + json.readTree(body).path("data").path("token").asText();
  }
}
