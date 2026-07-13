@Entry
@Component
struct RecentPhotoWidget {
  @LocalStorageProp('photoCount') photoCount: number = 0;
  @LocalStorageProp('photo0') photo0: string = '';
  @LocalStorageProp('photo0Date') photo0Date: string = '';
  @LocalStorageProp('photo1') photo1: string = '';
  @LocalStorageProp('photo1Date') photo1Date: string = '';
  @LocalStorageProp('photo2') photo2: string = '';
  @LocalStorageProp('photo2Date') photo2Date: string = '';
  @LocalStorageProp('photo3') photo3: string = '';
  @LocalStorageProp('photo3Date') photo3Date: string = '';
  @LocalStorageProp('hasPhotos') hasPhotos: number = 0;
  @LocalStorageProp('lastUpdate') lastUpdate: string = '';

  build() {
    Stack({ alignContent: Alignment.TopStart }) {
      Column()
        .width('100%')
        .height('100%')
        .borderRadius(16)
        .linearGradient({
          direction: GradientDirection.Top,
          colors: [['#F5F0E8', 0], ['#EBE3D5', 1]]
        })

      Column({ space: 0 }) {
        Row({ space: 8 }) {
          Text('📷')
            .fontSize(15)
          Text('最近照片')
            .fontSize(15)
            .fontWeight(FontWeight.Bold)
            .fontColor('#3D3226')
          Blank()
          if (this.hasPhotos === 1) {
            Text(`${this.photoCount}张 · ${this.lastUpdate}`)
              .fontSize(10)
              .fontColor('#8B7E6E')
          }
        }
        .width('100%')
        .padding({ left: 14, right: 14, top: 12, bottom: 8 })

        if (this.hasPhotos === 1) {
          this.buildPhotoGrid()
        } else {
          this.buildEmptyState()
        }
      }
      .width('100%')
      .height('100%')
    }
    .width('100%')
    .height('100%')
    .onClick(() => {
      postCardAction(this, {
        action: 'router',
        abilityName: 'EntryAbility',
        params: { targetUri: 'pages/HomePage' }
      });
    })
  }

  @Builder
  buildPhotoGrid() {
    Column({ space: 6 }) {
      Row({ space: 6 }) {
        this.buildPhotoCell(this.photo0, this.photo0Date)
        this.buildPhotoCell(this.photo1, this.photo1Date)
      }
      .width('100%')
      .layoutWeight(1)

      Row({ space: 6 }) {
        this.buildPhotoCell(this.photo2, this.photo2Date)
        this.buildPhotoCell(this.photo3, this.photo3Date)
      }
      .width('100%')
      .layoutWeight(1)
    }
    .width('100%')
    .layoutWeight(1)
    .padding({ left: 12, right: 12, bottom: 12 })
  }

  @Builder
  buildPhotoCell(imgKey: string, date: string) {
    Stack({ alignContent: Alignment.BottomStart }) {
      // 两种情况：http开头=原始URL（未下载），/开头=沙箱路径（已下载可用memory://）
      if (imgKey && imgKey.length > 0 && !imgKey.startsWith('http')) {
        // 已下载的图片：用 memory:// 加载
        Image('memory://' + imgKey)
          .width('100%')
          .height('100%')
          .borderRadius(10)
          .objectFit(ImageFit.Cover)
      } else {
        // 未下载或无图片：占位
        Column() {
          Text('🌿')
            .fontSize(20)
            .opacity(0.3)
        }
        .width('100%')
        .height('100%')
        .borderRadius(10)
        .backgroundColor('#00000006')
        .justifyContent(FlexAlign.Center)
      }

      if (date && date.length > 0) {
        Text(date)
          .fontSize(9)
          .fontColor('#FFFFFFE6')
          .fontWeight(FontWeight.Medium)
          .padding({ left: 6, right: 6, top: 2, bottom: 4 })
          .width('100%')
          .borderRadius({ bottomLeft: 10, bottomRight: 10 })
          .backgroundColor('#33000000')
      }
    }
    .layoutWeight(1)
    .height('100%')
    .borderRadius(10)
  }

  @Builder
  buildEmptyState() {
    Column({ space: 6 }) {
      Text('🌱')
        .fontSize(28)
      Text('暂无照片')
        .fontSize(14)
        .fontWeight(FontWeight.Medium)
        .fontColor('#3D3226')
      Text('记录一张记忆照片吧')
        .fontSize(11)
        .fontColor('#8B7E6E')
        .opacity(0.7)
    }
    .width('100%')
    .layoutWeight(1)
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .padding({ left: 14, right: 14, bottom: 14 })
  }
}
