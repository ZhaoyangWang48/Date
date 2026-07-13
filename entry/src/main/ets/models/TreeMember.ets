export class TreeMember {
  id: number = 0;
  treeHoleId: number = 0;
  userId: number = 0;
  nickname: string = '';
  role: string = 'MEMBER';

  constructor(id: number, treeHoleId: number, userId: number, nickname: string, role: string) {
    this.id = id;
    this.treeHoleId = treeHoleId;
    this.userId = userId;
    this.nickname = nickname;
    this.role = role;
  }
}
