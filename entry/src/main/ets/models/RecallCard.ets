export class RecallCard {
  id: number = 0;
  userId: number = 0;
  treeHoleId: number = 0;
  title: string = '';
  summary: string = '';
  moodTags: string = '';
  representativeImageUrl: string = '';
  timeRangeStart: string = '';
  timeRangeEnd: string = '';
  memoryCount: number = 0;
  createdAt: string = '';

  constructor(id: number, userId: number, treeHoleId: number, title: string, summary: string,
    moodTags: string, representativeImageUrl: string, timeRangeStart: string,
    timeRangeEnd: string, memoryCount: number, createdAt: string) {
    this.id = id;
    this.userId = userId;
    this.treeHoleId = treeHoleId;
    this.title = title;
    this.summary = summary;
    this.moodTags = moodTags;
    this.representativeImageUrl = representativeImageUrl;
    this.timeRangeStart = timeRangeStart;
    this.timeRangeEnd = timeRangeEnd;
    this.memoryCount = memoryCount;
    this.createdAt = createdAt;
  }

  getMoodTagList(): string[] {
    if (this.moodTags.length === 0) return [];
    return this.moodTags.split(',');
  }
}
