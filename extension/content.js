// content.js - Anime-Sama Video History Tracker
console.log('🎌 Anime History Tracker - Content Script Loaded');

class AnimeTracker {
  constructor() {
    this.currentEntry = null;
    this.watchStartTime = null;
    this.minWatchTime = 30000; // 30 secondes minimum
    this.isTracking = false;
    
    this.init();
  }
  
  init() {
    // Attendre que la page soit complètement chargée
    if (document.readyState === 'loading') {
      document.addEventListener('DOMContentLoaded', () => this.startTracking());
    } else {
      this.startTracking();
    }
  }
  
  startTracking() {
    try {
      const pageData = this.extractPageData();
      
      if (pageData && this.isValidAnimePage(pageData)) {
        console.log('📺 Page anime détectée:', pageData);
        this.currentEntry = pageData;
        this.watchStartTime = Date.now();
        this.isTracking = true;
        
        // Observer les changements de player vidéo
        this.observeVideoPlayer();
        
        // Sauvegarder au bout de 30 secondes
        setTimeout(() => {
          if (this.isTracking) {
            this.saveViewingHistory();
          }
        }, this.minWatchTime);
        
        // Sauvegarder lors de la fermeture/navigation
        this.setupUnloadHandler();
      }
    } catch (error) {
      console.error('❌ Erreur tracking:', error);
    }
  }
  
  extractPageData() {
    const url = window.location.href;
    const path = window.location.pathname;
    
    // Vérifier si c'est une page de catalogue anime
    const catalogueMatch = path.match(/^\/catalogue\/([^\/]+)\/([^\/]+)\/([^\/]+)\/?/);
    
    if (!catalogueMatch) return null;
    
    const [, animeName, seasonInfo, language] = catalogueMatch;
    
    // Extraire les données de la page
    const titleElement = document.querySelector('h1, title, .anime-title');
    const displayTitle = titleElement ? 
      titleElement.textContent.trim() : 
      this.formatAnimeName(animeName);
    
    // Détecter l'épisode depuis différentes sources
    const episodeNumber = this.detectEpisodeNumber();
    
    // Extraire l'image depuis les métadonnées ou le DOM
    const imageUrl = this.extractImageUrl();
    
    return {
      animeName: animeName,
      displayTitle: displayTitle,
      season: seasonInfo,
      language: language.toUpperCase(),
      episode: episodeNumber,
      url: url,
      imageUrl: imageUrl,
      timestamp: Date.now(),
      domain: 'anime-sama.fr'
    };
  }
  
  detectEpisodeNumber() {
    // Méthode 1: Depuis l'URL ou les paramètres
    const urlParams = new URLSearchParams(window.location.search);
    const episodeFromUrl = urlParams.get('episode') || urlParams.get('ep');
    
    if (episodeFromUrl) {
      return parseInt(episodeFromUrl);
    }
    
    // Méthode 2: Depuis le titre de la page
    const title = document.title;
    const episodeMatch = title.match(/(?:episode|ep|épisode)\s*(\d+)/i);
    if (episodeMatch) {
      return parseInt(episodeMatch[1]);
    }
    
    // Méthode 3: Depuis le player ou les contrôles
    const playerSelectors = [
      '.episode-number',
      '.current-episode',
      '[data-episode]',
      '.episode-info'
    ];
    
    for (const selector of playerSelectors) {
      const element = document.querySelector(selector);
      if (element) {
        const episodeText = element.textContent || element.dataset.episode;
        const match = episodeText.match(/(\d+)/);
        if (match) {
          return parseInt(match[1]);
        }
      }
    }
    
    // Méthode 4: Depuis les scripts de la page (comme episodes.js)
    const scriptEpisode = this.extractEpisodeFromScripts();
    if (scriptEpisode) {
      return scriptEpisode;
    }
    
    return null;
  }
  
  extractEpisodeFromScripts() {
    try {
      // Chercher dans les variables globales créées par episodes.js
      if (window.currentEpisode) {
        return parseInt(window.currentEpisode);
      }
      
      // Chercher dans localStorage (anime-sama utilise souvent ça)
      const localStorageKeys = ['currentEpisode', 'lastEpisode', 'episode'];
      for (const key of localStorageKeys) {
        const value = localStorage.getItem(key);
        if (value && !isNaN(parseInt(value))) {
          return parseInt(value);
        }
      }
      
      return null;
    } catch (error) {
      console.warn('⚠️ Erreur extraction épisode depuis scripts:', error);
      return null;
    }
  }
  
  extractImageUrl() {
    // Priorité aux métadonnées Open Graph
    const ogImage = document.querySelector('meta[property="og:image"]');
    if (ogImage) {
      return ogImage.content;
    }
    
    // Image principale de l'anime
    const mainImage = document.querySelector('.anime-poster, .anime-image, .cover-image img');
    if (mainImage) {
      return mainImage.src;
    }
    
    // Image par défaut basée sur le nom de l'anime
    const animeName = this.currentEntry?.animeName;
    if (animeName) {
      return `https://cdn.statically.io/gh/Anime-Sama/IMG/img/contenu/${animeName}.jpg`;
    }
    
    return null;
  }
  
  formatAnimeName(rawName) {
    return rawName
      .split('-')
      .map(word => word.charAt(0).toUpperCase() + word.slice(1))
      .join(' ');
  }
  
  isValidAnimePage(data) {
    return data && 
           data.animeName && 
           data.season && 
           data.language &&
           window.location.pathname.includes('/catalogue/');
  }
  
  observeVideoPlayer() {
    // Observer le player vidéo pour détecter la lecture
    const videoSelectors = ['video', 'iframe[src*="player"]', '.video-player'];
    
    videoSelectors.forEach(selector => {
      const elements = document.querySelectorAll(selector);
      elements.forEach(element => {
        if (element.tagName === 'VIDEO') {
          element.addEventListener('play', () => {
            console.log('▶️ Lecture vidéo détectée');
            this.isTracking = true;
          });
          
          element.addEventListener('pause', () => {
            console.log('⏸️ Vidéo en pause');
          });
        }
      });
    });
  }
  
  setupUnloadHandler() {
    const saveOnExit = () => {
      if (this.isTracking && this.watchStartTime) {
        const watchDuration = Date.now() - this.watchStartTime;
        if (watchDuration >= this.minWatchTime) {
          this.saveViewingHistory();
        }
      }
    };
    
    window.addEventListener('beforeunload', saveOnExit);
    window.addEventListener('pagehide', saveOnExit);
    
    // Observer les changements de navigation SPA
    const observer = new MutationObserver((mutations) => {
      mutations.forEach((mutation) => {
        if (mutation.type === 'childList' && 
            window.location.href !== this.currentEntry?.url) {
          saveOnExit();
        }
      });
    });
    
    observer.observe(document.body, {
      childList: true,
      subtree: true
    });
  }
  
  async saveViewingHistory() {
    if (!this.currentEntry) return;
    
    try {
      // Enrichir les données avec la durée de visionnage
      const enrichedEntry = {
        ...this.currentEntry,
        watchDuration: this.watchStartTime ? Date.now() - this.watchStartTime : 0,
        completedAt: Date.now()
      };
      
      console.log('💾 Sauvegarde historique:', enrichedEntry);
      
      // Sauvegarder via l'extension
      await this.sendToBackground('SAVE_HISTORY', enrichedEntry);
      
      // Notifier la PWA si connectée
      this.notifyPWA(enrichedEntry);
      
      this.isTracking = false;
      
    } catch (error) {
      console.error('❌ Erreur sauvegarde:', error);
    }
  }
  
  async sendToBackground(action, data) {
    return new Promise((resolve, reject) => {
      chrome.runtime.sendMessage({
        action: action,
        data: data,
        timestamp: Date.now()
      }, (response) => {
        if (chrome.runtime.lastError) {
          reject(chrome.runtime.lastError);
        } else {
          resolve(response);
        }
      });
    });
  }
  
  notifyPWA(data) {
    // Envoyer les données à la PWA via postMessage si elle est ouverte
    try {
      const pwaOrigins = [
        'https://localhost:3000',
        'https://*.github.io'
      ];
      
      window.postMessage({
        type: 'ANIME_HISTORY_UPDATE',
        source: 'anime-tracker-extension',
        data: data
      }, '*');
      
    } catch (error) {
      console.warn('⚠️ Erreur notification PWA:', error);
    }
  }
}

// Initialiser le tracker
const tracker = new AnimeTracker();

// Écouter les messages de la PWA
window.addEventListener('message', (event) => {
  if (event.data.type === 'PWA_REQUEST_HISTORY') {
    // La PWA demande l'historique
    tracker.sendToBackground('GET_HISTORY', {})
      .then(history => {
        window.postMessage({
          type: 'ANIME_HISTORY_DATA',
          source: 'anime-tracker-extension',
          data: history
        }, '*');
      });
  }
});

console.log('✅ Anime History Tracker initialisé');
