import axios from 'axios';
import { ChatRequest, ChatResponse, HealthResponse } from '../types';

const API_BASE_URL = process.env.REACT_APP_API_URL || 'http://localhost:8000';

class MitoAPI {
  private client = axios.create({
    baseURL: API_BASE_URL,
    timeout: 60000, // 60 seconds timeout for Slovak text processing
    headers: {
      'Content-Type': 'application/json',
    },
  });

  async sendMessage(message: string, sessionId?: string): Promise<ChatResponse> {
    const request: ChatRequest = {
      message,
      session_id: sessionId,
    };

    try {
      const response = await this.client.post<ChatResponse>('/api/chat', request);
      return response.data;
    } catch (error) {
      console.error('Error sending message:', error);
      throw new Error('Nastala chyba pri posielaní správy');
    }
  }

  async checkHealth(): Promise<HealthResponse> {
    try {
      const response = await this.client.get<HealthResponse>('/api/health');
      return response.data;
    } catch (error) {
      console.error('Health check failed:', error);
      throw new Error('Kontrola zdravia zlyhala');
    }
  }

  async getStats() {
    try {
      const response = await this.client.get('/api/stats');
      return response.data;
    } catch (error) {
      console.error('Error getting stats:', error);
      throw new Error('Chyba pri získavaní štatistík');
    }
  }
}

export const mitoAPI = new MitoAPI();