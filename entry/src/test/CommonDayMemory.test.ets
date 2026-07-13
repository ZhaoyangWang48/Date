import { describe, expect, it } from '@ohos/hypium';
import { Memory } from '../main/ets/models/Memory';

export default function commonDayMemoryTest() {
  describe('CommonDayMemory', () => {
    it('preservesTreeAndHour', 0, () => {
      const memory = new Memory(3, 1, '测试用户', '下午三点', '', 'happy', '2026-07-10', 15, '2026-07-10T15:00:00', 1);
      expect(memory.treeHoleId).assertEqual(1);
      expect(memory.hour).assertEqual(15);
    });
  });
}
