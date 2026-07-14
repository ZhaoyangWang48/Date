@Component
export struct CapsuleBloomCanvas {
  @Prop mood: string = 'calm';
  onComplete: () => void = () => {};
  private readonly canvasWidth: number = 300;
  private readonly canvasHeight: number = 300;
  private settings: RenderingContextSettings = new RenderingContextSettings(true);
  private ctx: CanvasRenderingContext2D = new CanvasRenderingContext2D(this.settings);
  private timer: number = 0;

  build() {
    Canvas(this.ctx)
      .width(this.canvasWidth)
      .height(this.canvasHeight)
      .borderRadius(28)
      .onReady(() => { this.play(); })
  }

  aboutToDisappear(): void { if (this.timer > 0) clearInterval(this.timer); }

  private play(): void {
    let frame = 0;
    this.draw(0);
    this.timer = setInterval(() => {
      frame += 1;
      this.draw(Math.min(1, frame / 42));
      if (frame >= 42) { clearInterval(this.timer); this.timer = 0; this.onComplete(); }
    }, 42);
  }

  private draw(progress: number): void {
    const cx = this.canvasWidth / 2; const cy = 140; const opened = Math.max(0, Math.min(1, (progress - 0.22) / 0.72));
    this.ctx.clearRect(0, 0, this.canvasWidth, this.canvasHeight);
    const bg = this.ctx.createRadialGradient(cx, cy, 16, cx, cy, 210);
    bg.addColorStop(0, '#FFFDF7'); bg.addColorStop(1, '#EEE9DD'); this.ctx.fillStyle = bg; this.ctx.fillRect(0, 0, this.canvasWidth, this.canvasHeight);
    this.ctx.save(); this.ctx.strokeStyle = '#587D67'; this.ctx.lineWidth = 3; this.ctx.lineCap = 'round';
    this.ctx.beginPath(); this.ctx.moveTo(cx, cy + 20); this.ctx.quadraticCurveTo(cx + 8, 230, cx - 4, 286); this.ctx.stroke(); this.ctx.restore();
    for (let index = 0; index < 5; index += 1) {
      const angle = index * Math.PI * 2 / 5 - Math.PI / 2;
      const spread = opened * 40;
      this.ctx.save(); this.ctx.translate(cx, cy); this.ctx.rotate(angle);
      const tipX = Math.sin(spread / 48) * 37; const tipY = -25 - Math.cos(spread / 48) * 38;
      const grad = this.ctx.createLinearGradient(0, 0, tipX, tipY);
      grad.addColorStop(0, '#FFF6CF'); grad.addColorStop(0.5, this.color()); grad.addColorStop(1, '#B88931'); this.ctx.fillStyle = grad;
      this.ctx.beginPath(); this.ctx.moveTo(0, 0); this.ctx.bezierCurveTo(14, -12, 18 + tipX * 0.4, tipY * 0.7, tipX, tipY); this.ctx.bezierCurveTo(tipX - 18, tipY * 0.6, -14, -12, 0, 0); this.ctx.fill(); this.ctx.restore();
    }
    this.ctx.save(); this.ctx.globalAlpha = 0.35 + opened * 0.45; this.ctx.fillStyle = '#FFE09A'; this.ctx.beginPath(); this.ctx.arc(cx, cy, 11 + opened * 5, 0, Math.PI * 2); this.ctx.fill(); this.ctx.restore();
    if (progress > 0.72) {
      this.ctx.save(); this.ctx.globalAlpha = (progress - 0.72) / 0.28;
      for (let index = 0; index < 18; index += 1) { const angle = index * 0.93; const radius = 35 + (progress - 0.72) * 180; this.ctx.fillStyle = '#D8A948'; this.ctx.beginPath(); this.ctx.arc(cx + Math.cos(angle) * radius, cy + Math.sin(angle) * radius, index % 3 + 1, 0, Math.PI * 2); this.ctx.fill(); }
      this.ctx.restore();
    }
  }

  private color(): string { if (this.mood === 'sad') return '#8EAAB0'; if (this.mood === 'excited') return '#D99677'; if (this.mood === 'happy') return '#E7BE62'; return '#C9A85B'; }
}
