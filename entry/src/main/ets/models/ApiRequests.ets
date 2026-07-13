export class LoginRequestBody {
  username: string = '';
  password: string = '';
  constructor(username: string, password: string) { this.username = username; this.password = password; }
}

export class RegisterRequestBody {
  username: string = '';
  password: string = '';
  nickname: string = '';
  constructor(username: string, password: string, nickname: string) { this.username = username; this.password = password; this.nickname = nickname; }
}

export class CreateMemoryRequestBody {
  content: string = '';
  imageUrl: string = '';
  mood: string = '';
  date: string = '';
  hour: number = 0;
  treeHoleId: number = 0;
  constructor(content: string, imageUrl: string, mood: string, date: string, hour: number, treeHoleId: number) {
    this.content = content; this.imageUrl = imageUrl; this.mood = mood; this.date = date; this.hour = hour; this.treeHoleId = treeHoleId;
  }
}

export class CreateTreeHoleRequestBody {
  name: string = '';
  constructor(name: string) { this.name = name; }
}

export class JoinTreeHoleRequestBody {
  inviteCode: string = '';
  constructor(inviteCode: string) { this.inviteCode = inviteCode; }
}
