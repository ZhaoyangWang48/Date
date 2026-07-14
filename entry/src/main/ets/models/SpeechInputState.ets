export enum SpeechInputStatus {
  IDLE = 'idle',
  STARTING = 'starting',
  LISTENING = 'listening',
  PROCESSING = 'processing',
  COMPLETED = 'completed',
  ERROR = 'error'
}

export class SpeechInputUpdate {
  status: SpeechInputStatus = SpeechInputStatus.IDLE;
  text: string = '';
  message: string = '';

  constructor(status: SpeechInputStatus, text: string = '', message: string = '') {
    this.status = status; this.text = text; this.message = message;
  }
}
