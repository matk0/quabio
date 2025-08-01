import React from 'react';
import { Source } from '../types';
import { ExternalLink, FileText } from 'lucide-react';

interface SourceCardProps {
  source: Source;
}

export const SourceCard: React.FC<SourceCardProps> = ({ source }) => {
  const handleClick = () => {
    if (source.url) {
      window.open(source.url, '_blank');
    }
  };

  return (
    <div 
      className="bg-white border border-gray-200 rounded-lg p-4 hover:shadow-md transition-shadow duration-200 cursor-pointer"
      onClick={handleClick}
    >
      <div className="flex items-start justify-between">
        <div className="flex-1">
          <div className="flex items-center space-x-2 mb-2">
            <FileText className="h-4 w-4 text-mito-blue" />
            <h4 className="font-medium text-gray-900 text-sm line-clamp-2">
              {source.title}
            </h4>
          </div>
          
          <p className="text-gray-600 text-xs line-clamp-3 mb-2">
            {source.excerpt}
          </p>
          
          <div className="flex items-center justify-between">
            <div className="flex items-center space-x-1">
              <div className="w-2 h-2 bg-green-500 rounded-full"></div>
              <span className="text-xs text-gray-500">
                Relevantnosť: {Math.round(source.relevance_score * 100)}%
              </span>
            </div>
            
            {source.url && (
              <ExternalLink className="h-3 w-3 text-gray-400" />
            )}
          </div>
        </div>
      </div>
    </div>
  );
};