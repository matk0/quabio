import React from 'react';
import { Header } from './Header';
import { MessageList } from './MessageList';
import { InputBar } from './InputBar';
import { useChat } from '../hooks/useChat';

export const ChatInterface: React.FC = () => {
  const { messages, isLoading, sendMessage, clearChat } = useChat();

  return (
    <div className="flex flex-col h-screen bg-mito-gray">
      <Header onClearChat={clearChat} />
      
      <MessageList messages={messages} />
      
      <InputBar 
        onSend={sendMessage}
        disabled={isLoading}
        placeholder="Napíšte vašu otázku..."
      />
    </div>
  );
};