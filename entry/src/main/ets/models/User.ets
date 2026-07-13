export class User {
  id: number = 0;
  username: string = '';
  nickname: string = '';
  avatarUrl: string = '';

  constructor(id: number, username: string, nickname: string, avatarUrl: string = '') {
    this.id = id;
    this.username = username;
    this.nickname = nickname;
    this.avatarUrl = avatarUrl;
  }
}
