import React from 'react';
import { Message } from '../types';
import { SourceCard } from './SourceCard';
import { ComparisonView } from './ComparisonView';
import { User, Bot, Loader } from 'lucide-react';
import ReactMarkdown from 'react-markdown';

interface MessageBubbleProps {
  message: Message;
  showSources?: boolean;
}

export const MessageBubble: React.FC<MessageBubbleProps> = ({ message, showSources = true }) => {
  const isUser = message.sender === 'user';
  
  return (
    <div className={`flex ${isUser ? 'justify-end' : 'justify-start'} mb-6`}>
      <div className={`max-w-3xl ${isUser ? 'ml-12' : 'mr-12'}`}>
        <div className={`flex items-start space-x-3 ${isUser ? 'flex-row-reverse space-x-reverse' : ''}`}>
          {/* Avatar */}
          <div className={`flex-shrink-0 w-8 h-8 rounded-full flex items-center justify-center ${
            isUser ? 'bg-mito-blue' : 'bg-gray-200'
          }`}>
            {isUser ? (
              <User className="h-4 w-4 text-white" />
            ) : (
              <Bot className="h-4 w-4 text-gray-600" />
            )}
          </div>
          
          {/* Message content */}
          <div className="flex-1">
            {message.isComparison && message.variantResponses ? (
              // Comparison view for variant responses
              <ComparisonView responses={message.variantResponses} />
            ) : (
              <div className={`rounded-lg p-4 ${
                isUser 
                  ? 'bg-mito-blue text-white' 
                  : 'bg-white border border-gray-200 text-gray-900'
              }`}>
                {message.isLoading ? (
                  <div className="flex items-center space-x-2">
                    <Loader className="h-4 w-4 animate-spin" />
                    <span className="text-sm">{message.text}</span>
                  </div>
                ) : (
                  <div className="prose prose-sm max-w-none">
                    <ReactMarkdown
                      components={{
                        p: ({ children }) => <p className="mb-2 last:mb-0">{children}</p>,
                        strong: ({ children }) => <strong className={isUser ? 'text-blue-100' : 'text-gray-900'}>{children}</strong>,
                        em: ({ children }) => <em className={isUser ? 'text-blue-100' : 'text-gray-700'}>{children}</em>,
                      }}
                    >
                      {message.text}
                    </ReactMarkdown>
                  </div>
                )}
              </div>
            )}
            
            {/* Timestamp */}
            <div className={`mt-1 text-xs text-gray-500 ${isUser ? 'text-right' : 'text-left'}`}>
              {new Intl.DateTimeFormat('sk-SK', {
                hour: '2-digit',
                minute: '2-digit',
              }).format(message.timestamp)}
            </div>
            
            {/* Sources - only show for non-comparison messages */}
            {!message.isComparison && showSources && message.sources && message.sources.length > 0 && (
              <div className="mt-4">
                <h5 className="text-sm font-medium text-gray-700 mb-2">
                  Zdrojové dokumenty:
                </h5>
                <div className="space-y-2">
                  {message.sources.map((source, index) => (
                    <SourceCard key={index} source={source} />
                  ))}
                </div>
              </div>
            )}
          </div>
        </div>
      </div>
    </div>
  );
};