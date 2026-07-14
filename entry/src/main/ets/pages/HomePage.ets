import { BusinessError } from '@kit.BasicServicesKit';
import { FeatureEntryCard } from '../components/FeatureEntryCard';
import { RecentPhotoCard } from '../components/RecentPhotoCard';
import { Memory } from '../models/Memory';
import { HomeFeature } from '../models/HomeFeature';
import { HomeViewModel } from '../viewmodels/HomeViewModel';
import { MemoryViewModel } from '../viewmodels/MemoryViewModel';
import { WidgetPhotoCache } from '../services/WidgetPhotoCache';
import { ImagePreloader } from '../services/ImagePreloader';

@Entry
@Component
struct HomePage {
  private readonly viewModel: HomeViewModel = new HomeViewModel();
  private readonly memoryViewModel: MemoryViewModel = new MemoryViewModel();
  @State recentPhotos: Memory[] = [];

  aboutToAppear(): void {
    this.loadRecentPhotos();
  }

  private async loadRecentPhotos(): Promise<void> {
    try {
      const memories = await this.memoryViewModel.listMemories(getContext(this));
      const photos = memories
        .filter((m: Memory) => m.imageUrl && m.imageUrl.length > 0)
        .sort((a: Memory, b: Memory) => b.createdAt.localeCompare(a.createdAt))
        .slice(0, 10);
      // Widget 缓存存原始 HTTP URL（供 EntryFormAbility 自己下载）
      WidgetPhotoCache.saveFromMemories(getContext(this), photos);
      // UI 显示用沙箱本地路径
      this.recentPhotos = await ImagePreloader.preloadPhotos(getContext(this), photos);
    } catch (err) {
      console.error('Failed to load recent photos:', JSON.stringify(err));
    }
  }

  private openPage(route: string): void {
    try {
      this.getUIContext().getRouter().pushUrl({ url: route }, (error: BusinessError) => {
        if (error) {
          console.error(`Failed to open ${route}. Code: ${error.code}, message: ${error.message}`);
        }
      });
    } catch (error) {
      console.error(`Failed to open ${route}. Cause: ${JSON.stringify(error)}`);
    }
  }

  build() {
    Scroll() {
      Column({ space: 0 }) {
        Row() {
          Column({ space: 6 }) {
            Text(this.viewModel.eyebrow)
              .fontSize(11)
              .fontColor($r('app.color.accent_gold'))
              .fontWeight(FontWeight.Bold)
              .letterSpacing(2)

            Text('植忆')
              .fontSize(27)
              .fontWeight(FontWeight.Bold)
              .fontColor($r('app.color.text_primary'))
          }
          .alignItems(HorizontalAlign.Start)

          Blank()

          Stack() {
            Text('叶')
              .fontSize(16)
              .fontWeight(FontWeight.Medium)
              .fontColor($r('app.color.accent_gold'))
          }
          .width(48)
          .height(48)
          .borderRadius(18)
          .backgroundColor($r('app.color.accent_gold_soft'))
        }
        .width('100%')

        Stack({ alignContent: Alignment.BottomStart }) {
          Column({ space: 12 }) {
            Text(this.viewModel.greeting)
              .fontSize(29)
              .fontWeight(FontWeight.Bold)
              .fontColor($r('app.color.on_forest'))
              .width('100%')
            Text(this.viewModel.description)
              .fontSize(14)
              .fontColor($r('app.color.forest_mist'))
              .lineHeight(22)
              .maxLines(2)
              .width('82%')
            Row({ space: 9 }) {
              Text('今日新叶')
                .fontSize(11)
                .fontColor($r('app.color.forest_mist'))
              Text('·')
                .fontColor($r('app.color.accent_gold'))
              Text('把此刻留给未来')
                .fontSize(11)
                .fontColor($r('app.color.forest_mist'))
            }
          }
          .alignItems(HorizontalAlign.Start)
          .width('100%')
          .padding(22)
          Column() {
            Text('01')
              .fontSize(54)
              .fontWeight(FontWeight.Lighter)
              .fontColor('#FFFFFF24')
          }
          .alignItems(HorizontalAlign.End)
          .width('100%')
          .padding({ right: 18, bottom: 10 })
        }
        .width('100%')
        .height(186)
        .borderRadius(30)
        .backgroundColor($r('app.color.forest_deep'))
        .shadow({ radius: 22, color: '#0C241F45', offsetX: 0, offsetY: 10 })
        .margin({ top: 26, bottom: 30 })

        RecentPhotoCard({
          photos: this.recentPhotos,
          onPhotoClick: (memory: Memory) => {
            this.openPage('pages/MemoryDetailPage');
          }
        })
          .margin({ bottom: 28 })

        Row() {
          Text('记忆树')
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .fontColor($r('app.color.text_primary'))
          Blank()
          Text('慢慢生长')
            .fontSize(12)
            .fontColor($r('app.color.text_secondary'))
        }
        .width('100%')
        .margin({ bottom: 14 })

        Column({ space: 14 }) {
          ForEach(this.viewModel.features, (feature: HomeFeature) => {
            FeatureEntryCard({
              icon: feature.icon,
              title: feature.title,
              description: feature.description,
              onOpen: () => {
                this.openPage(feature.route);
              }
            })
          }, (feature: HomeFeature) => feature.id)
        }
        .width('100%')

        Text('每一片叶子，都有被珍惜的理由。')
          .fontSize(12)
          .fontColor($r('app.color.text_secondary'))
          .margin({ top: 28, bottom: 10 })
      }
      .width('100%')
      .padding({ left: 20, right: 20, top: 32, bottom: 24 })
    }
    .width('100%')
    .height('100%')
    .scrollBar(BarState.Off)
    .edgeEffect(EdgeEffect.Spring)
    .backgroundColor($r('app.color.app_background'))
  }
}
