export class HomeFeature {
  id: string = '';
  icon: string = '';
  title: string = '';
  description: string = '';
  route: string = '';

  constructor(id: string, icon: string, title: string, description: string, route: string) {
    this.id = id;
    this.icon = icon;
    this.title = title;
    this.description = description;
    this.route = route;
  }
}
