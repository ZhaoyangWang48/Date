import { Context } from '@kit.AbilityKit';
import { preferences } from '@kit.ArkData';

export class RadioPlaylistStore {
  private static readonly STORE: string = 'zhiyi_radio';
  private static readonly KEY: string = 'favorite_ids';
  static async load(context: Context): Promise<number[]> {
    try {
      const store = await preferences.getPreferences(context, RadioPlaylistStore.STORE);
      const json = await store.get(RadioPlaylistStore.KEY, '[]') as string;
      const values = JSON.parse(json) as number[];
      return RadioPlaylistStore.normalize(values);
    } catch (_) { return []; }
  }
  static async save(context: Context, ids: number[]): Promise<void> {
    try {
      const store = await preferences.getPreferences(context, RadioPlaylistStore.STORE);
      await store.put(RadioPlaylistStore.KEY, JSON.stringify(RadioPlaylistStore.normalize(ids)));
      await store.flush();
    } catch (_) { }
  }
  static async toggle(context: Context, memoryId: number): Promise<boolean> {
    const ids = await RadioPlaylistStore.load(context);
    const index = ids.indexOf(memoryId);
    if (index >= 0) {
      ids.splice(index, 1);
      await RadioPlaylistStore.save(context, ids);
      return false;
    }
    ids.push(memoryId);
    await RadioPlaylistStore.save(context, ids);
    return true;
  }
  private static normalize(values: number[]): number[] {
    const result: number[] = [];
    for (let i = 0; i < values.length; i++) {
      const id = values[i];
      if (typeof id === 'number' && id > 0 && result.indexOf(id) < 0) result.push(id);
    }
    return result;
  }
}
