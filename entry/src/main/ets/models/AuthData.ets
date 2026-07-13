import { User } from './User';

export class AuthData {
  token: string = '';
  user: User = new User(0, '', '');

  constructor(token: string, user: User) {
    this.token = token;
    this.user = user;
  }
}
