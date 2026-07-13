import { AppRoutes } from '../constants/AppRoutes';
import { HomeFeature } from '../models/HomeFeature';

export class HomeViewModel {
  readonly eyebrow: string = 'MY MEMORY GARDEN';
  readonly greeting: string = '把今天，种进记忆里';
  readonly description: string = '每一次记录，都会让属于你的记忆树长出新的叶片。';

  readonly features: HomeFeature[] = [
    new HomeFeature('add', '＋', '添加记忆', '记录此刻的文字、图片与心情', AppRoutes.ADD_MEMORY),
    new HomeFeature('tree', '♧', '记忆树', '查看你的记忆节点', AppRoutes.MEMORY_TREE),
    new HomeFeature('day', '◷', '共同一天', '沿着 24 小时时间轴重逢', AppRoutes.COMMON_DAY),
    new HomeFeature('shared', '⌂', '树洞', '与重要的人共同记录', AppRoutes.SHARED_TREE),
    new HomeFeature('mine', '○', '我的', '管理个人资料与应用设置', AppRoutes.MINE)
  ];
}
