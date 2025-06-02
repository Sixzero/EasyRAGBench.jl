import React, { useState } from 'react';
import { useQuery } from '@tanstack/react-query';
import { api } from '../lib/api';

function QuestionViewer({ datasetId }) {
  const [searchTerm, setSearchTerm] = useState('');
  
  const { questions = [], isLoading, error } = useQuery({
    queryKey: ['questions', datasetId],
    queryFn: () => api.getQuestions(datasetId),
    enabled: !!datasetId,
  });

  if (!datasetId) return null;
  
  if (isLoading) return <div className="card animate-pulse h-96"></div>;
  
  if (error) return (
    <div className="card bg-red-50 border-red-200 text-red-700 p-4">
      <h3 className="font-bold">Error loading questions</h3>
      <p>{error.message}</p>
    </div>
  );
  
  // Filter questions based on search term
  const filteredQuestions = questions.filter(q => 
    q.question.toLowerCase().includes(searchTerm.toLowerCase())
  );
  
  return (
    <div className="card h-full overflow-hidden flex flex-col">
      <h2 className="text-lg font-semibold mb-4 pb-2 border-b">Questions</h2>
      
      <div className="mb-4 flex items-center">
        <input
          type="text"
          placeholder="Search questions..."
          value={searchTerm}
          onChange={(e) => setSearchTerm(e.target.value)}
          className="input"
        />
        <span className="ml-2 text-sm text-gray-500">
          Showing {filteredQuestions.length} of {questions.length} questions
        </span>
      </div>
      
      <div className="overflow-y-auto flex-grow">
        {filteredQuestions.length === 0 ? (
          <p className="text-gray-500 italic">No questions found</p>
        ) : (
          <div className="space-y-2">
            {filteredQuestions.map(q => (
              <div key={q.id} className="p-3 border rounded-lg hover:bg-gray-50">
                <p className="text-gray-800">{q.question}</p>
              </div>
            ))}
          </div>
        )}
      </div>
    </div>
  );
}

export default QuestionViewer;
