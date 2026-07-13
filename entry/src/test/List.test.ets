import authRepositoryTest from './AuthRepository.test';
import commonDayMemoryTest from './CommonDayMemory.test';
import homeViewModelTest from './HomeViewModel.test';
import localUnitTest from './LocalUnit.test';
import memoryRepositoryTest from './MemoryRepository.test';
import treeHoleRepositoryTest from './TreeHoleRepository.test';
import vineTreeLayoutTest from './VineTreeLayout.test';

export default function testsuite() {
  localUnitTest();
  homeViewModelTest();
  authRepositoryTest();
  memoryRepositoryTest();
  vineTreeLayoutTest();
  treeHoleRepositoryTest();
  commonDayMemoryTest();
}
