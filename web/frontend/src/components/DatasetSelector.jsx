import React from 'react';
import { useQuery } from '@tanstack/react-query';
import { api } from '../lib/api';

function DatasetSelector({ selectedDataset, onSelectDataset }) {
  const { data: datasets = [], isLoading, error } = useQuery({
    queryKey: ['datasets'],
    queryFn: api.getDatasets,
  });
  
  const { metadata = {} } = useQuery({
    queryKey: ['metadata'],
    queryFn: api.getMetadata,
  });

  if (isLoading) return <div className="card animate-pulse h-40"></div>;
  
  if (error) return (
    <div className="card bg-red-50 border-red-200 text-red-700 p-4">
      <h3 className="font-bold">Error loading datasets</h3>
      <p>{error.message}</p>
    </div>
  );

  return (
    <div className="card">
      <h2 className="text-lg font-semibold mb-4 pb-2 border-b">Datasets</h2>
      {datasets.length === 0 ? (
        <p className="text-gray-500 italic">No datasets available</p>
      ) : (
        <ul className="space-y-1">
          {datasets.map(dataset => {
            const meta = metadata[dataset] || {};
            return (
              <li 
                key={dataset} 
                onClick={() => onSelectDataset(dataset)}
                className={`p-2 rounded cursor-pointer hover:bg-gray-100 transition-colors flex justify-between items-center ${
                  selectedDataset === dataset ? 'bg-blue-50 border-l-4 border-blue-500 pl-2' : ''
                }`}
              >
                <span className="font-medium">{dataset}</span>
                {meta.num_chunks && (
                  <div className="flex space-x-2 text-xs text-gray-500">
                    <span>{meta.num_chunks} chunks</span>
                    <span>{meta.num_questions} questions</span>
                  </div>
                )}
              </li>
            );
          })}
        </ul>
      )}
    </div>
  );
}

export default DatasetSelector;
