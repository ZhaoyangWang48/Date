export class ApiResult<T> {
  code: number = 0;
  message: string = '';
  data: T | undefined = undefined;

  constructor(code: number, message: string, data?: T) {
    this.code = code;
    this.message = message;
    this.data = data;
  }
}
