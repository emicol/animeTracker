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

// === GESTION DES MISES À JOUR DANS POPUP ===
async function checkUpdateStatus() {
  try {
    const response = await chrome.runtime.sendMessage({ action: 'GET_UPDATE_INFO' });
    
    if (response.success && response.updateInfo) {
      showUpdateBanner(response.updateInfo);
    }
  } catch (error) {
    console.error('Erreur vérification MAJ:', error);
  }
}

function showUpdateBanner(updateInfo) {
  const container = document.querySelector('.popup-container');
  
  const banner = document.createElement('div');
  banner.className = 'update-banner';
  banner.innerHTML = `
    <div class="update-content">
      <strong>🆕 Mise à jour v${updateInfo.version}</strong>
      <p>Une nouvelle version est disponible !</p>
      <div class="update-actions">
        <button id="downloadUpdate" class="btn-update">📥 Télécharger</button>
        <button id="dismissUpdate" class="btn-dismiss">✕</button>
      </div>
    </div>
  `;
  
  container.insertBefore(banner, container.firstChild);
  
  // Actions
  document.getElementById('downloadUpdate').onclick = () => {
    chrome.tabs.create({ url: updateInfo.releaseUrl });
    window.close();
  };
  
  document.getElementById('dismissUpdate').onclick = async () => {
    await chrome.runtime.sendMessage({ action: 'CLEAR_UPDATE_NOTIFICATION' });
    banner.remove();
  };
}

// Ajouter à l'initialisation
document.addEventListener('DOMContentLoaded', () => {
  checkUpdateStatus();
  // ... reste du code existant
});
