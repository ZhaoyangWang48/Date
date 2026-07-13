import { describe, expect, it } from '@ohos/hypium';
import { Memory } from '../main/ets/models/Memory';
import { VineTreeLayout } from '../main/ets/viewmodels/VineTreeLayout';

export default function vineTreeLayoutTest() {
  describe('VineTreeLayout', () => {
    it('mapsEachMemoryToAClickableLeaf', 0, () => {
      const memories: Memory[] = [
        new Memory(1, 1, '朝阳', '平静的一天', '', 'calm', '2026-07-10', 9, '2026-07-10 09:00'),
        new Memory(2, 1, '朝阳', '开心的一天', '', 'happy', '2026-07-10', 10, '2026-07-10 10:00')
      ];
      const leaves = VineTreeLayout.createLeaves(memories);

      expect(leaves.length).assertEqual(2);
      expect(VineTreeLayout.hitTest(leaves, leaves[0].x, leaves[0].y)).assertEqual(1);
      expect(VineTreeLayout.hitTest(leaves, leaves[1].x, leaves[1].y)).assertEqual(2);
    });
  });
}
