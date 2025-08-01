import React from 'react';
import { Dna } from 'lucide-react';

interface HeaderProps {
  onClearChat: () => void;
}

export const Header: React.FC<HeaderProps> = ({ onClearChat }) => {
  return (
    <header className="bg-mito-blue text-white p-4 shadow-lg">
      <div className="max-w-6xl mx-auto flex items-center justify-between">
        <div className="flex items-center space-x-3">
          <Dna className="h-8 w-8" />
          <div>
            <h1 className="text-2xl font-bold">Miťo</h1>
            <p className="text-blue-100 text-sm">
              Váš slovenský zdravotný asistent
            </p>
          </div>
        </div>

        <button
          onClick={onClearChat}
          className="px-4 py-2 bg-blue-600 hover:bg-blue-700 rounded-lg transition-colors duration-200 text-sm font-medium"
        >
          Vymazať konverzáciu
        </button>
      </div>
    </header>
  );
};
