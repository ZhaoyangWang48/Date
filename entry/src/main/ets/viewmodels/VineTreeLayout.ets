import { Memory } from '../models/Memory';
import { TreeLeaf } from '../models/TreeLeaf';

export class VineTreeLayout {
  static readonly WIDTH: number = 320;
  static readonly HEIGHT: number = 430;

  static createLeaves(memories: Memory[]): TreeLeaf[] {
    const leaves: TreeLeaf[] = [];
    for (let index = 0; index < memories.length; index += 1) {
      const ring = Math.floor(index / 6);
      const angle = -Math.PI / 2 + index * 2.399963229728653;
      const distance = 54 + ring * 34;
      const x = 160 + Math.cos(angle) * distance;
      const y = 190 + Math.sin(angle) * distance * 0.78;
      const radius = ring < 2 ? 16 : 13;
      leaves.push(new TreeLeaf(memories[index].id, x, y, radius, angle + Math.PI / 2,
        VineTreeLayout.getMoodColor(memories[index].mood)));
    }
    return leaves;
  }

  static hitTest(leaves: TreeLeaf[], x: number, y: number): number {
    for (let index = leaves.length - 1; index >= 0; index -= 1) {
      const leaf = leaves[index];
      const distanceX = x - leaf.x;
      const distanceY = y - leaf.y;
      const hitRadius = leaf.radius + 10;
      if (distanceX * distanceX + distanceY * distanceY <= hitRadius * hitRadius) {
        return leaf.memoryId;
      }
    }
    return 0;
  }

  private static getMoodColor(mood: string): string {
    if (mood === 'happy') {
      return '#E2A94B';
    }
    if (mood === 'excited') {
      return '#D97979';
    }
    if (mood === 'sad') {
      return '#6D92B4';
    }
    if (mood === 'tired') {
      return '#9A8AAC';
    }
    return '#5F9C6B';
  }
}
