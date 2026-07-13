import { describe, expect, it } from '@ohos/hypium';
import { AppRoutes } from '../main/ets/constants/AppRoutes';
import { HomeViewModel } from '../main/ets/viewmodels/HomeViewModel';

export default function homeViewModelTest() {
  describe('HomeViewModel', () => {
    it('exposesFiveRoutableFeatures', 0, () => {
      const viewModel = new HomeViewModel();

      expect(viewModel.features.length).assertEqual(5);
      expect(viewModel.features[0].route).assertEqual(AppRoutes.ADD_MEMORY);
      expect(viewModel.features[1].route).assertEqual(AppRoutes.MEMORY_TREE);
      expect(viewModel.features[2].route).assertEqual(AppRoutes.COMMON_DAY);
      expect(viewModel.features[3].route).assertEqual(AppRoutes.SHARED_TREE);
      expect(viewModel.features[4].route).assertEqual(AppRoutes.MINE);
    });
  });
}
