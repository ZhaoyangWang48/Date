export class MoodOption {
  key: string = '';
  label: string = '';
  icon: string = '';

  constructor(key: string, label: string, icon: string) {
    this.key = key;
    this.label = label;
    this.icon = icon;
  }
}

export class MoodTypes {
  static readonly OPTIONS: MoodOption[] = [
    new MoodOption('calm', '平静', '◌'),
    new MoodOption('happy', '开心', '☀'),
    new MoodOption('excited', '雀跃', '✦'),
    new MoodOption('sad', '低落', '☂'),
    new MoodOption('tired', '疲惫', '☾')
  ];

  static getOption(key: string): MoodOption {
    const option = MoodTypes.OPTIONS.find((item: MoodOption) => item.key === key);
    return option === undefined ? MoodTypes.OPTIONS[0] : option;
  }
}
