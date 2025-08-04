// background.js - Service Worker pour l'extension Anime History Tracker
console.log('🎌 Anime History Tracker - Service Worker démarré');

class AnimeStorageManager {
  constructor() {
    this.STORAGE_KEYS = {
      HISTORY: 'anime_history',
      SETTINGS: 'tracker_settings',
      PLANNING: 'anime_planning',
      SERIES_STATUS: 'series_status',
      WATCH_COUNT: 'watch_count'
    };
    
    this.initializeStorage();
    this.setupPlanningSync();
  }
  
  async initializeStorage() {
    try {
      const result = await chrome.storage.local.get([
        this.STORAGE_KEYS.HISTORY,
        this.STORAGE_KEYS.SETTINGS,
        this.STORAGE_KEYS.PLANNING,
        this.STORAGE_KEYS.SERIES_STATUS,
        this.STORAGE_KEYS.WATCH_COUNT
      ]);
      
      // Initialiser avec des valeurs par défaut si nécessaire
      const defaults = {
        [this.STORAGE_KEYS.HISTORY]: [],
        [this.STORAGE_KEYS.SETTINGS]: {
          autoTrack: true,
          minWatchTime: 30000,
          syncWithPWA: true,
          viewModes: {
            default: 'card', // card | list
            itemsPerPage: 50,
            infiniteScroll: true
          }
        },
        [this.STORAGE_KEYS.PLANNING]: {},
        [this.STORAGE_KEYS.SERIES_STATUS]: {},
        [this.STORAGE_KEYS.WATCH_COUNT]: {}
      };
      
      const toSet = {};
      Object.keys(defaults).forEach(key => {
        if (!result[key]) {
          toSet[key] = defaults[key];
        }
      });
      
      if (Object.keys(toSet).length > 0) {
        await chrome.storage.local.set(toSet);
        console.log('📦 Storage initialisé avec valeurs par défaut');
      }
      
    } catch (error) {
      console.error('❌ Erreur initialisation storage:', error);
    }
  }
  
  async saveHistoryEntry(entry) {
    try {
      const result = await chrome.storage.local.get(this.STORAGE_KEYS.HISTORY);
      const history = result[this.STORAGE_KEYS.HISTORY] || [];
      
      // Éviter les doublons (même URL + timestamp proche)
      const existingIndex = history.findIndex(item => 
        item.url === entry.url && 
        Math.abs(item.timestamp - entry.timestamp) < 60000 // 1 minute
      );
      
      if (existingIndex === -1) {
        // Ajouter nouvelle entrée
        const enrichedEntry = {
          ...entry,
          id: this.generateId(),
          addedAt: Date.now()
        };
        
        history.unshift(enrichedEntry);
        
        // Limiter l'historique (garder 1000 entrées max)
        if (history.length > 1000) {
          history.splice(1000);
        }
        
        await chrome.storage.local.set({
          [this.STORAGE_KEYS.HISTORY]: history
        });
        
        // Mettre à jour le compteur de vues
        await this.updateWatchCount(entry);
        
        // Mettre à jour le statut de la série
        await this.updateSeriesStatus(entry);
        
        console.log('💾 Nouvelle entrée historique sauvegardée:', enrichedEntry);
        
        return enrichedEntry;
      } else {
        console.log('⚠️ Entrée déjà existante, ignorée');
        return history[existingIndex];
      }
      
    } catch (error) {
      console.error('❌ Erreur sauvegarde historique:', error);
      throw error;
    }
  }
  
  async updateWatchCount(entry) {
    try {
      const result = await chrome.storage.local.get(this.STORAGE_KEYS.WATCH_COUNT);
      const watchCount = result[this.STORAGE_KEYS.WATCH_COUNT] || {};
      
      const seriesKey = `${entry.animeName}_${entry.season}_${entry.language}`;
      const episodeKey = `${seriesKey}_ep${entry.episode || 'unknown'}`;
      
      if (!watchCount[seriesKey]) {
        watchCount[seriesKey] = {
          totalWatches: 0,
          episodes: {},
          lastWatched: null,
          languages: new Set()
        };
      }
      
      // Incrémenter le compteur pour cet épisode
      if (!watchCount[seriesKey].episodes[episodeKey]) {
        watchCount[seriesKey].episodes[episodeKey] = {
          count: 0,
          lastWatched: null,
          episode: entry.episode,
          language: entry.language
        };
      }
      
      watchCount[seriesKey].episodes[episodeKey].count++;
      watchCount[seriesKey].episodes[episodeKey].lastWatched = entry.timestamp;
      watchCount[seriesKey].totalWatches++;
      watchCount[seriesKey].lastWatched = entry.timestamp;
      watchCount[seriesKey].languages.add(entry.language);
      
      // Convertir Set en Array pour le stockage
      watchCount[seriesKey].languages = Array.from(watchCount[seriesKey].languages);
      
      await chrome.storage.local.set({
        [this.STORAGE_KEYS.WATCH_COUNT]: watchCount
      });
      
    } catch (error) {
      console.error('❌ Erreur mise à jour compteur:', error);
    }
  }
  
  async updateSeriesStatus(entry) {
    try {
      const result = await chrome.storage.local.get(this.STORAGE_KEYS.SERIES_STATUS);
      const seriesStatus = result[this.STORAGE_KEYS.SERIES_STATUS] || {};
      
      const seriesKey = entry.animeName;
      
      if (!seriesStatus[seriesKey]) {
        seriesStatus[seriesKey] = {
          name: entry.displayTitle || entry.animeName,
          seasons: {},
          isCompleted: false,
          totalEpisodes: null,
          lastUpdated: entry.timestamp
        };
      }
      
      const seasonKey = entry.season;
      if (!seriesStatus[seriesKey].seasons[seasonKey]) {
        seriesStatus[seriesKey].seasons[seasonKey] = {
          languages: {},
          totalEpisodes: null,
          isCompleted: false
        };
      }
      
      const languageKey = entry.language;
      if (!seriesStatus[seriesKey].seasons[seasonKey].languages[languageKey]) {
        seriesStatus[seriesKey].seasons[seasonKey].languages[languageKey] = {
          watchedEpisodes: new Set(),
          lastEpisode: null,
          isCompleted: false
        };
      }
      
      // Ajouter l'épisode regardé
      if (entry.episode) {
        seriesStatus[seriesKey].seasons[seasonKey].languages[languageKey].watchedEpisodes.add(entry.episode);
        seriesStatus[seriesKey].seasons[seasonKey].languages[languageKey].lastEpisode = Math.max(
          seriesStatus[seriesKey].seasons[seasonKey].languages[languageKey].lastEpisode || 0,
          entry.episode
        );
      }
      
      // Convertir Set en Array pour le stockage
      Object.keys(seriesStatus).forEach(series => {
        Object.keys(seriesStatus[series].seasons).forEach(season => {
          Object.keys(seriesStatus[series].seasons[season].languages).forEach(lang => {
            seriesStatus[series].seasons[season].languages[lang].watchedEpisodes = 
              Array.from(seriesStatus[series].seasons[season].languages[lang].watchedEpisodes);
          });
        });
      });
      
      seriesStatus[seriesKey].lastUpdated = entry.timestamp;
      
      await chrome.storage.local.set({
        [this.STORAGE_KEYS.SERIES_STATUS]: seriesStatus
      });
      
    } catch (error) {
      console.error('❌ Erreur mise à jour statut série:', error);
    }
  }
  
  async setupPlanningSync() {
    // Synchroniser le planning tous les jours
    chrome.alarms.create('syncPlanning', {
      when: Date.now() + 1000, // 1 seconde après le démarrage
      periodInMinutes: 24 * 60 // Tous les jours
    });
    
    chrome.alarms.onAlarm.addListener(async (alarm) => {
      if (alarm.name === 'syncPlanning') {
        await this.syncPlanningData();
      }
    });
  }
  
  async syncPlanningData() {
    try {
      console.log('🔄 Synchronisation du planning...');
      
      // Créer un onglet en arrière-plan pour scraper le planning
      const tab = await chrome.tabs.create({
        url: 'https://anime-sama.fr/planning',
        active: false
      });
      
      // Attendre que la page soit chargée puis extraire les données
      setTimeout(async () => {
        try {
          await chrome.scripting.executeScript({
            target: { tabId: tab.id },
            function: this.extractPlanningData
          });
        } catch (error) {
          console.error('❌ Erreur extraction planning:', error);
        } finally {
          // Fermer l'onglet
          chrome.tabs.remove(tab.id);
        }
      }, 3000);
      
    } catch (error) {
      console.error('❌ Erreur sync planning:', error);
    }
  }
  
  // Fonction injectée pour extraire les données du planning
  extractPlanningData() {
    const planningData = {
      lastUpdated: Date.now(),
      days: {}
    };
    
    // Extraire pour chaque jour (0-6)
    for (let day = 0; day <= 6; day++) {
      const dayElement = document.getElementById(day.toString());
      if (dayElement) {
        const animes = [];
        const scans = [];
        
        // Chercher tous les éléments d'anime/scan dans ce jour
        const cards = dayElement.querySelectorAll('.divOeuvrePlanning');
        
        cards.forEach(card => {
          const link = card.querySelector('a');
          const img = card.querySelector('img');
          const title = card.querySelector('h1');
          
          if (link && img && title && !link.href.includes('planning')) {
            const item = {
              title: title.textContent.trim(),
              url: link.href,
              image: img.src,
              type: link.href.includes('/scan/') ? 'scan' : 'anime'
            };
            
            if (item.type === 'anime') {
              animes.push(item);
            } else {
              scans.push(item);
            }
          }
        });
        
        planningData.days[day] = { animes, scans };
      }
    }
    
    // Sauvegarder via message au service worker
    chrome.runtime.sendMessage({
      action: 'SAVE_PLANNING_DATA',
      data: planningData
    });
  }
  
  generateId() {
    return Date.now().toString(36) + Math.random().toString(36).substr(2);
  }
  
  async getHistory(filters = {}) {
    try {
      const result = await chrome.storage.local.get(this.STORAGE_KEYS.HISTORY);
      let history = result[this.STORAGE_KEYS.HISTORY] || [];
      
      // Appliquer les filtres
      if (filters.animeName) {
        history = history.filter(item => 
          item.animeName.toLowerCase().includes(filters.animeName.toLowerCase())
        );
      }
      
      if (filters.language) {
        history = history.filter(item => item.language === filters.language);
      }
      
      if (filters.dateFrom) {
        history = history.filter(item => item.timestamp >= filters.dateFrom);
      }
      
      if (filters.dateTo) {
        history = history.filter(item => item.timestamp <= filters.dateTo);
      }
      
      return history;
    } catch (error) {
      console.error('❌ Erreur récupération historique:', error);
      return [];
    }
  }
  
  async updateEpisodeWatchCount(animeName, season, language, episode, newCount) {
    try {
      const result = await chrome.storage.local.get(this.STORAGE_KEYS.WATCH_COUNT);
      const watchCount = result[this.STORAGE_KEYS.WATCH_COUNT] || {};
      
      const seriesKey = `${animeName}_${season}_${language}`;
      const episodeKey = `${seriesKey}_ep${episode}`;
      
      if (watchCount[seriesKey] && watchCount[seriesKey].episodes[episodeKey]) {
        const oldCount = watchCount[seriesKey].episodes[episodeKey].count;
        const difference = newCount - oldCount;
        
        watchCount[seriesKey].episodes[episodeKey].count = newCount;
        watchCount[seriesKey].totalWatches += difference;
        
        await chrome.storage.local.set({
          [this.STORAGE_KEYS.WATCH_COUNT]: watchCount
        });
        
        console.log(`📊 Mise à jour compteur: ${episodeKey} = ${newCount}`);
        return true;
      }
      
      return false;
    } catch (error) {
      console.error('❌ Erreur mise à jour compteur manuel:', error);
      return false;
    }
  }
}

// Initialiser le gestionnaire de stockage
const storageManager = new AnimeStorageManager();

// Écouter les messages des content scripts et de la PWA
chrome.runtime.onMessage.addListener((message, sender, sendResponse) => {
  console.log('📨 Message reçu:', message.action);
  
  switch (message.action) {
    case 'SAVE_HISTORY':
      storageManager.saveHistoryEntry(message.data)
        .then(entry => sendResponse({ success: true, entry }))
        .catch(error => sendResponse({ success: false, error: error.message }));
      return true; // Indique une réponse asynchrone
      
    case 'GET_HISTORY':
      storageManager.getHistory(message.filters || {})
        .then(history => sendResponse({ success: true, history }))
        .catch(error => sendResponse({ success: false, error: error.message }));
      return true;
      
    case 'UPDATE_WATCH_COUNT':
      storageManager.updateEpisodeWatchCount(
        message.data.animeName,
        message.data.season,
        message.data.language,
        message.data.episode,
        message.data.count
      )
        .then(success => sendResponse({ success }))
        .catch(error => sendResponse({ success: false, error: error.message }));
      return true;
      
    case 'SAVE_PLANNING_DATA':
      chrome.storage.local.set({
        [storageManager.STORAGE_KEYS.PLANNING]: message.data
      })
        .then(() => {
          console.log('📅 Planning synchronisé');
          sendResponse({ success: true });
        })
        .catch(error => sendResponse({ success: false, error: error.message }));
      return true;
      
    case 'GET_SERIES_STATUS':
      chrome.storage.local.get(storageManager.STORAGE_KEYS.SERIES_STATUS)
        .then(result => sendResponse({ 
          success: true, 
          seriesStatus: result[storageManager.STORAGE_KEYS.SERIES_STATUS] || {} 
        }))
        .catch(error => sendResponse({ success: false, error: error.message }));
      return true;
      
    case 'GET_WATCH_COUNT':
      chrome.storage.local.get(storageManager.STORAGE_KEYS.WATCH_COUNT)
        .then(result => sendResponse({ 
          success: true, 
          watchCount: result[storageManager.STORAGE_KEYS.WATCH_COUNT] || {} 
        }))
        .catch(error => sendResponse({ success: false, error: error.message }));
      return true;
      
    default:
      sendResponse({ success: false, error: 'Action inconnue' });
  }
});

// Écouter les messages externes (PWA)
chrome.runtime.onMessageExternal.addListener((message, sender, sendResponse) => {
  console.log('🌐 Message externe reçu:', message.action);
  
  // Rediriger vers le gestionnaire de messages interne
  chrome.runtime.onMessage.trigger(message, sender, sendResponse);
});

console.log('✅ Service Worker Anime History Tracker prêt');
