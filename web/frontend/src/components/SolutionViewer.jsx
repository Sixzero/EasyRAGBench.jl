import React, { useState } from 'react';
import { useQuery } from '@tanstack/react-query';
import { api } from '../lib/api';
import CodeMirror from '@uiw/react-codemirror';
import { javascript } from '@codemirror/lang-javascript';

function SolutionViewer({ datasetId, configId }) {
  const [searchTerm, setSearchTerm] = useState('');
  const [expandedQuestion, setExpandedQuestion] = useState(null);
  
  const { solutions = {}, isLoading: solutionsLoading, error: solutionsError } = useQuery({
    queryKey: ['solutions', datasetId, configId],
    queryFn: () => api.getSolutions(datasetId, configId),
    enabled: !!(datasetId && configId),
  });
  
  const { documents = [] } = useQuery({
    queryKey: ['documents', datasetId],
    queryFn: () => api.getDocuments(datasetId),
    enabled: !!datasetId,
  });

  if (!datasetId || !configId) return null;
  
  if (solutionsLoading) return <div className="card animate-pulse h-96"></div>;
  
  if (solutionsError) return (
    <div className="card bg-red-50 border-red-200 text-red-700 p-4">
      <h3 className="font-bold">Error loading solutions</h3>
      <p>{solutionsError.message}</p>
    </div>
  );
  
  // Create a map of document sources for quick lookup
  const documentMap = {};
  documents.forEach(doc => {
    documentMap[doc.source] = doc;
  });
  
  // Filter solutions based on search term
  const filteredSolutions = Object.entries(solutions).filter(([question]) => 
    question.toLowerCase().includes(searchTerm.toLowerCase())
  );
  
  return (
    <div className="card h-full overflow-hidden flex flex-col">
      <h2 className="text-lg font-semibold mb-4 pb-2 border-b">Solutions</h2>
      
      <div className="mb-4 flex items-center">
        <input
          type="text"
          placeholder="Search questions..."
          value={searchTerm}
          onChange={(e) => setSearchTerm(e.target.value)}
          className="input"
        />
        <span className="ml-2 text-sm text-gray-500">
          Showing {filteredSolutions.length} of {Object.keys(solutions).length} solutions
        </span>
      </div>
      
      <div className="overflow-y-auto flex-grow">
        {filteredSolutions.length === 0 ? (
          <p className="text-gray-500 italic">No solutions found</p>
        ) : (
          <div className="space-y-4">
            {filteredSolutions.map(([question, sources]) => (
              <div 
                key={question} 
                className="border rounded-lg overflow-hidden"
              >
                <div 
                  className="flex justify-between items-center p-3 bg-gray-50 cursor-pointer"
                  onClick={() => setExpandedQuestion(expandedQuestion === question ? null : question)}
                >
                  <h3 className="font-medium">{question}</h3>
                  <span className="text-gray-500">
                    {expandedQuestion === question ? '▼' : '►'}
                  </span>
                </div>
                
                {expandedQuestion === question && (
                  <div className="p-3 border-t">
                    <h4 className="font-medium mb-2">Sources ({sources.length})</h4>
                    <div className="space-y-3">
                      {sources.map((source, index) => (
                        <div key={index} className="border rounded overflow-hidden">
                          <div className="px-3 py-2 bg-gray-50 text-sm font-medium">
                            {source}
                          </div>
                          {documentMap[source] && (
                            <CodeMirror
                              value={documentMap[source].text}
                              height="150px"
                              extensions={[javascript()]}
                              theme="light"
                              editable={false}
                              basicSetup={{
                                lineNumbers: false,
                                foldGutter: false,
                              }}
                            />
                          )}
                        </div>
                      ))}
                    </div>
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

export default SolutionViewer;
