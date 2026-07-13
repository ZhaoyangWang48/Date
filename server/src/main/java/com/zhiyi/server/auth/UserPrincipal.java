package com.zhiyi.server.auth;

import com.zhiyi.server.domain.UserAccount;
import org.springframework.security.core.GrantedAuthority;
import org.springframework.security.core.userdetails.UserDetails;
import java.util.Collection;
import java.util.List;

public record UserPrincipal(Long id, String username, String passwordHash) implements UserDetails {
  public static UserPrincipal from(UserAccount user) { return new UserPrincipal(user.getId(), user.getUsername(), user.getPasswordHash()); }
  @Override public Collection<? extends GrantedAuthority> getAuthorities() { return List.of(); }
  @Override public String getPassword() { return passwordHash; }
  @Override public String getUsername() { return username; }
  @Override public boolean isAccountNonExpired() { return true; }
  @Override public boolean isAccountNonLocked() { return true; }
  @Override public boolean isCredentialsNonExpired() { return true; }
  @Override public boolean isEnabled() { return true; }
}
