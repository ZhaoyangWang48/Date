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

export class AgentChatRequestBody {
  treeHoleId: number = 0;
  question: string = '';
  constructor(treeHoleId: number, question: string) { this.treeHoleId = treeHoleId; this.question = question; }
}
export class CreateTimeCapsuleRequestBody {
  content: string = ''; mood: string = 'calm'; openAt: string = '';
  constructor(content: string, mood: string, openAt: string) { this.content = content; this.mood = mood; this.openAt = openAt; }
}

export class ThrowBottleRequestBody {
  memoryId: number = 0; content: string = ''; mood: string = 'calm';
  constructor(memoryId: number, content: string, mood: string) { this.memoryId = memoryId; this.content = content; this.mood = mood; }
}

export class SendResonanceRequestBody {
  mood: string = 'moved';
  constructor(mood: string) { this.mood = mood; }
}

export class EmptyRequestBody { }
