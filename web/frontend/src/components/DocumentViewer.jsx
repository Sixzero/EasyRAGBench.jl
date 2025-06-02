import React, { useState } from 'react';
import { useQuery } from '@tanstack/react-query';
import { api } from '../lib/api';
import CodeMirror from '@uiw/react-codemirror';
import { javascript } from '@codemirror/lang-javascript';

function DocumentViewer({ datasetId }) {
  const [searchTerm, setSearchTerm] = useState('');
  const [expandedDocId, setExpandedDocId] = useState(null);
  
  const { data: documents = [], isLoading, error } = useQuery({
    queryKey: ['documents', datasetId],
    queryFn: () => api.getDocuments(datasetId),
    enabled: !!datasetId,
  });

  if (!datasetId) return null;
  
  if (isLoading) return <div className="card animate-pulse h-96"></div>;
  
  if (error) return (
    <div className="card bg-red-50 border-red-200 text-red-700 p-4">
      <h3 className="font-bold">Error loading documents</h3>
      <p>{error.message}</p>
    </div>
  );
  
  // Filter documents based on search term
  const filteredDocs = documents.filter(doc => 
    doc.text.toLowerCase().includes(searchTerm.toLowerCase()) ||
    doc.source.toLowerCase().includes(searchTerm.toLowerCase())
  );
  
  // Display only the first 100 documents to avoid performance issues
  const displayDocs = filteredDocs.slice(0, 100);
  
  return (
    <div className="card h-full overflow-hidden flex flex-col">
      <h2 className="text-lg font-semibold mb-4 pb-2 border-b">Documents</h2>
      
      <div className="mb-4 flex items-center">
        <input
          type="text"
          placeholder="Search documents..."
          value={searchTerm}
          onChange={(e) => setSearchTerm(e.target.value)}
          className="input"
        />
        <span className="ml-2 text-sm text-gray-500">
          Showing {displayDocs.length} of {filteredDocs.length} documents
        </span>
      </div>
      
      <div className="overflow-y-auto flex-grow">
        {displayDocs.length === 0 ? (
          <p className="text-gray-500 italic">No documents found</p>
        ) : (
          <div className="space-y-3">
            {displayDocs.map(doc => (
              <div 
                key={doc.id} 
                className="border rounded-lg overflow-hidden"
              >
                <div 
                  className="flex justify-between items-center p-3 bg-gray-50 cursor-pointer"
                  onClick={() => setExpandedDocId(expandedDocId === doc.id ? null : doc.id)}
                >
                  <h3 className="font-medium">Document {doc.id}</h3>
                  <span className="text-gray-500">
                    {expandedDocId === doc.id ? '▼' : '►'}
                  </span>
                </div>
                <div className="px-3 py-1 text-sm text-gray-600 border-t border-b bg-gray-50">
                  <span className="font-medium">Source:</span> {doc.source}
                </div>
                {expandedDocId === doc.id && (
                  <div className="p-0 border-t">
                    <CodeMirror
                      value={doc.text}
                      height="200px"
                      extensions={[javascript()]}
                      theme="light"
                      editable={false}
                      basicSetup={{
                        lineNumbers: false,
                        foldGutter: false,
                      }}
                    />
                  </div>
                )}
              </div>
            ))}
          </div>
        )}
      </div>
    </div>
  );
}

export default DocumentViewer;
