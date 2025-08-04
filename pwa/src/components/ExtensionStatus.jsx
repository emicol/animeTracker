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

  const handleDownloadExtension = () => {
    // En développement, pointer vers GitHub
    const downloadUrl = 'https://github.com/emicol/animeTracker/releases/latest/download/anime-tracker-extension-latest.zip';
    window.open(downloadUrl, '_blank');
  };

  const handleInstallGuide = () => {
    const guideUrl = 'https://github.com/emicol/animeTracker/blob/master/docs/EXTENSION_INSTALL.md';
    window.open(guideUrl, '_blank');
  };

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
            <button
              onClick={handleDownloadExtension}
              className="inline-flex items-center px-4 py-2 bg-amber-600 text-white rounded-md hover:bg-amber-700 transition-colors cursor-pointer"
            >
              <ArrowDownTrayIcon className="h-4 w-4 mr-2" />
              Télécharger Extension
            </button>
            
            <button
              onClick={handleInstallGuide}
              className="inline-flex items-center px-4 py-2 bg-gray-600 text-white rounded-md hover:bg-gray-700 transition-colors cursor-pointer"
            >
              📚 Guide d'installation
            </button>
            
            <button
              onClick={checkExtension}
              className="inline-flex items-center px-4 py-2 bg-blue-600 text-white rounded-md hover:bg-blue-700 transition-colors cursor-pointer"
            >
              🔄 Vérifier à nouveau
            </button>
          </div>
          
          <div className="mt-4 p-3 bg-amber-100 rounded-md">
            <p className="text-sm text-amber-800">
              <strong>💡 Instructions rapides :</strong>
            </p>
            <ol className="text-sm text-amber-700 mt-1 space-y-1">
              <li>1. Cliquez "Télécharger Extension" ci-dessus</li>
              <li>2. Décompressez le fichier ZIP téléchargé</li>
              <li>3. Allez dans chrome://extensions/</li>
              <li>4. Activez le "Mode développeur"</li>
              <li>5. Cliquez "Charger extension non empaquetée"</li>
              <li>6. Sélectionnez le dossier décompressé</li>
              <li>7. Visitez Anime-Sama.fr et regardez un anime</li>
              <li>8. Revenez ici pour voir votre historique !</li>
            </ol>
          </div>
          
          <div className="mt-3 p-3 bg-blue-50 rounded-md">
            <p className="text-sm text-blue-800">
              <strong>🔗 Liens utiles :</strong>
            </p>
            <div className="text-sm text-blue-700 mt-1 space-y-1">
              <div>• <a href="https://anime-sama.fr" target="_blank" rel="noopener noreferrer" className="underline hover:text-blue-900">Anime-Sama.fr</a> - Site de streaming</div>
              <div>• <a href="https://github.com/emicol/animeTracker" target="_blank" rel="noopener noreferrer" className="underline hover:text-blue-900">GitHub du projet</a> - Code source</div>
              <div>• <a href="https://github.com/emicol/animeTracker/issues" target="_blank" rel="noopener noreferrer" className="underline hover:text-blue-900">Support</a> - Signaler un problème</div>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};

export default ExtensionStatus;
