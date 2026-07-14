export class ApiConfig {
  static readonly DEFAULT_BASE_URL: string = 'http://127.0.0.1:8080';
  // 启动时自动探测的候选服务器地址，按顺序尝试
  static readonly CANDIDATE_URLS: string[] = [
    'http://127.0.0.1:8080',
    'http://127.0.0.1:8080',        // 模拟器 NAT 宿主机映射
    'http://127.0.0.1:8080',     // Local development
    'http://127.0.0.1:8080', // WLAN
  ];
  // 启动时从本机 preferences 读取；可在“我的”页面修改。
  static BASE_URL: string = ApiConfig.DEFAULT_BASE_URL;

  static setBaseUrl(value: string): void {
    ApiConfig.BASE_URL = value.endsWith('/') ? value.substring(0, value.length - 1) : value;
  }

  static readonly AUTH_LOGIN: string = '/api/auth/login';
  static readonly AUTH_REGISTER: string = '/api/auth/register';
  static readonly USER_ME: string = '/api<REDACTED_LOCAL_PATH>';
  static readonly MEMORIES: string = '/api/memories';
  static readonly TREE_HOLES: string = '/api/tree-holes';
  static readonly IMAGE_UPLOAD: string = '/api/files/images';
  static readonly MEMORY_DRAFT: string = '/api/ai/memory-draft';
  static readonly AGENT_CHAT: string = '/api/agent/rememberer/chat';
  static readonly TIME_CAPSULES: string = '/api/time-capsules';
  static readonly BOTTLES: string = '/api/bottles';
  static readonly RECALL_CARDS_GENERATE: string = '/api/recall-cards/generate';
  static readonly RECALL_CARDS: string = '/api/recall-cards';
  static RECALL_CARD_DETAIL(id: number): string { return `/api/recall-cards/${id}`; }
}
