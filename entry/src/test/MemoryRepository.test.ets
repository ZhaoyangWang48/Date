import { describe, expect, it } from '@ohos/hypium';
import { Memory } from '../main/ets/models/Memory';

export default function memoryRepositoryTest() {
  describe('Memory', () => {
    it('keepsServerMappedFields', 0, () => {
      const memory = new Memory(1, 2, '测试用户', '今天种下第一段记忆', '', 'calm', '2026-07-10', 15, '2026-07-10T15:30:00', 0);
      expect(memory.authorId).assertEqual(2);
      expect(memory.hour).assertEqual(15);
    });
  });
}
