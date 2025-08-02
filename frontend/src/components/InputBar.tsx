import React, { useState, KeyboardEvent } from 'react';
import { Send } from 'lucide-react';

interface InputBarProps {
  onSend: (message: string) => void;
  disabled?: boolean;
  placeholder?: string;
}

export const InputBar: React.FC<InputBarProps> = ({ 
  onSend, 
  disabled = false, 
  placeholder = "Napíšte vašu otázku..." 
}) => {
  const [message, setMessage] = useState('');

  const handleSend = () => {
    if (message.trim() && !disabled) {
      onSend(message.trim());
      setMessage('');
    }
  };

  const handleKeyPress = (e: KeyboardEvent<HTMLTextAreaElement>) => {
    if (e.key === 'Enter' && !e.shiftKey) {
      e.preventDefault();
      handleSend();
    }
  };

  return (
    <div className="border-t border-gray-200 bg-white p-4 pb-safe">
      <div className="max-w-6xl mx-auto">
        <div className="flex items-end space-x-2 sm:space-x-3">
          <div className="flex-1">
            <textarea
              value={message}
              onChange={(e) => setMessage(e.target.value)}
              onKeyPress={handleKeyPress}
              placeholder={placeholder}
              disabled={disabled}
              rows={1}
              className="w-full px-3 sm:px-4 py-2.5 sm:py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-mito-blue focus:border-transparent resize-none text-base sm:text-sm placeholder:text-gray-400"
              style={{ minHeight: '44px', maxHeight: '120px' }}
            />
          </div>
          
          <button
            onClick={handleSend}
            disabled={disabled || !message.trim()}
            className="flex-shrink-0 w-11 h-11 sm:w-auto sm:h-auto sm:px-4 sm:py-3 bg-mito-blue text-white rounded-lg hover:bg-mito-blue-dark disabled:opacity-50 disabled:cursor-not-allowed transition-colors duration-200 flex items-center justify-center"
          >
            <Send className="h-5 w-5" />
            <span className="hidden sm:inline ml-1 text-sm">Odoslať</span>
          </button>
        </div>
        
        <div className="mt-2 text-xs text-gray-500 text-center">
          <span className="hidden sm:inline">Stlačte Enter pre odoslanie, Shift+Enter pre nový riadok</span>
          <span className="sm:hidden">Enter = odoslať</span>
        </div>
      </div>
    </div>
  );
};