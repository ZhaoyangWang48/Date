export class DriftBottle {
  id: number = 0;
  content: string = '';
  mood: string = 'calm';
  throwTime: string = '';
  expireTime: string = '';
  isPickedUp: boolean = false;
  resonanceCount: number = 0;
  isExpired(): boolean { return this.expireTime.length > 0 && new Date(this.expireTime).getTime() < Date.now(); }
  remainingDays(): number { return this.expireTime.length === 0 ? 0 : Math.max(0, Math.ceil((new Date(this.expireTime).getTime() - Date.now()) / 86400000)); }
}

export class ResonanceLeaf {
  id: number = 0;
  bottleId: number = 0;
  mood: string = 'moved';
  timestamp: string = '';
  bottleContentSnippet: string = '';
}

export class ResonanceMoodOption {
  key: string = ''; label: string = ''; icon: string = ''; color: string = '';
  constructor(key: string, label: string, icon: string, color: string) { this.key = key; this.label = label; this.icon = icon; this.color = color; }
}

export class ResonanceMoodTypes {
  static readonly OPTIONS: ResonanceMoodOption[] = [
    new ResonanceMoodOption('moved', '感动', '◌', '#7D9DA6'), new ResonanceMoodOption('relatable', '同感', '◇', '#6F9D78'),
    new ResonanceMoodOption('blessed', '祝福', '✦', '#CDA560'), new ResonanceMoodOption('warm', '温暖', '◒', '#C98279'),
    new ResonanceMoodOption('miss', '想念', '☾', '#8E87A2')
  ];
  static getOption(key: string): ResonanceMoodOption { return ResonanceMoodTypes.OPTIONS.find((item: ResonanceMoodOption) => item.key === key) ?? ResonanceMoodTypes.OPTIONS[0]; }
}
