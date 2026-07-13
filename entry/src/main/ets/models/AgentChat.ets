export interface AgentSourceCitation {
  memoryId: number;
  contentSnippet: string;
  date: string;
  authorName: string;
}

export interface AgentChatResponse {
  answer: string;
  sources: AgentSourceCitation[];
}
