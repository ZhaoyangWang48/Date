import { describe, expect, it } from '@ohos/hypium';
import { AuthData } from '../main/ets/models/AuthData';
import { User } from '../main/ets/models/User';

export default function authRepositoryTest() {
  describe('AuthData', () => {
    it('keepsServerSessionFields', 0, () => {
      const data = new AuthData('token', new User(7, 'tester', '测试用户'));
      expect(data.user.id).assertEqual(7);
      expect(data.token).assertEqual('token');
    });
  });
}
