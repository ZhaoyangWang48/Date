@Component
export struct HourTimeline {
  @Prop selectedHour: number = 0;
  onChanged: (hour: number) => void = () => {};
  private readonly hours: number[] = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23];
  build() {
    Scroll() {
      Row({ space: 8 }) {
        ForEach(this.hours, (hour: number) => {
          Text(`${hour}点`).fontSize(14).fontColor(this.selectedHour === hour ? $r('app.color.on_primary') : $r('app.color.text_primary'))
            .width(56).height(50).textAlign(TextAlign.Center).padding({ top: 16 }).borderRadius(15)
            .backgroundColor(this.selectedHour === hour ? $r('app.color.primary') : $r('app.color.surface'))
            .border({ width: 1, color: this.selectedHour === hour ? $r('app.color.primary') : $r('app.color.outline') })
            .onClick(() => { this.onChanged(hour); })
        }, (hour: number) => hour.toString())
      }
    }.width('100%').scrollable(ScrollDirection.Horizontal).scrollBar(BarState.Off)
  }
}
