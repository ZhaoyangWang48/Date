export class TimeCapsule {
  id: number = 0;
  authorId: number = 0;
  authorName: string = '';
  content: string = '';
  mood: string = 'calm';
  sealDate: string = '';
  openDate: string = '';
  openAt: string = '';
  actualOpenDate: string = '';
  isOpened: boolean = false;

  remainingMilliseconds(now: number = Date.now()): number {
    if (this.isOpened) return 0;
    if (this.openAt.length === 0 && this.openDate.length === 0) return 0;
    const target = this.openAt.length > 0 ? this.openAt : `${this.openDate}T09:00:00`;
    return new Date(target).getTime() - now;
  }
  remainingDays(now: number = Date.now()): number {
    return Math.ceil(this.remainingMilliseconds(now) / 86400000);
  }
  isReady(now: number = Date.now()): boolean {
    return !this.isOpened && (this.openAt.length > 0 || this.openDate.length > 0) && this.remainingMilliseconds(now) <= 0;
  }
  remainingText(now: number = Date.now()): string {
    if (this.isOpened) return '已开启';
    if (this.openAt.length === 0 && this.openDate.length === 0) return '开启时间未知';
    const remaining = this.remainingMilliseconds(now);
    if (remaining <= 0) return '现在可以开启';
    if (remaining < 60000) return `还有 ${Math.ceil(remaining / 1000)} 秒`;
    if (remaining < 3600000) return `还有 ${Math.ceil(remaining / 60000)} 分钟`;
    if (remaining < 86400000) return `还有 ${Math.ceil(remaining / 3600000)} 小时`;
    const days = Math.ceil(remaining / 86400000);
    if (days === 1) return '明天开启';
    if (days < 30) return `还有 ${days} 天`;
    if (days < 365) return `还有 ${Math.floor(days / 30)} 个月`;
    return `还有 ${Math.floor(days / 365)} 年`;
  }
}

export class CapsuleTimeOption {
  label: string = '';
  unit: string = 'day';
  value: number = 0;
  key: string = '';
  constructor(label: string, unit: string, value: number) {
    this.label = label; this.unit = unit; this.value = value; this.key = `${unit}-${value}`;
  }
}

export class CapsuleTimeOptions {
  static readonly OPTIONS: CapsuleTimeOption[] = [
    new CapsuleTimeOption('1 分钟后（测试）', 'minute', 1),
    new CapsuleTimeOption('1 周后', 'day', 7), new CapsuleTimeOption('1 个月后', 'day', 30),
    new CapsuleTimeOption('3 个月后', 'day', 90), new CapsuleTimeOption('1 年后', 'day', 365)
  ];
  static openAtFrom(option: CapsuleTimeOption): string {
    const target = new Date();
    if (option.unit === 'minute') target.setMinutes(target.getMinutes() + option.value);
    else target.setDate(target.getDate() + option.value);
    const date = `${target.getFullYear()}-${String(target.getMonth() + 1).padStart(2, '0')}-${String(target.getDate()).padStart(2, '0')}`;
    const time = `${String(target.getHours()).padStart(2, '0')}:${String(target.getMinutes()).padStart(2, '0')}:${String(target.getSeconds()).padStart(2, '0')}`;
    return `${date}T${time}.${String(target.getMilliseconds()).padStart(3, '0')}`;
  }
  static find(key: string): CapsuleTimeOption { return CapsuleTimeOptions.OPTIONS.find((item: CapsuleTimeOption) => item.key === key) ?? CapsuleTimeOptions.OPTIONS[1]; }
}
