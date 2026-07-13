export class TreeLeaf {
  memoryId: number = 0;
  x: number = 0;
  y: number = 0;
  radius: number = 0;
  rotation: number = 0;
  color: string = '';
  branchId: number = 0;
  growth: number = 1;
  glow: number = 0;

  constructor(memoryId: number, x: number, y: number, radius: number, rotation: number, color: string,
    branchId: number = 0, growth: number = 1, glow: number = 0) {
    this.memoryId = memoryId;
    this.x = x;
    this.y = y;
    this.radius = radius;
    this.rotation = rotation;
    this.color = color;
    this.branchId = branchId;
    this.growth = growth;
    this.glow = glow;
  }
}
