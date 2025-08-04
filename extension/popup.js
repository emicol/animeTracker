// Popup script pour l'extension
document.addEventListener('DOMContentLoaded', async () => {
  const totalAnimesEl = document.getElementById('totalAnimes');
  const totalEpisodesEl = document.getElementById('totalEpisodes');
  const recentListEl = document.getElementById('recentList');
  const openPWABtn = document.getElementById('openPWA');
  const refreshBtn = document.getElementById('refreshData');
  
  // Charger les statistiques
  async function loadStats() {
    try {
      const response = await chrome.runtime.sendMessage({ action: 'GET_HISTORY' });
      
      if (response.success) {
        const history = response.history;
        const uniqueAnimes = new Set(history.map(item => item.animeName)).size;
        
        totalAnimesEl.textContent = uniqueAnimes;
        totalEpisodesEl.textContent = history.length;
        
        // Afficher les 5 derniers
        const recent = history.slice(0, 5);
        recentListEl.innerHTML = recent.map(item => `
          <div class="recent-item">
            <div class="recent-title">${item.displayTitle}</div>
            <div class="recent-meta">
              ${item.episode ? `Ép. ${item.episode}` : ''} • ${item.language}
            </div>
          </div>
        `).join('');
      }
    } catch (error) {
      console.error('Erreur chargement stats:', error);
      recentListEl.innerHTML = '<div class="error">Erreur de chargement</div>';
    }
  }
  
  // Ouvrir la PWA
  openPWABtn.addEventListener('click', () => {
    chrome.tabs.create({ 
      url: 'https://emicol.github.io/animeTracker/' 
    });
  });
  
  // Actualiser les données
  refreshBtn.addEventListener('click', loadStats);
  
  // Charger les stats au démarrage
  loadStats();
});
