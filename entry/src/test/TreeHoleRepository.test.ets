import { describe, expect, it } from '@ohos/hypium';
import { TreeHole } from '../main/ets/models/TreeHole';

export default function treeHoleRepositoryTest() {
  describe('TreeHole', () => {
    it('keepsInviteCodeFromServer', 0, () => {
      const tree = new TreeHole(1, '测试树洞', 'REMOVED_SECRET', 2, '2026-07-10T09:00:00');
      expect(tree.inviteCode).assertEqual('REMOVED_SECRET');
    });
  });
}
