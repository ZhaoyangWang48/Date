export class TreeHole {
  id: number = 0;
  name: string = '';
  inviteCode: string = '';
  creatorId: number = 0;
  createdAt: string = '';

  constructor(id: number, name: string, inviteCode: string, creatorId: number, createdAt: string) {
    this.id = id;
    this.name = name;
    this.inviteCode = inviteCode;
    this.creatorId = creatorId;
    this.createdAt = createdAt;
  }
}
