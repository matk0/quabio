export interface Message {
  id: string;
  text: string;
  sender: 'user' | 'assistant';
  sources?: Source[];
  timestamp: Date;
  isLoading?: boolean;
}

export interface Source {
  title: string;
  excerpt: string;
  url: string;
  relevance_score: number;
}

export interface ChatRequest {
  message: string;
  session_id?: string;
}

export interface ChatResponse {
  response: string;
  sources: Source[];
  session_id: string;
  timestamp: string;
}

export interface HealthResponse {
  status: string;
  model: string;
  vector_store_status: string;
}