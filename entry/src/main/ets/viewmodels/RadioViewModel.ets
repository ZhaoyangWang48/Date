import { Context } from '@kit.AbilityKit';
import { Memory } from '../models/Memory';
import { MemoryTrack, RadioChannel } from '../models/RadioChannel';
import { MemoryViewModel } from './MemoryViewModel';
import { RadioPlaylistStore } from '../services/RadioPlaylistStore';
import { CapsuleTtsService, TtsStateListener } from '../services/CapsuleTtsService';

export class RadioViewModel {
  private readonly memories: MemoryViewModel = new MemoryViewModel();
  async load(context: Context, channel: RadioChannel): Promise<MemoryTrack[]> {
    const source = await this.memories.listMemories(context); const favorites = await RadioPlaylistStore.load(context);
    return channel.filter(source).map((memory: Memory, index: number) => { const track = new MemoryTrack(memory, index); track.isFavorited = favorites.indexOf(memory.id) >= 0; return track; });
  }
  async toggleFavorite(context: Context, tracks: MemoryTrack[], index: number): Promise<MemoryTrack[]> {
    const next = tracks.slice(); const track = next[index]; if (track === undefined) return next;
    track.isFavorited = await RadioPlaylistStore.toggle(context, track.memory.id);
    return next;
  }
  async play(track: MemoryTrack, listener: TtsStateListener): Promise<boolean> { return CapsuleTtsService.speak(track.narration(), listener); }
  stop(): void { CapsuleTtsService.stop(); }
}
