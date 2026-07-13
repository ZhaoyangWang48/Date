import { describe, it, expect } from '@ohos/hypium';
import { Memory } from '../../../main/ets/models/Memory';

export default function abilityTest() {
  describe('ZhiyiPrototypeAcceptance', () => {
    it('mapsCommonDayFieldsFromBackend', 0, () => {
      const memory = new Memory(4, 2, '小满', '同一天记录', '', 'calm', '2026-07-10', 10, '2026-07-10T10:00:00', 1);
      expect(memory.treeHoleId).assertEqual(1);
      expect(memory.hour).assertEqual(10);
    })
  })
}
