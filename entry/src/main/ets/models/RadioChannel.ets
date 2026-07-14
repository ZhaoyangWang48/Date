import { Memory } from './Memory';

export class RadioTheme {
  backgroundStart: string = '#172F32';
  backgroundEnd: string = '#385951';
  cardColor: string = '#243E3C';
  accentColor: string = '#DCEADF';
  accentTextColor: string = '#17362D';
  secondaryTextColor: string = '#C9DCD2';

  constructor(backgroundStart: string, backgroundEnd: string, cardColor: string,
    accentColor: string, accentTextColor: string, secondaryTextColor: string) {
    this.backgroundStart = backgroundStart;
    this.backgroundEnd = backgroundEnd;
    this.cardColor = cardColor;
    this.accentColor = accentColor;
    this.accentTextColor = accentTextColor;
    this.secondaryTextColor = secondaryTextColor;
  }
}

export class RadioChannel {
  id: string = ''; name: string = ''; icon: string = ''; description: string = '';
  theme: RadioTheme = new RadioTheme('#172F32', '#385951', '#243E3C', '#DCEADF', '#17362D', '#C9DCD2');
  filter: (memories: Memory[]) => Memory[] = (items: Memory[]) => items;
  constructor(id: string, name: string, icon: string, description: string, theme: RadioTheme,
    filter: (memories: Memory[]) => Memory[]) {
    this.id = id; this.name = name; this.icon = icon; this.description = description;
    this.theme = theme; this.filter = filter;
  }
}

export class RadioChannels {
  static readonly LIST: RadioChannel[] = [
    new RadioChannel('timeline', '时光倒流', '◁', '从最近的记忆慢慢走回过去',
      new RadioTheme('#172F32', '#385951', '#243E3C', '#DCEADF', '#17362D', '#C9DCD2'),
      (items: Memory[]) => items.slice().sort((a: Memory, b: Memory) => b.createdAt.localeCompare(a.createdAt))),
    new RadioChannel('happy', '阳光电台', '☀', '播放温暖而明亮的时刻',
      new RadioTheme('#6C552C', '#C49A52', '#7A6032', '#FFF0C9', '#4E3610', '#F6E5BE'),
      (items: Memory[]) => items.filter((m: Memory) => m.mood === 'happy' || m.mood === 'excited')),
    new RadioChannel('photo', '影像馆', '▣', '回看那些留下照片的瞬间',
      new RadioTheme('#283849', '#60788A', '#344A5D', '#E2EDF2', '#203443', '#D2E0E6'),
      (items: Memory[]) => items.filter((m: Memory) => m.imageUrl.length > 0)),
    new RadioChannel('night', '深夜树洞', '☾', '安静、思考、偶尔的低落',
      new RadioTheme('#151B2A', '#303B55', '#202A3D', '#D8E0ED', '#1A2538', '#C5CEDD'),
      (items: Memory[]) => items.filter((m: Memory) => m.mood === 'sad' || m.mood === 'tired' || m.mood === 'calm'))
  ];
  static find(id: string): RadioChannel { return RadioChannels.LIST.find((channel: RadioChannel) => channel.id === id) ?? RadioChannels.LIST[0]; }
}

export class MemoryTrack {
  memory: Memory = new Memory(0, 0, '', '', '', 'calm', '', 0, '');
  index: number = 0;
  isFavorited: boolean = false;
  constructor(memory: Memory = new Memory(0, 0, '', '', '', 'calm', '', 0, ''), index: number = 0) { this.memory = memory; this.index = index; }
  narration(): string {
    const content = this.memory.content.trim().length > 0 ? this.memory.content.trim() : '这是一张留住当时画面的影像记忆。';
    return `接下来，是 ${this.memory.date} 的一段记忆。${content}`;
  }
}
