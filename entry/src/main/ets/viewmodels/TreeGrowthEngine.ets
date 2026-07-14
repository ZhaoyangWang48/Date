import { Memory } from '../models/Memory';
import { TreeLeaf } from '../models/TreeLeaf';

export class BranchNode {
  id: number = 0;
  parentId: number = -1;
  x: number = 0;
  y: number = 0;
  depth: number = 0;
  width: number = 1;
  children: number = 0;
  directionX: number = 0;
  directionY: number = -1;
  constructor(id: number, parentId: number, x: number, y: number, depth: number, width: number,
    directionX: number = 0, directionY: number = -1) {
    this.id = id; this.parentId = parentId; this.x = x; this.y = y; this.depth = depth; this.width = width;
    this.directionX = directionX; this.directionY = directionY;
  }
}

export class GrowthTarget {
  memory: Memory;
  x: number = 0;
  y: number = 0;
  attachedBranchId: number = -1;
  constructor(memory: Memory, x: number, y: number) { this.memory = memory; this.x = x; this.y = y; }
}

export class TreeGrowthSnapshot {
  branches: BranchNode[] = [];
  leaves: TreeLeaf[] = [];
  targets: GrowthTarget[] = [];
}

export class TreeGrowthEngine {
  static readonly WIDTH: number = 320;
  static readonly HEIGHT: number = 430;
  private static readonly GOLDEN_ANGLE: number = 2.399963229728653;
  // 第一片叶子与预设主茎顶端相距约 110–122px；吸引半径必须覆盖这段距离，
  // 否则只有一片叶子时，生长算法找不到目标，主茎会停在画布中部。
  private static readonly ATTRACTION_RADIUS: number = 140;
  private static readonly ATTACH_DISTANCE: number = 15;
  private static readonly MAX_BRANCH_DEPTH: number = 12;

  static create(memories: Memory[], seed: number): TreeGrowthSnapshot {
    const snapshot = new TreeGrowthSnapshot();
    const ordered = memories.slice().sort((a: Memory, b: Memory) => {
      const dateCompare = a.createdAt.localeCompare(b.createdAt);
      return dateCompare === 0 ? a.id - b.id : dateCompare;
    });
    snapshot.targets = TreeGrowthEngine.createTargets(ordered, seed);
    snapshot.branches = TreeGrowthEngine.growBranches(snapshot.targets);
    snapshot.leaves = TreeGrowthEngine.attachLeaves(snapshot.targets, snapshot.branches);
    return snapshot;
  }

  static hitTest(leaves: TreeLeaf[], x: number, y: number): number {
    for (let index = leaves.length - 1; index >= 0; index -= 1) {
      const leaf = leaves[index];
      const dx = x - leaf.x;
      const dy = y - leaf.y;
      const radius = leaf.radius + 10;
      if (dx * dx + dy * dy <= radius * radius) return leaf.memoryId;
    }
    return 0;
  }

  private static createTargets(memories: Memory[], seed: number): GrowthTarget[] {
    const targets: GrowthTarget[] = [];
    let state = seed === 0 ? 97 : seed;
    for (let index = 0; index < memories.length; index += 1) {
      state = TreeGrowthEngine.next(state);
      const jitterX = ((state % 1000) / 1000 - 0.5) * 16;
      state = TreeGrowthEngine.next(state);
      const jitterY = ((state % 1000) / 1000 - 0.5) * 12;
      const band = Math.floor(index / 10);
      const angle = -Math.PI / 2 + index * TreeGrowthEngine.GOLDEN_ANGLE;
      const distance = 34 + band * 24 + (index % 5) * 3;
      let x = 160 + Math.cos(angle) * distance * 1.12 + jitterX;
      let y = 190 + Math.sin(angle) * distance * 0.76 + jitterY;
      x = Math.max(28, Math.min(292, x));
      y = Math.max(42, Math.min(284, y));
      for (let retry = 0; retry < 16; retry += 1) {
        let collides = false;
        for (let attempt = 0; attempt < targets.length; attempt += 1) {
          const other = targets[attempt];
          const dx = x - other.x;
          const dy = y - other.y;
          if (dx * dx + dy * dy < 25 * 25) { collides = true; break; }
        }
        if (!collides) break;
        const escapeAngle = angle + retry * 0.82;
        x += Math.cos(escapeAngle) * 9;
        y += Math.sin(escapeAngle) * 7;
        x = Math.max(24, Math.min(296, x));
        y = Math.max(36, Math.min(292, y));
      }
      targets.push(new GrowthTarget(memories[index], x, y));
    }
    return targets;
  }

  private static growBranches(targets: GrowthTarget[]): BranchNode[] {
    const branches: BranchNode[] = [];
    branches.push(new BranchNode(0, -1, 160, 418, 0, 10));
    branches.push(new BranchNode(1, 0, 157, 372, 1, 8));
    branches.push(new BranchNode(2, 1, 164, 326, 2, 6));
    branches.push(new BranchNode(3, 2, 159, 280, 3, 4.5));
    let nextId = 4;
    for (let step = 0; step < 44; step += 1) {
      const active: number[] = [];
      for (let index = 0; index < targets.length; index += 1) if (targets[index].attachedBranchId < 0) active.push(index);
      if (active.length === 0) break;
      const sumX: number[] = [];
      const sumY: number[] = [];
      const count: number[] = [];
      for (let index = 0; index < branches.length; index += 1) { sumX[index] = 0; sumY[index] = 0; count[index] = 0; }
      for (let targetIndex = 0; targetIndex < active.length; targetIndex += 1) {
        const target = targets[active[targetIndex]];
        let nearest = -1;
        let nearestDistance = TreeGrowthEngine.ATTRACTION_RADIUS * TreeGrowthEngine.ATTRACTION_RADIUS;
        for (let branchIndex = 0; branchIndex < branches.length; branchIndex += 1) {
          const branch = branches[branchIndex];
          const dx = target.x - branch.x;
          const dy = target.y - branch.y;
          const distance = dx * dx + dy * dy;
          if (distance < TreeGrowthEngine.ATTACH_DISTANCE * TreeGrowthEngine.ATTACH_DISTANCE) {
            target.attachedBranchId = branch.id; nearest = -1; break;
          }
          if (distance < nearestDistance && branch.children < 3) { nearest = branchIndex; nearestDistance = distance; }
        }
        if (nearest >= 0) {
          const branch = branches[nearest];
          const length = Math.sqrt(nearestDistance);
          sumX[nearest] += (target.x - branch.x) / length;
          sumY[nearest] += (target.y - branch.y) / length;
          count[nearest] += 1;
        }
      }
      let added = 0;
      const originalLength = branches.length;
      for (let index = 0; index < originalLength; index += 1) {
        if (count[index] === 0 || branches[index].depth >= TreeGrowthEngine.MAX_BRANCH_DEPTH) continue;
        const branch = branches[index];
        const vectorLength = Math.sqrt(sumX[index] * sumX[index] + sumY[index] * sumY[index]);
        const segment = Math.max(10, 17 - branch.depth * 0.7);
        const directionX = sumX[index] / vectorLength;
        const directionY = sumY[index] / vectorLength;
        if (!TreeGrowthEngine.hasNaturalFork(branches, branch, directionX, directionY)) continue;
        const x = branch.x + directionX * segment;
        const y = branch.y + directionY * segment;
        branches.push(new BranchNode(nextId++, branch.id, x, y, branch.depth + 1,
          Math.max(1.1, branch.width * 0.72), directionX, directionY));
        branch.children += 1;
        added += 1;
      }
      if (added === 0) break;
    }
    return branches;
  }

  private static attachLeaves(targets: GrowthTarget[], branches: BranchNode[]): TreeLeaf[] {
    const leaves: TreeLeaf[] = [];
    for (let index = 0; index < targets.length; index += 1) {
      const target = targets[index];
      let branchId = target.attachedBranchId;
      if (branchId < 0) branchId = TreeGrowthEngine.nearestBranch(target, branches);
      const branch = branches[branchId];
      const radius = target.memory.imageUrl.length > 0 ? 15 : 12 + (index % 3);
      const angle = Math.atan2(target.y - branch.y, target.x - branch.x) + Math.PI / 2;
      leaves.push(new TreeLeaf(target.memory.id, target.x, target.y, radius, angle,
        TreeGrowthEngine.moodColor(target.memory.mood), branchId, 1, target.memory.imageUrl.length > 0 ? 0.42 : 0.14));
    }
    return leaves;
  }

  private static nearestBranch(target: GrowthTarget, branches: BranchNode[]): number {
    let selected = 0; let distance = Number.MAX_VALUE;
    for (let index = 0; index < branches.length; index += 1) {
      const dx = target.x - branches[index].x; const dy = target.y - branches[index].y;
      const current = dx * dx + dy * dy;
      if (current < distance) { distance = current; selected = index; }
    }
    return selected;
  }

  private static hasNaturalFork(branches: BranchNode[], parent: BranchNode, directionX: number, directionY: number): boolean {
    // 22 degrees keeps sibling branches from becoming mechanically parallel.
    const maximumCosine = Math.cos(22 * Math.PI / 180);
    for (let index = 0; index < branches.length; index += 1) {
      const sibling = branches[index];
      if (sibling.parentId !== parent.id) continue;
      const similarity = sibling.directionX * directionX + sibling.directionY * directionY;
      if (similarity > maximumCosine) return false;
    }
    return true;
  }

  private static next(value: number): number { return (value * 1664525 + 1013904223) & 0x7fffffff; }
  private static moodColor(mood: string): string {
    if (mood === 'happy' || mood === 'joy') return '#CDA560';
    if (mood === 'excited') return '#C98279';
    if (mood === 'sad') return '#7D9DA6';
    if (mood === 'tired') return '#8E87A2';
    if (mood === 'hope') return '#91B8A3';
    return '#6F9D78';
  }
}
