import React from 'react';
import { useQuery } from '@tanstack/react-query';
import { api } from '../lib/api';

function ConfigSelector({ datasetId, selectedConfig, onSelectConfig }) {
  const { configs = [], isLoading, error } = useQuery({
    queryKey: ['configs', datasetId],
    queryFn: () => api.getConfigs(datasetId),
    enabled: !!datasetId,
  });

  if (!datasetId) return null;
  
  if (isLoading) return <div className="card animate-pulse h-40"></div>;
  
  if (error) return (
    <div className="card bg-red-50 border-red-200 text-red-700 p-4">
      <h3 className="font-bold">Error loading configurations</h3>
      <p>{error.message}</p>
    </div>
  );

  return (
    <div className="card mt-4">
      <h2 className="text-lg font-semibold mb-4 pb-2 border-b">Configurations</h2>
      {configs.length === 0 ? (
        <p className="text-gray-500 italic">No configurations available</p>
      ) : (
        <ul className="space-y-1">
          {configs.map(config => (
            <li 
              key={config} 
              onClick={() => onSelectConfig(config)}
              className={`p-2 rounded cursor-pointer hover:bg-gray-100 transition-colors ${
                selectedConfig === config ? 'bg-blue-50 border-l-4 border-blue-500 pl-2' : ''
              }`}
            >
              {config}
            </li>
          ))}
        </ul>
      )}
    </div>
  );
}

export default ConfigSelector;
