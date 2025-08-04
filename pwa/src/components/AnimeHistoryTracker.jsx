import ExtensionStatus from './ExtensionStatus';
import React from 'react';
import ExtensionStatus from './ExtensionStatus';

const AnimeHistoryTracker = () => {
  return (
    <div className="max-w-6xl mx-auto p-6">
      <div className="mb-8">
        <h1 className="text-3xl font-bold text-gray-900 mb-2">
          🎌 Anime History Tracker
        </h1>
        <p className="text-gray-600">
          Suivez votre progression anime avec des statistiques détaillées
        </p>
      </div>
      
      <ExtensionStatus />
      
      <div className="bg-white rounded-lg shadow-md p-6">
        <h2 className="text-xl font-semibold text-gray-900 mb-4">
          📊 Votre historique d'animes
        </h2>
        <p className="text-gray-600 mb-6">
          Une fois l'extension installée et que vous aurez regardé des animes, 
          votre historique apparaîtra ici automatiquement.
        </p>
        
        <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
          <div className="p-4 bg-gray-50 rounded-lg text-center">
            <div className="text-2xl mb-2">📺</div>
            <div className="font-medium text-gray-900">Tracking Auto</div>
            <div className="text-sm text-gray-600">Détection des épisodes regardés</div>
          </div>
          
          <div className="p-4 bg-gray-50 rounded-lg text-center">
            <div className="text-2xl mb-2">📊</div>
            <div className="font-medium text-gray-900">Statistiques</div>
            <div className="text-sm text-gray-600">Temps, compteurs, progression</div>
          </div>
          
          <div className="p-4 bg-gray-50 rounded-lg text-center">
            <div className="text-2xl mb-2">🔄</div>
            <div className="font-medium text-gray-900">Synchronisation</div>
            <div className="text-sm text-gray-600">Multi-plateforme</div>
          </div>
        </div>
      </div>
    </div>
  );
};

export default AnimeHistoryTracker;
