import { MoodOption, MoodTypes } from '../constants/MoodTypes';

@Component
export struct MoodSelector {
  @Prop selectedMood: string = 'calm';
  onMoodChanged: (mood: string) => void = () => {};

  build() {
    Scroll() {
      Row({ space: 8 }) {
        ForEach(MoodTypes.OPTIONS, (option: MoodOption) => {
          Text(option.label)
            .fontSize(14)
            .fontColor(this.selectedMood === option.key ? $r('app.color.on_primary') : $r('app.color.primary'))
            .padding({ left: 14, right: 14, top: 9, bottom: 9 })
            .borderRadius(16)
            .backgroundColor(this.selectedMood === option.key ? $r('app.color.primary') : $r('app.color.primary_soft'))
            .onClick(() => { this.onMoodChanged(option.key); })
        }, (option: MoodOption) => option.key)
      }
    }
    .width('100%').scrollable(ScrollDirection.Horizontal).scrollBar(BarState.Off)
  }
}
