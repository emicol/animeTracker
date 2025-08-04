import React, { useState, useEffect, useMemo, useCallback, useRef } from 'react';
import { ChevronDownIcon, ChevronUpIcon, MagnifyingGlassIcon, CalendarIcon, PlayIcon, EyeIcon, Squares2X2Icon, ListBulletIcon, PlusIcon, MinusIcon, CheckCircleIcon, ClockIcon } from '@heroicons/react/24/outline';

// Composant Virtual Scroll pour les performances
const VirtualScrollContainer = ({ items, renderItem, itemHeight = 120, containerHeight = 600 }) => {
  const [scrollTop, setScrollTop] = useState(0);
  const containerRef = useRef();
  
  const visibleStart = Math.floor(scrollTop / itemHeight);
  const visibleEnd = Math.min(visibleStart + Math.ceil(containerHeight / itemHeight) + 1, items.length);
  const visibleItems = items.slice(visibleStart, visibleEnd);
  
  const totalHeight = items.length * itemHeight;
  const offsetY = visibleStart * itemHeight;
  
  const handleScroll = useCallback((e) => {
    setScrollTop(e.target.scrollTop);
  }, []);
  
  return (
    <div 
      ref={containerRef}
      className="overflow-auto"
      style={{ height: containerHeight }}
      onScroll={handleScroll}
    >
      <div style={{ height: totalHeight, position: 'relative' }}>
        <div style={{ transform: `translateY(${offsetY}px)` }}>
          {visibleItems.map((item, index) => 
            renderItem(item, visibleStart + index)
          )}
        </div>
      </div>
    </div>
  );
};

// Hook personnalisé pour la communication avec l'extension
const useAnimeExtension = () => {
  const [isExtensionConnected, setIsExtensionConnected] = useState(false);
  const [history, setHistory] = useState([]);
  const [watchCount, setWatchCount] = useState({});
  const [seriesStatus, setSeriesStatus] = useState({});
  const [planning, setPlanning] = useState({});
  
  const checkExtensionConnection = useCallback(async () => {
    try {
      if (typeof chrome !== 'undefined' && chrome.runtime) {
        const response = await new Promise((resolve) => {
          chrome.runtime.sendMessage('extension-id-here', 
            { action: 'PING' }, 
            resolve
          );
        });
        setIsExtensionConnected(!!response);
      }
    } catch (error) {
      setIsExtensionConnected(false);
    }
  }, []);
  
  const loadData = useCallback(async () => {
    if (!isExtensionConnected) return;
    
    try {
      // Charger l'historique
      const historyResponse = await new Promise((resolve) => {
        chrome.runtime.sendMessage('extension-id-here', 
          { action: 'GET_HISTORY' }, 
          resolve
        );
      });
      
      if (historyResponse?.success) {
        setHistory(historyResponse.history);
      }
      
      // Charger les compteurs
      const countResponse = await new Promise((resolve) => {
        chrome.runtime.sendMessage('extension-id-here', 
          { action: 'GET_WATCH_COUNT' }, 
          resolve
        );
      });
      
      if (countResponse?.success) {
        setWatchCount(countResponse.watchCount);
      }
      
      // Charger le statut des séries
      const statusResponse = await new Promise((resolve) => {
        chrome.runtime.sendMessage('extension-id-here', 
          { action: 'GET_SERIES_STATUS' }, 
          resolve
        );
      });
      
      if (statusResponse?.success) {
        setSeriesStatus(statusResponse.seriesStatus);
      }
      
    } catch (error) {
      console.error('Erreur chargement données:', error);
    }
  }, [isExtensionConnected]);
  
  const updateWatchCount = useCallback(async (animeName, season, language, episode, newCount) => {
    if (!isExtensionConnected) return false;
    
    try {
      const response = await new Promise((resolve) => {
        chrome.runtime.sendMessage('extension-id-here', {
          action: 'UPDATE_WATCH_COUNT',
          data: { animeName, season, language, episode, count: newCount }
        }, resolve);
      });
      
      if (response?.success) {
        await loadData(); // Recharger les données
        return true;
      }
      return false;
    } catch (error) {
      console.error('Erreur mise à jour compteur:', error);
      return false;
    }
  }, [isExtensionConnected, loadData]);
  
  useEffect(() => {
    checkExtensionConnection();
    const interval = setInterval(checkExtensionConnection, 5000);
    return () => clearInterval(interval);
  }, [checkExtensionConnection]);
  
  useEffect(() => {
    if (isExtensionConnected) {
      loadData();
    }
  }, [isExtensionConnected, loadData]);
  
  // Écouter les messages de l'extension
  useEffect(() => {
    const handleMessage = (event) => {
      if (event.data.type === 'ANIME_HISTORY_UPDATE' && 
          event.data.source === 'anime-tracker-extension') {
        loadData();
      }
    };
    
    window.addEventListener('message', handleMessage);
    return () => window.removeEventListener('message', handleMessage);
  }, [loadData]);
  
  return {
    isExtensionConnected,
    history,
    watchCount,
    seriesStatus,
    planning,
    updateWatchCount,
    refreshData: loadData
  };
};

// Hook pour l'infinite scroll
const useInfiniteScroll = (items, itemsPerPage = 50) => {
  const [displayedItems, setDisplayedItems] = useState([]);
  const [hasMore, setHasMore] = useState(true);
  const [loading, setLoading] = useState(false);
  
  const loadMoreItems = useCallback(() => {
    if (loading || !hasMore) return;
    
    setLoading(true);
    
    setTimeout(() => {
      const currentLength = displayedItems.length;
      const nextItems = items.slice(currentLength, currentLength + itemsPerPage);
      
      setDisplayedItems(prev => [...prev, ...nextItems]);
      setHasMore(currentLength + nextItems.length < items.length);
      setLoading(false);
    }, 300);
  }, [items, displayedItems.length, itemsPerPage, loading, hasMore]);
  
  useEffect(() => {
    setDisplayedItems(items.slice(0, itemsPerPage));
    setHasMore(items.length > itemsPerPage);
  }, [items, itemsPerPage]);
  
  return { displayedItems, hasMore, loading, loadMoreItems };
};

const AnimeHistoryTracker = () => {
  // États principaux
  const [viewMode, setViewMode] = useState('card');
  const [searchQuery, setSearchQuery] = useState('');
  const [filters, setFilters] = useState({
    language: '',
    status: '',
    dateRange: ''
  });
  const [sortBy, setSortBy] = useState('timestamp');
  const [sortOrder, setSortOrder] = useState('desc');
  
  const {
    isExtensionConnected,
    history,
    watchCount,
    seriesStatus,
    planning,
    updateWatchCount,
    refreshData
  } = useAnimeExtension();
  
  // Données filtrées et triées
  const processedHistory = useMemo(() => {
    let filtered = history.filter(item => {
      if (searchQuery && !item.displayTitle.toLowerCase().includes(searchQuery.toLowerCase())) {
        return false;
      }
      if (filters.language && item.language !== filters.language) {
        return false;
      }
      if (filters.status) {
        const seriesKey = item.animeName;
        const series = seriesStatus[seriesKey];
        if (filters.status === 'completed' && (!series || !series.isCompleted)) {
          return false;
        }
        if (filters.status === 'ongoing' && series && series.isCompleted) {
          return false;
        }
      }
      return true;
    });
    
    // Tri
    filtered.sort((a, b) => {
      let aValue = a[sortBy];
      let bValue = b[sortBy];
      
      if (sortBy === 'timestamp') {
        return sortOrder === 'desc' ? bValue - aValue : aValue - bValue;
      }
      
      if (typeof aValue === 'string') {
        aValue = aValue.toLowerCase();
        bValue = bValue.toLowerCase();
      }
      
      if (sortOrder === 'desc') {
        return aValue < bValue ? 1 : -1;
      }
      return aValue > bValue ? 1 : -1;
    });
    
    return filtered;
  }, [history, searchQuery, filters, sortBy, sortOrder, seriesStatus]);
  
  const { displayedItems, hasMore, loading, loadMoreItems } = useInfiniteScroll(processedHistory);
  
  // Données agrégées pour les statistiques
  const stats = useMemo(() => {
    const totalEntries = history.length;
    const uniqueSeries = new Set(history.map(item => item.animeName)).size;
    const languages = Object.keys(
      history.reduce((acc, item) => {
        acc[item.language] = (acc[item.language] || 0) + 1;
        return acc;
      }, {})
    );
    
    const totalWatchTime = history.reduce((acc, item) => acc + (item.watchDuration || 0), 0);
    
    return {
      totalEntries,
      uniqueSeries,
      languages,
      totalWatchTime
    };
  }, [history]);
  
  // Fonction pour obtenir le jour de sortie d'un anime
  const getReleaseDay = useCallback((animeName) => {
    const days = ['Dimanche', 'Lundi', 'Mardi', 'Mercredi', 'Jeudi', 'Vendredi', 'Samedi'];
    
    for (const [dayIndex, dayData] of Object.entries(planning.days || {})) {
      const animes = dayData.animes || [];
      if (animes.some(anime => anime.title.toLowerCase().includes(animeName.toLowerCase()))) {
        return days[parseInt(dayIndex)];
      }
    }
    return null;
  }, [planning]);
  
  // Composant carte d'anime
  const AnimeCard = ({ item, index }) => {
    const [episodeCount, setEpisodeCount] = useState(1);
    const [showCountEditor, setShowCountEditor] = useState(false);
    
    const seriesKey = `${item.animeName}_${item.season}_${item.language}`;
    const episodeKey = `${seriesKey}_ep${item.episode || 'unknown'}`;
    const currentCount = watchCount[seriesKey]?.episodes[episodeKey]?.count || 1;
    const releaseDay = getReleaseDay(item.animeName);
    
    const handleUpdateCount = async () => {
      const success = await updateWatchCount(
        item.animeName, 
        item.season, 
        item.language, 
        item.episode, 
        episodeCount
      );
      
      if (success) {
        setShowCountEditor(false);
      }
    };
    
    return (
      <div className="bg-white rounded-lg shadow-md p-4 hover:shadow-lg transition-shadow">
        <div className="flex items-start space-x-4">
          {/* Image */}
          <div className="flex-shrink-0">
            <img 
              src={item.imageUrl || `https://cdn.statically.io/gh/Anime-Sama/IMG/img/contenu/${item.animeName}.jpg`}
              alt={item.displayTitle}
              className="w-16 h-24 object-cover rounded"
              loading="lazy"
            />
          </div>
          
          {/* Contenu */}
          <div className="flex-1 min-w-0">
            <h3 className="text-lg font-semibold text-gray-900 truncate">
              {item.displayTitle}
            </h3>
            
            <div className="flex items-center space-x-2 mt-1">
              <span className="text-sm text-gray-500">{item.season}</span>
              <span className="px-2 py-1 text-xs font-medium bg-blue-100 text-blue-800 rounded">
                {item.language}
              </span>
              {item.episode && (
                <span className="px-2 py-1 text-xs font-medium bg-green-100 text-green-800 rounded">
                  Ép. {item.episode}
                </span>
              )}
            </div>
            
            {releaseDay && (
              <div className="flex items-center mt-2 text-sm text-gray-600">
                <CalendarIcon className="w-4 h-4 mr-1" />
                Sort le {releaseDay}
              </div>
            )}
            
            <div className="flex items-center mt-2 text-sm text-gray-500">
              <ClockIcon className="w-4 h-4 mr-1" />
              {new Date(item.timestamp).toLocaleDateString('fr-FR')}
              {item.watchDuration && (
                <span className="ml-2">
                  • {Math.round(item.watchDuration / 60000)}min
                </span>
              )}
            </div>
            
            {/* Compteur de vues */}
            <div className="flex items-center mt-3 space-x-2">
              <EyeIcon className="w-4 h-4 text-gray-400" />
              <span className="text-sm text-gray-600">Vu {currentCount} fois</span>
              
              {!showCountEditor ? (
                <button
                  onClick={() => {
                    setEpisodeCount(currentCount);
                    setShowCountEditor(true);
                  }}
                  className="text-xs text-blue-600 hover:text-blue-800"
                >
                  Modifier
                </button>
              ) : (
                <div className="flex items-center space-x-1">
                  <button
                    onClick={() => setEpisodeCount(Math.max(0, episodeCount - 1))}
                    className="w-6 h-6 flex items-center justify-center bg-gray-200 rounded"
                  >
                    <MinusIcon className="w-3 h-3" />
                  </button>
                  <span className="w-8 text-center text-sm">{episodeCount}</span>
                  <button
                    onClick={() => setEpisodeCount(episodeCount + 1)}
                    className="w-6 h-6 flex items-center justify-center bg-gray-200 rounded"
                  >
                    <PlusIcon className="w-3 h-3" />
                  </button>
                  <button
                    onClick={handleUpdateCount}
                    className="px-2 py-1 text-xs bg-green-600 text-white rounded hover:bg-green-700"
                  >
                    OK
                  </button>
                  <button
                    onClick={() => setShowCountEditor(false)}
                    className="px-2 py-1 text-xs bg-gray-600 text-white rounded hover:bg-gray-700"
                  >
                    ✕
                  </button>
                </div>
              )}
            </div>
          </div>
        </div>
      </div>
    );
  };
  
  // Composant liste d'anime
  const AnimeListItem = ({ item, index }) => {
    const seriesKey = `${item.animeName}_${item.season}_${item.language}`;
    const episodeKey = `${seriesKey}_ep${item.episode || 'unknown'}`;
    const currentCount = watchCount[seriesKey]?.episodes[episodeKey]?.count || 1;
    const releaseDay = getReleaseDay(item.animeName);
    
    return (
      <div className="flex items-center p-3 border-b border-gray-200 hover:bg-gray-50">
        <img 
          src={item.imageUrl || `https://cdn.statically.io/gh/Anime-Sama/IMG/img/contenu/${item.animeName}.jpg`}
          alt={item.displayTitle}
          className="w-10 h-14 object-cover rounded mr-3"
          loading="lazy"
        />
        
        <div className="flex-1 min-w-0">
          <h4 className="font-medium text-gray-900 truncate">{item.displayTitle}</h4>
          <div className="flex items-center space-x-2 text-sm text-gray-500">
            <span>{item.season}</span>
            <span className="text-blue-600">{item.language}</span>
            {item.episode && <span>Ép. {item.episode}</span>}
            {releaseDay && <span>• {releaseDay}</span>}
          </div>
        </div>
        
        <div className="flex items-center space-x-4 text-sm text-gray-500">
          <span className="flex items-center">
            <EyeIcon className="w-4 h-4 mr-1" />
            {currentCount}
          </span>
          <span>{new Date(item.timestamp).toLocaleDateString('fr-FR')}</span>
        </div>
      </div>
    );
  };
  
  // Intersection Observer pour l'infinite scroll
  const loadMoreRef = useRef();
  
  useEffect(() => {
    if (!loadMoreRef.current || !hasMore || loading) return;
    
    const observer = new IntersectionObserver(
      (entries) => {
        if (entries[0].isIntersecting) {
          loadMoreItems();
        }
      },
      { threshold: 0.1 }
    );
    
    observer.observe(loadMoreRef.current);
    return () => observer.disconnect();
  }, [hasMore, loading, loadMoreItems]);
  
  if (!isExtensionConnected) {
    return (
      <div className="max-w-4xl mx-auto p-6">
        <div className="text-center py-12">
          <div className="mx-auto w-16 h-16 bg-red-100 rounded-full flex items-center justify-center mb-4">
            <svg className="w-8 h-8 text-red-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-2.5L13.732 4c-.77-.833-1.964-.833-2.732 0L3.732 16.5c-.77.833.192 2.5 1.732 2.5z" />
            </svg>
          </div>
          <h2 className="text-xl font-semibold text-gray-900 mb-2">Extension non connectée</h2>
          <p className="text-gray-600 mb-6">
            Veuillez installer et activer l'extension Anime History Tracker pour utiliser cette application.
          </p>
          <a
            href="#"
            className="inline-flex items-center px-4 py-2 bg-blue-600 text-white rounded-md hover:bg-blue-700"
          >
            Installer l'extension
          </a>
        </div>
      </div>
    );
  }
  
  return (
    <div className="max-w-6xl mx-auto p-6">
      {/* En-tête */}
      <div className="mb-8">
        <h1 className="text-3xl font-bold text-gray-900 mb-2">
          🎌 Anime History Tracker
        </h1>
        <p className="text-gray-600">
          Suivez votre progression anime avec des statistiques détaillées
        </p>
      </div>
      
      {/* Statistiques */}
      <div className="grid grid-cols-1 md:grid-cols-4 gap-4 mb-8">
        <div className="bg-blue-50 p-4 rounded-lg">
          <div className="text-2xl font-bold text-blue-900">{stats.totalEntries}</div>
          <div className="text-sm text-blue-700">Épisodes regardés</div>
        </div>
        <div className="bg-green-50 p-4 rounded-lg">
          <div className="text-2xl font-bold text-green-900">{stats.uniqueSeries}</div>
          <div className="text-sm text-green-700">Séries différentes</div>
        </div>
        <div className="bg-purple-50 p-4 rounded-lg">
          <div className="text-2xl font-bold text-purple-900">{stats.languages.length}</div>
          <div className="text-sm text-purple-700">Langues regardées</div>
        </div>
        <div className="bg-orange-50 p-4 rounded-lg">
          <div className="text-2xl font-bold text-orange-900">
            {Math.round(stats.totalWatchTime / 3600000)}h
          </div>
          <div className="text-sm text-orange-700">Temps total</div>
        </div>
      </div>
      
      {/* Barre d'outils */}
      <div className="bg-white p-4 rounded-lg shadow mb-6">
        <div className="flex flex-col lg:flex-row gap-4">
          {/* Recherche */}
          <div className="flex-1">
            <div className="relative">
              <MagnifyingGlassIcon className="absolute left-3 top-1/2 transform -translate-y-1/2 w-4 h-4 text-gray-400" />
              <input
                type="text"
                placeholder="Rechercher un anime..."
                value={searchQuery}
                onChange={(e) => setSearchQuery(e.target.value)}
                className="w-full pl-10 pr-4 py-2 border border-gray-300 rounded-md focus:ring-2 focus:ring-blue-500 focus:border-transparent"
              />
            </div>
          </div>
          
          {/* Filtres */}
          <div className="flex gap-2">
            <select
              value={filters.language}
              onChange={(e) => setFilters(prev => ({ ...prev, language: e.target.value }))}
              className="px-3 py-2 border border-gray-300 rounded-md focus:ring-2 focus:ring-blue-500"
            >
              <option value="">Toutes langues</option>
              <option value="VOSTFR">VOSTFR</option>
              <option value="VF">VF</option>
            </select>
            
            <select
              value={filters.status}
              onChange={(e) => setFilters(prev => ({ ...prev, status: e.target.value }))}
              className="px-3 py-2 border border-gray-300 rounded-md focus:ring-2 focus:ring-blue-500"
            >
              <option value="">Tous statuts</option>
              <option value="completed">Terminé</option>
              <option value="ongoing">En cours</option>
            </select>
          </div>
          
          {/* Mode d'affichage */}
          <div className="flex bg-gray-100 rounded-md p-1">
            <button
              onClick={() => setViewMode('card')}
              className={`px-3 py-1 rounded flex items-center ${
                viewMode === 'card' 
                  ? 'bg-white shadow text-blue-600' 
                  : 'text-gray-600 hover:text-gray-900'
              }`}
            >
              <Squares2X2Icon className="w-4 h-4 mr-1" />
              Cartes
            </button>
            <button
              onClick={() => setViewMode('list')}
              className={`px-3 py-1 rounded flex items-center ${
                viewMode === 'list' 
                  ? 'bg-white shadow text-blue-600' 
                  : 'text-gray-600 hover:text-gray-900'
              }`}
            >
              <ListBulletIcon className="w-4 h-4 mr-1" />
              Liste
            </button>
          </div>
        </div>
      </div>
      
      {/* Contenu principal */}
      <div className="space-y-4">
        {displayedItems.length === 0 ? (
          <div className="text-center py-12">
            <div className="mx-auto w-16 h-16 bg-gray-100 rounded-full flex items-center justify-center mb-4">
              <EyeIcon className="w-8 h-8 text-gray-400" />
            </div>
            <h3 className="text-lg font-medium text-gray-900 mb-2">Aucun historique</h3>
            <p className="text-gray-500">
              Regardez des animes sur Anime-Sama pour voir votre historique ici.
            </p>
          </div>
        ) : (
          <>
            {viewMode === 'card' ? (
              <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
                {displayedItems.map((item, index) => (
                  <AnimeCard key={item.id || index} item={item} index={index} />
                ))}
              </div>
            ) : (
              <div className="bg-white rounded-lg shadow overflow-hidden">
                {displayedItems.map((item, index) => (
                  <AnimeListItem key={item.id || index} item={item} index={index} />
                ))}
              </div>
            )}
            
            {/* Infinite scroll loader */}
            {hasMore && (
              <div ref={loadMoreRef} className="text-center py-6">
                {loading ? (
                  <div className="inline-flex items-center">
                    <div className="animate-spin rounded-full h-6 w-6 border-b-2 border-blue-600 mr-2"></div>
                    Chargement...
                  </div>
                ) : (
                  <button
                    onClick={loadMoreItems}
                    className="px-6 py-2 bg-blue-600 text-white rounded-md hover:bg-blue-700"
                  >
                    Charger plus
                  </button>
                )}
              </div>
            )}
          </>
        )}
      </div>
    </div>
  );
};

export default AnimeHistoryTracker;
