import React, { useState, useEffect } from 'react';
import { ExclamationTriangleIcon, CheckCircleIcon, ArrowDownTrayIcon } from '@heroicons/react/24/outline';

const ExtensionStatus = () => {
  const [extensionStatus, setExtensionStatus] = useState({
    connected: false,
    version: null,
    extensionId: null,
    checking: true
  });

  const checkExtension = async () => {
    setExtensionStatus(prev => ({ ...prev, checking: true }));
    
    try {
      // Essayer plusieurs méthodes de détection
      const methods = [
        // Méthode 1: Message direct si extension installée
        () => new Promise((resolve) => {
          if (typeof chrome !== 'undefined' && chrome.runtime) {
            // Envoyer un ping à l'extension
            chrome.runtime.sendMessage(
              { action: 'GET_VERSION' },
              (response) => {
                if (chrome.runtime.lastError) {
                  resolve(null);
                } else {
                  resolve(response);
                }
              }
            );
          } else {
            resolve(null);
          }
        }),
        
        // Méthode 2: Vérifier via postMessage
        () => new Promise((resolve) => {
          const handleMessage = (event) => {
            if (event.data.type === 'EXTENSION_STATUS' && 
                event.data.source === 'anime-tracker-extension') {
              window.removeEventListener('message', handleMessage);
              resolve(event.data);
            }
          };
          
          window.addEventListener('message', handleMessage);
          
          // Demander le statut
          window.postMessage({
            type: 'PWA_REQUEST_STATUS',
            source: 'anime-tracker-pwa'
          }, '*');
          
          // Timeout après 2 secondes
          setTimeout(() => {
            window.removeEventListener('message', handleMessage);
            resolve(null);
          }, 2000);
        })
      ];
      
      // Essayer toutes les méthodes
      for (const method of methods) {
        const result = await method();
        if (result && result.success) {
          setExtensionStatus({
            connected: true,
            version: result.version,
            extensionId: result.extensionId,
            checking: false
          });
          return;
        }
      }
      
      // Aucune méthode n'a fonctionné
      setExtensionStatus({
        connected: false,
        version: null,
        extensionId: null,
        checking: false
      });
      
    } catch (error) {
      console.error('Erreur détection extension:', error);
      setExtensionStatus({
        connected: false,
        version: null,
        extensionId: null,
        checking: false
      });
    }
  };

  useEffect(() => {
    checkExtension();
    
    // Vérifier périodiquement
    const interval = setInterval(checkExtension, 10000); // Toutes les 10 secondes
    
    return () => clearInterval(interval);
  }, []);

  if (extensionStatus.checking) {
    return (
      <div className="bg-blue-50 border border-blue-200 rounded-lg p-4 mb-6">
        <div className="flex items-center">
          <div className="animate-spin rounded-full h-5 w-5 border-b-2 border-blue-600"></div>
          <span className="ml-2 text-blue-700">Vérification de l'extension...</span>
        </div>
      </div>
    );
  }

  if (extensionStatus.connected) {
    return (
      <div className="bg-green-50 border border-green-200 rounded-lg p-4 mb-6">
        <div className="flex items-center justify-between">
          <div className="flex items-center">
            <CheckCircleIcon className="h-5 w-5 text-green-600" />
            <div className="ml-2">
              <span className="text-green-800 font-medium">Extension connectée</span>
              {extensionStatus.version && (
                <span className="text-green-600 text-sm ml-2">v{extensionStatus.version}</span>
              )}
            </div>
          </div>
          <button
            onClick={checkExtension}
            className="text-green-600 hover:text-green-800 text-sm"
          >
            🔄 Actualiser
          </button>
        </div>
      </div>
    );
  }

  return (
    <div className="bg-amber-50 border border-amber-200 rounded-lg p-6 mb-6">
      <div className="flex items-start">
        <ExclamationTriangleIcon className="h-6 w-6 text-amber-600 mt-1" />
        <div className="ml-3 flex-1">
          <h3 className="text-lg font-semibold text-amber-900">
            Extension non connectée
          </h3>
          <p className="text-amber-700 mt-2">
            Installez l'extension Anime History Tracker pour un suivi automatique de vos animes sur Anime-Sama.fr
          </p>
          
          <div className="mt-4 flex flex-wrap gap-3">
            <a
              href="https://github.com/emicol/animeTracker/releases/latest/download/anime-tracker-extension-latest.zip"
              className="inline-flex items-center px-4 py-2 bg-amber-600 text-white rounded-md hover:bg-amber-700 transition-colors"
            >
              <ArrowDownTrayIcon className="h-4 w-4 mr-2" />
              Télécharger Extension
            </a>
            
            <a
              href="https://github.com/emicol/animeTracker/blob/master/docs/EXTENSION_INSTALL.md"
              target="_blank"
              rel="noopener noreferrer"
              className="inline-flex items-center px-4 py-2 bg-gray-600 text-white rounded-md hover:bg-gray-700 transition-colors"
            >
              📚 Guide d'installation
            </a>
            
            <button
              onClick={checkExtension}
              className="inline-flex items-center px-4 py-2 bg-blue-600 text-white rounded-md hover:bg-blue-700 transition-colors"
            >
              🔄 Vérifier à nouveau
            </button>
          </div>
          
          <div className="mt-4 p-3 bg-amber-100 rounded-md">
            <p className="text-sm text-amber-800">
              <strong>💡 Après installation :</strong>
            </p>
            <ol className="text-sm text-amber-700 mt-1 space-y-1">
              <li>1. Visitez Anime-Sama.fr</li>
              <li>2. Regardez un épisode d'anime</li>
              <li>3. Revenez ici pour voir votre historique synchronisé</li>
            </ol>
          </div>
        </div>
      </div>
    </div>
  );
};

export default ExtensionStatus;
