import { describe, expect, it } from '@ohos/hypium';
import { TimeCapsule } from '../main/ets/models/TimeCapsule';

export default function timeCapsuleTest() {
  describe('TimeCapsulePrivacy', () => {
    it('hidesContentUntilOpened', 0, () => {
      const capsule = new TimeCapsule();
      capsule.content = '未来才能看到的秘密';

      expect(capsule.displayContent()).assertEqual('内容已封存，开启后可见');

      capsule.isOpened = true;
      expect(capsule.displayContent()).assertEqual('未来才能看到的秘密');
    });
  });
}
