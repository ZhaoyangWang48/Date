export class ImageEditSession {
  static pending: boolean = false;
  static confirmed: boolean = false;
  static imageUrl: string = '';
  static finalUrl: string = '';

  static begin(url: string): void {
    ImageEditSession.pending = true; ImageEditSession.confirmed = false;
    ImageEditSession.imageUrl = url; ImageEditSession.finalUrl = '';
  }

  static updateUrl(url: string): void { ImageEditSession.imageUrl = url; }

  static confirm(): void {
    ImageEditSession.confirmed = true;
    ImageEditSession.finalUrl = ImageEditSession.imageUrl;
  }

  static consume(): boolean {
    const was = ImageEditSession.pending;
    ImageEditSession.pending = false;
    return was;
  }
}
