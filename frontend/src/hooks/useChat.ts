import { useState, useCallback } from 'react';
import { Message, ChatResponse, ComparisonResponse, VariantResponse } from '../types';
import { mitoAPI } from '../services/api';

export const useChat = () => {
  const [messages, setMessages] = useState<Message[]>([
    {
      id: '1',
      text: 'Vitajte v Miťo! 🧬 Som váš slovenský zdravotný asistent špecializovaný na epigenetiku, kvantovú biológiu a zdravie. Opýtajte sa ma čokoľvek!',
      sender: 'assistant',
      timestamp: new Date(),
      sources: [],
    },
  ]);
  const [isLoading, setIsLoading] = useState(false);
  const [sessionId, setSessionId] = useState<string>('');

  const sendMessage = useCallback(
    async (text: string) => {
      if (!text.trim() || isLoading) return;

      // Add user message
      const userMessage: Message = {
        id: Date.now().toString(),
        text: text.trim(),
        sender: 'user',
        timestamp: new Date(),
      };

      setMessages((prev) => [...prev, userMessage]);
      setIsLoading(true);

      // Add loading message
      const loadingMessage: Message = {
        id: (Date.now() + 1).toString(),
        text: 'Získavam odpovede z oboch variantov RAG systému...',
        sender: 'assistant',
        timestamp: new Date(),
        isLoading: true,
      };

      setMessages((prev) => [...prev, loadingMessage]);

      try {
        // Always use comparison endpoint
        const response: ComparisonResponse = await mitoAPI.sendMessageCompare(
          text,
          sessionId,
        );

        // Update session ID if we got a new one
        if (response.session_id && response.session_id !== sessionId) {
          setSessionId(response.session_id);
        }

        // Replace loading message with comparison response
        const comparisonMessage: Message = {
          id: (Date.now() + 2).toString(),
          text: '', // We'll handle display in ComparisonView
          sender: 'assistant',
          timestamp: new Date(response.timestamp),
          isComparison: true,
          variantResponses: response.responses,
        };

        setMessages((prev) => prev.slice(0, -1).concat(comparisonMessage));
      } catch (error) {
        console.error('Chat error:', error);

        // Replace loading message with error message
        const errorMessage: Message = {
          id: (Date.now() + 3).toString(),
          text: 'Prepáčte, nastala chyba pri spracovaní vašej otázky. Skúste to prosím znovu.',
          sender: 'assistant',
          timestamp: new Date(),
        };

        setMessages((prev) => prev.slice(0, -1).concat(errorMessage));
      } finally {
        setIsLoading(false);
      }
    },
    [isLoading, sessionId],
  );


  const clearChat = useCallback(() => {
    setMessages([
      {
        id: '1',
        text: 'Vitajte v Miťo! 🧬 Som váš slovenský zdravotný asistent špecializovaný na epigenetiku, kvantovú biológiu a zdravie. Opýtajte sa ma čokoľvek!',
        sender: 'assistant',
        timestamp: new Date(),
        sources: [],
      },
    ]);
    setSessionId('');
  }, []);

  return {
    messages,
    isLoading,
    sendMessage,
    clearChat,
  };
};
