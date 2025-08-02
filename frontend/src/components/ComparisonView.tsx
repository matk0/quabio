import React from 'react';
import { VariantResponse } from '../types';
import { SourceCard } from './SourceCard';
import ReactMarkdown from 'react-markdown';

interface ComparisonViewProps {
  responses: VariantResponse[];
}

export const ComparisonView: React.FC<ComparisonViewProps> = ({ responses }) => {
  return (
    <div className="w-full">
      {/* Horizontal layout container */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-4">
        {responses.map((variantResponse, index) => (
          <div
            key={index}
            className="border border-gray-200 rounded-lg bg-white shadow-sm overflow-hidden"
          >
            {/* Variant Header */}
            <div className="bg-gray-50 px-4 py-3 border-b border-gray-200">
              <div className="flex justify-between items-center">
                <h3 className="font-semibold text-gray-800">
                  {variantResponse.variant_name}
                </h3>
                <span className="text-xs text-gray-500 bg-gray-100 px-2 py-1 rounded">
                  {variantResponse.processing_time.toFixed(2)}s
                </span>
              </div>
            </div>
            
            {/* Response Content */}
            <div className="p-4">
              <div className="prose prose-sm max-w-none mb-4">
                <ReactMarkdown
                  components={{
                    p: ({ children }) => <p className="mb-2 last:mb-0 text-gray-700">{children}</p>,
                    strong: ({ children }) => <strong className="text-gray-900">{children}</strong>,
                    em: ({ children }) => <em className="text-gray-600">{children}</em>,
                  }}
                >
                  {variantResponse.response}
                </ReactMarkdown>
              </div>
              
              {/* Sources */}
              {variantResponse.sources && variantResponse.sources.length > 0 && (
                <div className="pt-4 border-t border-gray-100">
                  <h4 className="text-sm font-medium text-gray-700 mb-3">
                    Zdroje ({variantResponse.sources.length}):
                  </h4>
                  <div className="space-y-2">
                    {variantResponse.sources.map((source, sourceIndex) => (
                      <div key={sourceIndex} className="transform scale-95 origin-left">
                        <SourceCard source={source} />
                      </div>
                    ))}
                  </div>
                </div>
              )}
            </div>
          </div>
        ))}
      </div>
      
      {/* Comparison hint on smaller screens */}
      <div className="mt-4 text-center text-xs text-gray-500 lg:hidden">
        ↔ Potiahnite pre porovnanie odpovedí
      </div>
    </div>
  );
};