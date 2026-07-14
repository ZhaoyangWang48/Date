@Component
export struct DriftOceanCanvas {
  private settings: RenderingContextSettings = new RenderingContextSettings(true);
  private ctx: CanvasRenderingContext2D = new CanvasRenderingContext2D(this.settings);
  private timer: number = -1;
  build() {
    Canvas(this.ctx)
      .width('100%')
      .height('100%')
      .onReady(() => { this.play(); })
  }

  aboutToDisappear(): void {
    if (this.timer >= 0) clearInterval(this.timer);
    this.timer = -1;
  }

  private play(): void {
    if (this.timer >= 0) clearInterval(this.timer);
    let frame = 0;
    this.draw(0);
    this.timer = setInterval(() => {
      frame += 1;
      this.draw(frame);
      if (frame >= 180) {
        clearInterval(this.timer);
        this.timer = -1;
      }
    }, 80);
  }

  private draw(frame: number): void {
    const width = 420;
    const height = 920;
    const background = this.ctx.createLinearGradient(0, 0, 0, height);
    background.addColorStop(0, '#102F43');
    background.addColorStop(1, '#1B5664');
    this.ctx.fillStyle = background;
    this.ctx.fillRect(0, 0, width, height);

    for (let row = 0; row < 5; row += 1) {
      this.ctx.save();
      this.ctx.globalAlpha = 0.09 + row * 0.025;
      this.ctx.strokeStyle = '#C7E4E1';
      this.ctx.lineWidth = 1.1;
      this.ctx.beginPath();
      for (let x = 0; x <= width; x += 16) {
        const y = 270 + row * 105 + Math.sin((x + frame * 3 + row * 21) / 42) * (6 + row);
        if (x === 0) this.ctx.moveTo(x, y); else this.ctx.lineTo(x, y);
      }
      this.ctx.stroke();
      this.ctx.restore();
    }

    this.ctx.save();
    this.ctx.globalAlpha = 0.28;
    this.ctx.fillStyle = '#C4DED8';
    for (let index = 0; index < 12; index += 1) {
      const x = (index * 71 + frame * 1.3) % width;
      const y = 88 + (index * 97) % 610;
      this.ctx.beginPath();
      this.ctx.arc(x, y, index % 3 === 0 ? 1.5 : 0.7, 0, Math.PI * 2);
      this.ctx.fill();
    }
    this.ctx.restore();
  }
}
