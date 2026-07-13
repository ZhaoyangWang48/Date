export class Memory {
  id: number = 0;
  authorId: number = 0;
  authorName: string = '';
  treeHoleId: number = 0;
  content: string = '';
  imageUrl: string = '';
  mood: string = 'calm';
  date: string = '';
  hour: number = 0;
  createdAt: string = '';

  constructor(id: number, authorId: number, authorName: string, content: string, imageUrl: string,
    mood: string, date: string, hour: number, createdAt: string, treeHoleId: number = 0) {
    this.id = id;
    this.authorId = authorId;
    this.authorName = authorName;
    this.content = content;
    this.imageUrl = imageUrl;
    this.mood = mood;
    this.date = date;
    this.hour = hour;
    this.createdAt = createdAt;
    this.treeHoleId = treeHoleId;
  }
}
