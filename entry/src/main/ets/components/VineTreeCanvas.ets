import { Memory } from '../models/Memory';
import { TreeGrowthEngine, TreeGrowthSnapshot } from '../viewmodels/TreeGrowthEngine';

@Component
export struct VineTreeCanvas {
  @Prop memories: Memory[] = [];
  @Prop seed: number = 1;
  onLeafSelected: (memoryId: number) => void = () => {};
  private settings: RenderingContextSettings = new RenderingContextSettings(true);
  private context: CanvasRenderingContext2D = new CanvasRenderingContext2D(this.settings);
  private snapshot: TreeGrowthSnapshot = new TreeGrowthSnapshot();
  private growthTimer: number = 0;

  build() {
    Canvas(this.context)
      .width(TreeGrowthEngine.WIDTH)
      .height(TreeGrowthEngine.HEIGHT)
      .borderRadius(20)
      .onReady(() => { this.playGrowth(); })
      .onClick((event: ClickEvent) => {
        const memoryId = TreeGrowthEngine.hitTest(this.snapshot.leaves, event.x, event.y);
        if (memoryId > 0) this.onLeafSelected(memoryId);
      })
  }

  aboutToDisappear(): void {
    if (this.growthTimer > 0) clearInterval(this.growthTimer);
  }

  private playGrowth(): void {
    this.snapshot = TreeGrowthEngine.create(this.memories, this.seed);
    let frame = 0;
    this.drawTree(0);
    this.growthTimer = setInterval(() => {
      frame += 1;
      this.drawTree(Math.min(1, frame / 18));
      if (frame >= 18) {
        clearInterval(this.growthTimer);
        this.growthTimer = 0;
      }
    }, 38);
  }

  private drawTree(progress: number = 1): void {
    this.context.clearRect(0, 0, TreeGrowthEngine.WIDTH, TreeGrowthEngine.HEIGHT);
    this.drawBackground();
    this.drawRootAndBranches(progress);
    if (this.snapshot.leaves.length === 0) {
      this.drawSeedling();
    } else {
      this.drawLeaves(progress);
    }
  }

  private drawBackground(): void {
    const background = this.context.createLinearGradient(0, 0, TreeGrowthEngine.WIDTH, TreeGrowthEngine.HEIGHT);
    background.addColorStop(0, '#F9FBFC');
    background.addColorStop(0.55, '#EEF5F3');
    background.addColorStop(1, '#FFFFFF');
    this.context.fillStyle = background;
    this.context.fillRect(0, 0, TreeGrowthEngine.WIDTH, TreeGrowthEngine.HEIGHT);
    this.context.globalAlpha = 0.24;
    this.context.fillStyle = '#CDE4DD';
    this.context.beginPath(); this.context.arc(52, 68, 82, 0, Math.PI * 2); this.context.fill();
    this.context.globalAlpha = 0.14;
    this.context.fillStyle = '#B8D4E1';
    this.context.beginPath(); this.context.arc(286, 128, 92, 0, Math.PI * 2); this.context.fill();
    this.context.globalAlpha = 0.3;
    this.context.fillStyle = '#D6E7E2';
    for (let index = 0; index < 22; index += 1) {
      const x = 18 + (index * 47) % 292;
      const y = 24 + (index * 71) % 250;
      this.context.beginPath(); this.context.arc(x, y, index % 3 === 0 ? 1.6 : 0.8, 0, Math.PI * 2); this.context.fill();
    }
    this.context.globalAlpha = 1;
    this.context.strokeStyle = '#E5E5EA'; this.context.lineWidth = 1;
    this.context.strokeRect(0.5, 0.5, TreeGrowthEngine.WIDTH - 1, TreeGrowthEngine.HEIGHT - 1);
  }

  private drawRootAndBranches(progress: number): void {
    const branches = this.snapshot.branches;
    this.drawRootBed();
    for (let index = 1; index < branches.length; index += 1) {
      if (index / branches.length > progress) continue;
      const branch = branches[index]; const parent = branches[branch.parentId];
      this.context.save();
      this.context.globalAlpha = Math.max(0.25, 0.86 - branch.depth * 0.055);
      this.context.strokeStyle = '#B7D8CC'; this.context.lineCap = 'round'; this.context.lineWidth = branch.width + 2.1;
      this.context.beginPath(); this.context.moveTo(parent.x, parent.y);
      this.context.quadraticCurveTo((parent.x + branch.x) / 2 + (branch.y - parent.y) * 0.12, (parent.y + branch.y) / 2, branch.x, branch.y);
      this.context.stroke();
      this.context.strokeStyle = branch.depth < 3 ? '#275F55' : '#5B9B89';
      this.context.lineCap = 'round'; this.context.lineWidth = branch.width;
      this.context.beginPath(); this.context.moveTo(parent.x, parent.y);
      this.context.quadraticCurveTo((parent.x + branch.x) / 2 + (branch.y - parent.y) * 0.12, (parent.y + branch.y) / 2, branch.x, branch.y);
      this.context.stroke(); this.context.restore();
    }
  }

  private drawRootBed(): void {
    this.context.save();
    this.context.globalAlpha = 0.26; this.context.fillStyle = '#A9CEC0';
    this.context.beginPath(); this.context.ellipse(160, 404, 94, 26, 0, 0, Math.PI * 2); this.context.fill();
    this.context.globalAlpha = 0.9; this.context.strokeStyle = '#275F55'; this.context.lineCap = 'round';
    const roots: number[][] = [[78, 410, 115, 385], [104, 423, 132, 392], [216, 423, 188, 391], [242, 410, 204, 385], [143, 430, 151, 392], [177, 430, 169, 392]];
    for (let index = 0; index < roots.length; index += 1) {
      const root = roots[index]; this.context.lineWidth = index < 2 ? 2.4 : 1.45;
      this.context.beginPath(); this.context.moveTo(160, 418); this.context.quadraticCurveTo(root[2], root[3], root[0], root[1]); this.context.stroke();
    }
    this.context.restore();
  }

  private drawLeaves(progress: number): void {
    const leafProgress = Math.max(0, Math.min(1, (progress - 0.28) / 0.72));
    for (let index = 0; index < this.snapshot.leaves.length; index += 1) {
      if (index / Math.max(1, this.snapshot.leaves.length) > leafProgress) continue;
      const leaf = this.snapshot.leaves[index];
      this.context.save(); this.context.translate(leaf.x, leaf.y); this.context.rotate(leaf.rotation);
      this.context.globalAlpha = 0.16; this.context.fillStyle = '#184C43';
      this.context.beginPath(); this.context.ellipse(2.5, 3.5, leaf.radius * 0.74, leaf.radius * 1.05, 0, 0, Math.PI * 2); this.context.fill();
      if (leaf.glow > 0.2) {
        this.context.globalAlpha = leaf.glow * 0.45; this.context.fillStyle = '#BFE4D6';
        this.context.beginPath(); this.context.arc(0, 0, leaf.radius * 1.55, 0, Math.PI * 2); this.context.fill();
      }
      const fill = this.context.createLinearGradient(-leaf.radius, -leaf.radius, leaf.radius, leaf.radius);
      fill.addColorStop(0, '#EFF8F4'); fill.addColorStop(0.24, leaf.color); fill.addColorStop(1, '#285F55');
      this.context.globalAlpha = 0.58 + leafProgress * 0.3; this.context.fillStyle = fill;
      this.context.beginPath(); this.context.moveTo(0, -leaf.radius * 1.22);
      this.context.bezierCurveTo(leaf.radius, -leaf.radius * 0.48, leaf.radius * 0.9, leaf.radius * 0.76, 0, leaf.radius * 1.18);
      this.context.bezierCurveTo(-leaf.radius * 0.9, leaf.radius * 0.76, -leaf.radius, -leaf.radius * 0.48, 0, -leaf.radius * 1.22); this.context.fill();
      this.context.globalAlpha = 0.68; this.context.strokeStyle = '#FFFFFF'; this.context.lineWidth = 0.75;
      this.context.beginPath(); this.context.moveTo(0, -leaf.radius * 0.82); this.context.lineTo(0, leaf.radius * 0.8); this.context.stroke();
      this.context.globalAlpha = 0.45; this.context.lineWidth = 0.55;
      this.context.beginPath(); this.context.moveTo(0, -leaf.radius * 0.22); this.context.lineTo(leaf.radius * 0.48, leaf.radius * 0.12); this.context.moveTo(0, leaf.radius * 0.14); this.context.lineTo(-leaf.radius * 0.45, leaf.radius * 0.42); this.context.stroke();
      this.context.restore();
    }
  }

  private drawSeedling(): void {
    this.context.save();
    this.context.strokeStyle = '#397963'; this.context.lineWidth = 2.4; this.context.lineCap = 'round';
    this.context.beginPath(); this.context.moveTo(160, 380); this.context.quadraticCurveTo(158, 350, 164, 329); this.context.stroke();
    this.context.fillStyle = '#7EB5A0'; this.context.globalAlpha = 0.9;
    this.context.beginPath(); this.context.ellipse(151, 344, 8, 15, -0.65, 0, Math.PI * 2); this.context.fill();
    this.context.beginPath(); this.context.ellipse(172, 334, 8, 15, 0.65, 0, Math.PI * 2); this.context.fill();
    this.context.globalAlpha = 0.35; this.context.fillStyle = '#247A63';
    this.context.beginPath(); this.context.arc(160, 385, 10, 0, Math.PI * 2); this.context.fill();
    this.context.restore();
  }

}
