import { MoodTypes } from '../constants/MoodTypes';
import { Memory } from '../models/Memory';

@Component
export struct MemoryCard {
  @Prop memory: Memory = new Memory(0, 0, '', '', '', 'calm', '', 0, '');
  onOpen: () => void = () => {};

  build() {
    Row({ space: 12 }) {
      Column({ space: 5 }) {
        Text(this.memory.date).fontSize(15).fontWeight(FontWeight.Medium).fontColor($r('app.color.text_primary'))
        Text(this.memory.content.length > 0 ? this.memory.content : '一张照片').fontSize(14)
          .fontColor($r('app.color.text_secondary')).maxLines(2).textOverflow({ overflow: TextOverflow.Ellipsis })
        Text(`${this.memory.hour}:00 · ${MoodTypes.getOption(this.memory.mood).label}`).fontSize(12).fontColor($r('app.color.text_secondary'))
      }
      .alignItems(HorizontalAlign.Start).layoutWeight(1)
      if (this.memory.imageUrl.length > 0) {
        Image(this.memory.imageUrl).width(64).height(64).objectFit(ImageFit.Cover).borderRadius(12)
      } else {
        Text('●').fontSize(20).fontColor($r('app.color.primary'))
      }
    }
    .width('100%').padding(16).borderRadius(16).backgroundColor($r('app.color.surface'))
    .border({ width: 1, color: $r('app.color.outline') }).onClick(() => { this.onOpen(); })
  }
}
