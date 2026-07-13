package com.zhiyi.server.config;

import com.zhiyi.server.domain.*;
import com.zhiyi.server.repository.*;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.CommandLineRunner;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.transaction.annotation.Transactional;
import java.time.LocalDate;

@Configuration
public class DemoDataInitializer {
  @Bean CommandLineRunner seedDemoData(@Value("${zhiyi.demo.seed-enabled}") boolean enabled, UserRepository users, TreeHoleRepository trees, TreeMemberRepository members, MemoryRepository memories, PasswordEncoder encoder) {
    return args -> { if (enabled) seed(users, trees, members, memories, encoder); };
  }
  @Transactional void seed(UserRepository users, TreeHoleRepository trees, TreeMemberRepository members, MemoryRepository memories, PasswordEncoder encoder) {
    UserAccount zhiyi = users.findByUsername("zhiyi").orElseGet(() -> users.save(new UserAccount("zhiyi", encoder.encode("REMOVED_SECRET"), "植忆用户")));
    UserAccount xiaoman = users.findByUsername("xiaoman").orElseGet(() -> users.save(new UserAccount("xiaoman", encoder.encode("REMOVED_SECRET"), "小满")));
    TreeHoleEntity tree = trees.findByInviteCode("REMOVED_SECRET").orElseGet(() -> trees.save(new TreeHoleEntity("午后树洞", "REMOVED_SECRET", xiaoman)));
    if (members.findByTreeHoleIdAndUserId(tree.getId(), xiaoman.getId()).isEmpty()) members.save(new TreeMemberEntity(tree, xiaoman, MemberRole.OWNER));
    if (members.findByTreeHoleIdAndUserId(tree.getId(), zhiyi.getId()).isEmpty()) members.save(new TreeMemberEntity(tree, zhiyi, MemberRole.MEMBER));
    if (memories.count() == 0) { LocalDate today = LocalDate.now(); memories.save(new MemoryEntity(zhiyi, null, "清晨给绿萝浇水，发现新叶子已经舒展开了。", null, "calm", today, 8)); memories.save(new MemoryEntity(xiaoman, tree, "今天的阳光很轻，适合把没说完的话放进树洞里。", null, "calm", today, 15)); }
  }
}
