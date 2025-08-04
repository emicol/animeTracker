#!/bin/bash

# 🎌 Setup GitHub Distribution - Anime History Tracker
# Configure complètement la distribution GitHub de l'extension

set -e

# Couleurs
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
PURPLE='\033[0;35m'
NC='\033[0m'

log() { printf "${GREEN}[$(date +'%H:%M:%S')]${NC} %s\n" "$1"; }
info() { printf "${BLUE}[INFO]${NC} %s\n" "$1"; }
warn() { printf "${YELLOW}[WARN]${NC} %s\n" "$1"; }
error() { printf "${RED}[ERROR]${NC} %s\n" "$1"; exit 1; }
header() { printf "\n${PURPLE}=== %s ===${NC}\n\n" "$1"; }

# Configuration
GITHUB_USER="emicol"
REPO_NAME="animeTracker"
EXTENSION_ID="generate-later"  # Sera généré après première installation

# Créer la structure GitHub complète
setup_github_structure() {
    header "📁 Configuration structure GitHub"
    
    # Créer les dossiers nécessaires
    mkdir -p {.github/{workflows,ISSUE_TEMPLATE},docs}
    
    # Documentation principale
    cat > README.md << 'EOF'
# 🎌 Anime History Tracker

> Suivez automatiquement votre historique de visionnage d'animes sur Anime-Sama.fr

[![Extension](https://img.shields.io/badge/Extension-Chrome%2FBrave-blue)](https://github.com/emicol/animeTracker/releases/latest)
[![PWA](https://img.shields.io/badge/PWA-Live-green)](https://emicol.github.io/animeTracker/)
[![License](https://img.shields.io/badge/License-MIT-yellow)](LICENSE)
[![GitHub release](https://img.shields.io/github/v/release/emicol/animeTracker)](https://github.com/emicol/animeTracker/releases)

## 🚀 Installation Rapide

### 📦 Extension Navigateur (Recommandé)

**[📥 TÉLÉCHARGER EXTENSION](https://github.com/emicol/animeTracker/releases/latest/download/anime-tracker-extension-latest.zip)**

1. **Décompresser** le fichier ZIP téléchargé
2. **Ouvrir** `chrome://extensions/` (ou `brave://extensions/`)
3. **Activer** le "Mode développeur" (coin supérieur droit)
4. **Cliquer** "Charger l'extension non empaquetée"
5. **Sélectionner** le dossier décompressé
6. **C'est prêt !** 🎉

### 🌐 Application Web (PWA)

**[🔗 OUVRIR ANIME TRACKER](https://emicol.github.io/animeTracker/)**

*L'extension se connecte automatiquement à la PWA pour synchroniser vos données.*

### 📱 Application Mobile

**[📥 TÉLÉCHARGER APK](https://github.com/emicol/animeTracker/releases/latest/download/anime-tracker-mobile.apk)**

## ✨ Fonctionnalités

- ✅ **Tracking automatique** - Détection automatique des animes regardés
- 📊 **Statistiques détaillées** - Temps de visionnage, épisodes, séries
- 🔄 **Synchronisation temps réel** - Extension ↔ PWA ↔ Mobile  
- 📱 **Multi-plateforme** - Extension + PWA + APK Android
- 🌐 **Planning intégré** - Sorties d'animes de la semaine
- 📈 **Compteurs avancés** - Nombre de vues par épisode
- 🎨 **Interface moderne** - Design responsive et intuitive

## 📖 Documentation

- 📚 **[Guide d'installation détaillé](docs/EXTENSION_INSTALL.md)**
- 🔄 **[Guide de mise à jour](docs/UPDATE_GUIDE.md)**
- 🛠️ **[Résolution de problèmes](docs/TROUBLESHOOTING.md)**
- 💻 **[Guide développeur](docs/DEVELOPMENT.md)**

## 🔄 Mises à jour

L'extension vérifie automatiquement les mises à jour et vous notifie quand une nouvelle version est disponible.

**Version actuelle :** Voir [Releases](https://github.com/emicol/animeTracker/releases/latest)

## 📸 Captures d'écran

### Extension
![Extension Popup](assets/screenshots/extension-popup.png)

### PWA Dashboard  
![PWA Dashboard](assets/screenshots/pwa-dashboard.png)

### Application Mobile
![Mobile App](assets/screenshots/mobile-app.png)

## 🤝 Support & Communauté

- 🐛 **[Signaler un bug](https://github.com/emicol/animeTracker/issues/new?template=bug_report.md)**
- 💡 **[Demander une fonctionnalité](https://github.com/emicol/animeTracker/issues/new?template=feature_request.md)**
- 💬 **[Discussions](https://github.com/emicol/animeTracker/discussions)**
- ⭐ **Likez le projet** si il vous est utile !

## 📄 Licence

MIT © emicol

---

**🎌 Bon visionnage d'animes !**
EOF
    
    log "✅ README.md principal créé"
    
    # Workflow GitHub Actions
    cat > .github/workflows/release.yml << 'EOF'
name: 🚀 Build & Release

on:
  push:
    tags:
      - 'extension-v*'
      - 'v*'
  workflow_dispatch:

jobs:
  build-and-release:
    runs-on: ubuntu-latest
    
    steps:
    - name: 📥 Checkout
      uses: actions/checkout@v4
      
    - name: 🔧 Setup Node.js
      uses: actions/setup-node@v4
      with:
        node-version: '18'
        cache: 'npm'
        cache-dependency-path: |
          pwa/package-lock.json
          mobile/package-lock.json
        
    - name: 📦 Install dependencies
      run: |
        cd pwa && npm ci
        cd ../mobile && npm ci
        
    - name: 🎨 Setup ImageMagick
      run: |
        sudo apt-get update
        sudo apt-get install imagemagick -y
        
    - name: 🖼️ Generate icons
      run: |
        chmod +x fix-icons.sh
        ./fix-icons.sh --generate-only
        
    - name: 🏗️ Build PWA
      run: |
        cd pwa && npm run build
        
    - name: 📦 Package Extension
      run: |
        cd extension
        # Nettoyer et préparer
        rm -f *.zip
        
        # Créer l'archive
        zip -r "../anime-tracker-extension-${GITHUB_REF#refs/tags/}.zip" . \
          -x "*.md" "node_modules/*" "*.log" "*.zip" ".DS_Store"
        
        # Version "latest" pour lien direct
        cp "../anime-tracker-extension-${GITHUB_REF#refs/tags/}.zip" \
           "../anime-tracker-extension-latest.zip"
           
    - name: 📱 Build APK (if possible)
      run: |
        if [ -f "build-apk.sh" ]; then
          chmod +x build-apk.sh
          timeout 300 ./build-apk.sh || echo "APK build timeout - will be available in manual releases"
          
          # Copier l'APK s'il existe
          if ls dist/*.apk 1> /dev/null 2>&1; then
            cp dist/*.apk anime-tracker-mobile.apk
          fi
        fi
        
    - name: 📋 Generate Release Notes
      id: release_notes
      run: |
        echo "## 🎌 Anime History Tracker ${GITHUB_REF#refs/tags/}" > release_notes.md
        echo "" >> release_notes.md
        echo "### 📦 Fichiers de cette release:" >> release_notes.md
        echo "- **Extension navigateur** → \`anime-tracker-extension-latest.zip\`" >> release_notes.md
        if [ -f "anime-tracker-mobile.apk" ]; then
          echo "- **Application mobile** → \`anime-tracker-mobile.apk\`" >> release_notes.md
        fi
        echo "- **PWA** → [emicol.github.io/animeTracker](https://emicol.github.io/animeTracker/)" >> release_notes.md
        echo "" >> release_notes.md
        echo "### 🚀 Installation rapide:" >> release_notes.md
        echo "1. Téléchargez \`anime-tracker-extension-latest.zip\`" >> release_notes.md
        echo "2. Décompressez le fichier" >> release_notes.md
        echo "3. Allez dans \`chrome://extensions/\`" >> release_notes.md
        echo "4. Activez le mode développeur" >> release_notes.md
        echo "5. Cliquez \"Charger extension non empaquetée\"" >> release_notes.md
        echo "6. Sélectionnez le dossier décompressé" >> release_notes.md
        echo "" >> release_notes.md
        echo "**Documentation complète:** [docs/EXTENSION_INSTALL.md](docs/EXTENSION_INSTALL.md)" >> release_notes.md
        
    - name: 🚀 Create Release
      uses: softprops/action-gh-release@v1
      with:
        files: |
          anime-tracker-extension-${{ github.ref_name }}.zip
          anime-tracker-extension-latest.zip
          anime-tracker-mobile.apk
        body_path: release_notes.md
        draft: false
        prerelease: false
        generate_release_notes: true
      env:
        GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
        
    - name: 📊 Upload artifacts
      uses: actions/upload-artifact@v4
      with:
        name: anime-tracker-builds
        path: |
          anime-tracker-extension-*.zip
          anime-tracker-mobile.apk
        retention-days: 30
EOF
    
    log "✅ GitHub Actions workflow créé"
}

# Créer les templates d'issues
create_issue_templates() {
    header "📝 Création des templates d'issues"
    
    # Bug report
    cat > .github/ISSUE_TEMPLATE/bug_report.md << 'EOF'
---
name: 🐛 Bug Report
about: Signaler un problème avec l'extension ou la PWA
title: '[BUG] '
labels: 'bug'
assignees: ''
---

## 🐛 Description du bug
Une description claire et concise du problème.

## 🔄 Étapes pour reproduire
1. Aller sur '...'
2. Cliquer sur '...'
3. Faire défiler jusqu'à '...'
4. Voir l'erreur

## ✅ Comportement attendu
Description claire de ce qui devrait se passer.

## 📸 Captures d'écran
Si applicable, ajoutez des captures d'écran pour aider à expliquer le problème.

## 📱 Environnement
- **OS**: [Windows 10/11, macOS, Ubuntu, etc.]
- **Navigateur**: [Chrome, Brave, Firefox + version]
- **Extension version**: [visible dans chrome://extensions/]
- **Site concerné**: [anime-sama.fr, PWA, etc.]

## 🔍 Informations supplémentaires
- Console errors (F12 → Console)
- Comportement depuis quand
- Fréquence du problème
EOF
    
    # Feature request
    cat > .github/ISSUE_TEMPLATE/feature_request.md << 'EOF'
---
name: 💡 Feature Request
about: Suggérer une nouvelle fonctionnalité
title: '[FEATURE] '
labels: 'enhancement'
assignees: ''
---

## 💡 Résumé de la fonctionnalité
Description courte de la fonctionnalité demandée.

## 🎯 Problème résolu
Quel problème cette fonctionnalité résoudrait-elle ?

## 🔧 Solution proposée
Description détaillée de la solution que vous aimeriez voir.

## 🎨 Alternatives considérées
Autres solutions ou fonctionnalités auxquelles vous avez pensé.

## 📱 Plateforme concernée
- [ ] Extension navigateur
- [ ] PWA (Application web)
- [ ] Application mobile
- [ ] Toutes plateformes

## 🌟 Priorité
- [ ] Nice to have
- [ ] Important
- [ ] Critique

## 📝 Contexte additionnel
Ajoutez tout autre contexte ou captures d'écran à propos de la demande.
EOF
    
    log "✅ Templates d'issues créés"
}

# Créer la documentation complète
create_documentation() {
    header "📚 Création de la documentation"
    
    # Guide d'installation détaillé
    cat > docs/EXTENSION_INSTALL.md << 'EOF'
# 📦 Guide d'Installation - Extension Anime History Tracker

## 🎯 Prérequis

- **Navigateur supporté**: Chrome, Brave, Edge, Opera
- **Version**: Chromium 88+ (vérifiez avec `chrome://version/`)
- **Permissions**: Autorisation mode développeur

## 📥 Téléchargement

### Option 1: Téléchargement direct (Recommandé)

**[📥 TÉLÉCHARGER LA DERNIÈRE VERSION](https://github.com/emicol/animeTracker/releases/latest/download/anime-tracker-extension-latest.zip)**

### Option 2: Depuis GitHub Releases

1. Allez sur [GitHub Releases](https://github.com/emicol/animeTracker/releases)
2. Cliquez sur la dernière version
3. Téléchargez `anime-tracker-extension-latest.zip`

## 🔧 Installation Étape par Étape

### 1. Décompression

1. **Localisez** le fichier ZIP téléchargé
2. **Clic droit** → "Extraire tout" (Windows) ou double-clic (Mac/Linux)
3. **Choisissez** un dossier permanent (ex: `Documents/Extensions/AnimeTracker`)

⚠️ **Important**: Ne supprimez pas ce dossier après installation !

### 2. Activation du Mode Développeur

1. **Ouvrez** votre navigateur
2. **Tapez** dans la barre d'adresse:
   - Chrome: `chrome://extensions/`
   - Brave: `brave://extensions/`
   - Edge: `edge://extensions/`
3. **Activez** le bouton "Mode développeur" (coin supérieur droit)

### 3. Installation de l'Extension

1. **Cliquez** sur "Charger l'extension non empaquetée"
2. **Naviguez** vers le dossier décompressé
3. **Sélectionnez** le dossier (pas un fichier)
4. **Cliquez** "Sélectionner le dossier"

### 4. Vérification

✅ L'extension apparaît dans la liste avec l'icône 🎌  
✅ L'icône est visible dans la barre d'outils du navigateur  
✅ Pas de message d'erreur

## 🎌 Premier Usage

### 1. Test sur Anime-Sama

1. **Visitez** [anime-sama.fr](https://anime-sama.fr)
2. **Allez** dans une page anime (ex: `/catalogue/naruto/1/vostfr`)
3. **Regardez** au moins 30 secondes d'un épisode
4. **Cliquez** sur l'icône extension 🎌

### 2. Vérification PWA

1. **Ouvrez** [Anime Tracker PWA](https://emicol.github.io/animeTracker/)
2. **Vérifiez** que "Extension connectée" apparaît
3. **Consultez** votre historique

## 🔄 Mises à Jour

### Notification Automatique

L'extension vérifie automatiquement les mises à jour et vous notifie.

### Mise à Jour Manuelle

1. **Téléchargez** la nouvelle version
2. **Décompressez** dans le même dossier (remplacez les fichiers)
3. **Allez** dans `chrome://extensions/`
4. **Cliquez** sur l'icône "Actualiser" de l'extension

## 🛠️ Résolution de Problèmes

### Extension Non Visible

- ✅ Vérifiez que le mode développeur est activé
- ✅ Actualisez la page extensions (`F5`)
- ✅ Épinglez l'extension (clic droit sur l'icône)

### Erreurs de Chargement

- ✅ Vérifiez que tous les fichiers sont présents
- ✅ Téléchargez à nouveau le ZIP
- ✅ Désinstallez et réinstallez

### Historique Vide

- ✅ Regardez au moins 30 secondes d'anime
- ✅ Vérifiez que vous êtes sur `anime-sama.fr/catalogue/`
- ✅ Ouvrez la console (F12) pour voir les erreurs

### PWA Non Connectée

- ✅ Actualisez la page PWA
- ✅ Vérifiez que l'extension est installée ET activée
- ✅ Regardez un anime pour tester la connexion

## 🔒 Sécurité & Confidentialité

- ✅ **Données locales**: Tout est stocké sur votre navigateur
- ✅ **Pas de tracking**: Aucune donnée envoyée à des tiers
- ✅ **Open source**: Code accessible sur GitHub
- ✅ **Permissions minimales**: Accès uniquement à anime-sama.fr

## 💬 Support

- 🐛 **Bug?** → [Signaler un problème](https://github.com/emicol/animeTracker/issues/new?template=bug_report.md)
- 💡 **Idée?** → [Demander une fonctionnalité](https://github.com/emicol/animeTracker/issues/new?template=feature_request.md)
- ❓ **Question?** → [Discussions GitHub](https://github.com/emicol/animeTracker/discussions)

---

**🎌 Installation terminée ! Bon visionnage d'animes !**
EOF
    
    # Guide de mise à jour
    cat > docs/UPDATE_GUIDE.md << 'EOF'
# 🔄 Guide de Mise à Jour - Anime History Tracker

## 🔔 Notification de Mise à Jour

L'extension vous notifie automatiquement quand une nouvelle version est disponible.

### Types de Notifications

- **🔔 Notification navigateur**: Popup avec lien de téléchargement
- **🔴 Badge sur l'icône**: Point rouge sur l'icône extension
- **📋 Popup extension**: Message dans l'interface popup

## 📥 Téléchargement de la Mise à Jour

### Option 1: Lien Direct

**[📥 DERNIÈRE VERSION](https://github.com/emicol/animeTracker/releases/latest/download/anime-tracker-extension-latest.zip)**

### Option 2: Depuis la Notification

1. **Cliquez** sur la notification
2. **Vous serez redirigé** vers la page de téléchargement
3. **Téléchargez** le nouveau ZIP

## 🔄 Processus de Mise à Jour

### Méthode Rapide (Recommandée)

1. **Téléchargez** la nouvelle version
2. **Décompressez** dans le même dossier (remplacez les anciens fichiers)
3. **Allez** dans `chrome://extensions/`
4. **Cliquez** sur l'icône "Actualiser" 🔄 de l'extension
5. **Fini !** La nouvelle version est active

### Méthode Complète

1. **Notez** le dossier d'installation actuel
2. **Désinstallez** l'ancienne version (bouton "Supprimer")
3. **Téléchargez** et décompressez la nouvelle version
4. **Installez** comme une nouvelle extension
5. **Vos données** sont conservées automatiquement

## 📊 Vérification de la Version

### Dans l'Extension

1. **Cliquez** sur l'icône extension 🎌
2. **La version** est affichée en bas du popup

### Dans Chrome Extensions

1. **Allez** dans `chrome://extensions/`
2. **Trouvez** "Anime History Tracker"
3. **La version** est affichée sous le nom

## 🔍 Changelog (Nouveautés)

Consultez les nouveautés de chaque version:

- **[Releases GitHub](https://github.com/emicol/animeTracker/releases)** - Détails complets
- **[CHANGELOG.md](../CHANGELOG.md)** - Historique des versions

## 🛠️ Problèmes de Mise à Jour

### La Mise à Jour Ne Fonctionne Pas

1. **Fermez** complètement le navigateur
2. **Rouvrez** le navigateur
3. **Répétez** le processus de mise à jour

### Perte de Données

😌 **Rassurez-vous**: Vos données sont conservées dans le stockage local du navigateur.

**Si vous perdez quand même vos données**:
1. Vérifiez dans la PWA si elles sont synchronisées
2. Regardez quelques animes pour reconstruire l'historique

### Extension Cassée Après MAJ

1. **Désinstallez** l'extension
2. **Supprimez** le dossier d'installation
3. **Téléchargez** une version fraîche
4. **Réinstallez** complètement

## 🚀 Versions Bêta

Parfois, des versions bêta sont disponibles avec de nouvelles fonctionnalités.

### Installation Version Bêta

1. **Allez** sur [GitHub Releases](https://github.com/emicol/animeTracker/releases)
2. **Cherchez** les versions marquées "Pre-release"
3. **Téléchargez** et installez normalement

⚠️ **Attention**: Les versions bêta peuvent contenir des bugs.

## 📅 Fréquence des Mises à Jour

- **Corrections de bugs**: Dès que nécessaire
- **Nouvelles fonctionnalités**: Mensuellement
- **Mises à jour de sécurité**: Immédiatement

## 💬 Support Mise à Jour

**Problème avec une mise à jour?**

- 🐛 **[Signaler un bug de MAJ](https://github.com/emicol/animeTracker/issues/new?template=bug_report.md)**
- 💬 **[Poser une question](https://github.com/emicol/animeTracker/discussions)**

---

**🔄 Gardez votre extension à jour pour profiter des dernières fonctionnalités !**
EOF
    
    log "✅ Documentation complète créée"
}

# Améliorer l'extension avec détection de MAJ
enhance_extension_update_system() {
    header "🔄 Amélioration système de mise à jour extension"
    
    # Ajouter au background.js
    cat >> extension/background.js << 'EOF'

// === SYSTÈME DE MISE À JOUR ===
class UpdateManager {
  constructor() {
    this.githubAPI = 'https://api.github.com/repos/emicol/animeTracker/releases/latest';
    this.currentVersion = chrome.runtime.getManifest().version;
    this.checkInterval = 24 * 60 * 60 * 1000; // 24h
    
    this.init();
  }
  
  async init() {
    // Vérifier au démarrage (avec délai)
    setTimeout(() => this.checkForUpdates(), 5000);
    
    // Vérification périodique
    chrome.alarms.create('updateCheck', {
      when: Date.now() + this.checkInterval,
      periodInMinutes: 24 * 60 // Tous les jours
    });
    
    chrome.alarms.onAlarm.addListener((alarm) => {
      if (alarm.name === 'updateCheck') {
        this.checkForUpdates();
      }
    });
    
    // Gestion des clics sur notifications
    chrome.notifications.onClicked.addListener((notificationId) => {
      if (notificationId.startsWith('update-')) {
        chrome.tabs.create({
          url: 'https://github.com/emicol/animeTracker/releases/latest'
        });
        chrome.notifications.clear(notificationId);
        chrome.action.setBadgeText({ text: '' });
      }
    });
  }
  
  async checkForUpdates() {
    try {
      console.log('🔍 Vérification mises à jour...');
      
      const response = await fetch(this.githubAPI, {
        cache: 'no-cache'
      });
      
      if (!response.ok) return;
      
      const release = await response.json();
      const latestVersion = release.tag_name.replace(/^extension-v/, '');
      
      if (this.isNewerVersion(latestVersion, this.currentVersion)) {
        this.notifyUpdate(release, latestVersion);
      } else {
        console.log('✅ Extension à jour');
      }
    } catch (error) {
      console.error('❌ Erreur vérification MAJ:', error);
    }
  }
  
  isNewerVersion(latest, current) {
    const parseVersion = (v) => v.split('.').map(Number);
    const latestParts = parseVersion(latest);
    const currentParts = parseVersion(current);
    
    for (let i = 0; i < Math.max(latestParts.length, currentParts.length); i++) {
      const l = latestParts[i] || 0;
      const c = currentParts[i] || 0;
      
      if (l > c) return true;
      if (l < c) return false;
    }
    return false;
  }
  
  async notifyUpdate(release, version) {
    console.log(`🆕 Nouvelle version disponible: ${version}`);
    
    // Badge sur l'icône
    chrome.action.setBadgeText({ text: '!' });
    chrome.action.setBadgeBackgroundColor({ color: '#ff4444' });
    chrome.action.setTitle({ 
      title: `Anime History Tracker - MAJ v${version} disponible!` 
    });
    
    // Notification
    const notificationId = `update-${Date.now()}`;
    chrome.notifications.create(notificationId, {
      type: 'basic',
      iconUrl: 'icons/icon48.png',
      title: '🎌 Anime Tracker - Mise à jour disponible',
      message: `Version ${version} disponible ! Cliquez pour télécharger.`,
      buttons: [
        { title: '📥 Télécharger' },
        { title: '⏰ Plus tard' }
      ]
    });
    
    // Stocker l'info de MAJ
    chrome.storage.local.set({
      updateAvailable: {
        version: version,
        releaseUrl: release.html_url,
        downloadUrl: release.assets.find(a => a.name.includes('latest'))?.browser_download_url,
        notifiedAt: Date.now()
      }
    });
  }
  
  async getUpdateInfo() {
    const result = await chrome.storage.local.get('updateAvailable');
    return result.updateAvailable || null;
  }
  
  async clearUpdateNotification() {
    chrome.action.setBadgeText({ text: '' });
    chrome.storage.local.remove('updateAvailable');
  }
}

// Initialiser le gestionnaire de mises à jour
const updateManager = new UpdateManager();

// Ajouter aux messages handlers
chrome.runtime.onMessage.addListener((message, sender, sendResponse) => {
  switch (message.action) {
    case 'GET_UPDATE_INFO':
      updateManager.getUpdateInfo()
        .then(info => sendResponse({ success: true, updateInfo: info }))
        .catch(error => sendResponse({ success: false, error: error.message }));
      return true;
      
    case 'CLEAR_UPDATE_NOTIFICATION':
      updateManager.clearUpdateNotification()
        .then(() => sendResponse({ success: true }))
        .catch(error => sendResponse({ success: false, error: error.message }));
      return true;
      
    case 'CHECK_UPDATES':
      updateManager.checkForUpdates()
        .then(() => sendResponse({ success: true }))
        .catch(error => sendResponse({ success: false, error: error.message }));
      return true;
      
    case 'GET_VERSION':
      sendResponse({ 
        success: true, 
        version: updateManager.currentVersion,
        extensionId: chrome.runtime.id
      });
      return true;
  }
});

console.log('🔄 Système de mise à jour initialisé');
EOF
    
    # Améliorer le popup avec infos de MAJ
    cat >> extension/popup.js << 'EOF'

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
EOF
    
    # CSS pour le banner de MAJ
    cat >> extension/styles/popup.css << 'EOF'

/* Styles pour le banner de mise à jour */
.update-banner {
  background: linear-gradient(135deg, #10b981, #059669);
  color: white;
  padding: 12px;
  margin: -16px -16px 16px -16px;
  border-radius: 8px 8px 0 0;
}

.update-content {
  text-align: center;
}

.update-content strong {
  display: block;
  margin-bottom: 4px;
  font-size: 14px;
}

.update-content p {
  margin: 0 0 8px 0;
  font-size: 12px;
  opacity: 0.9;
}

.update-actions {
  display: flex;
  gap: 8px;
  justify-content: center;
}

.btn-update {
  background: rgba(255, 255, 255, 0.2);
  color: white;
  border: 1px solid rgba(255, 255, 255, 0.3);
  padding: 4px 12px;
  border-radius: 4px;
  font-size: 11px;
  cursor: pointer;
  transition: background-color 0.2s;
}

.btn-update:hover {
  background: rgba(255, 255, 255, 0.3);
}

.btn-dismiss {
  background: transparent;
  color: white;
  border: 1px solid rgba(255, 255, 255, 0.3);
  padding: 4px 8px;
  border-radius: 4px;
  font-size: 11px;
  cursor: pointer;
  opacity: 0.8;
}

.btn-dismiss:hover {
  opacity: 1;
  background: rgba(255, 255, 255, 0.1);
}
EOF
    
    log "✅ Système de mise à jour extension amélioré"
}

# Améliorer la PWA avec détection extension
enhance_pwa_extension_detection() {
    header "🌐 Amélioration détection extension PWA"
    
    # Créer un composant de détection d'extension amélioré
    cat > pwa/src/components/ExtensionStatus.jsx << 'EOF'
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
EOF
    
    log "✅ Composant de détection d'extension PWA créé"
}

# Créer le changelog
create_changelog() {
    header "📝 Création du CHANGELOG"
    
    cat > CHANGELOG.md << 'EOF'
# 📝 Changelog

Toutes les modifications notables de ce projet seront documentées dans ce fichier.

Le format est basé sur [Keep a Changelog](https://keepachangelog.com/fr/1.0.0/),
et ce projet adhère au [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### À venir
- Synchronisation cloud optionnelle
- Thèmes personnalisables
- Export de données

## [1.0.0] - 2025-01-XX

### ✨ Ajouté
- **Extension navigateur** - Tracking automatique sur Anime-Sama.fr
- **Interface PWA** - Application web complète et responsive
- **Application mobile** - APK Android avec Capacitor
- **Synchronisation temps réel** - Extension ↔ PWA ↔ Mobile
- **Statistiques avancées** - Temps de visionnage, compteurs d'épisodes
- **Planning intégré** - Sorties d'animes de la semaine
- **Système de mise à jour** - Notifications automatiques
- **Multi-langues** - Support VOSTFR et VF
- **Historique détaillé** - Avec métadonnées complètes

### 🔧 Technique
- Manifest V3 pour l'extension
- React 18 pour la PWA
- Capacitor pour le mobile
- GitHub Actions pour CI/CD
- ImageMagick pour génération d'icônes

### 📚 Documentation
- Guide d'installation complet
- Documentation développeur
- Templates d'issues GitHub
- Système de support communautaire

---

## Format des entrées

### Types de changements
- **✨ Ajouté** - Nouvelles fonctionnalités
- **🔧 Modifié** - Changements de fonctionnalités existantes
- **🐛 Corrigé** - Corrections de bugs
- **🗑️ Supprimé** - Fonctionnalités supprimées
- **🔒 Sécurité** - Corrections de vulnérabilités
- **📚 Documentation** - Améliorations de la documentation
EOF
    
    log "✅ CHANGELOG créé"
}

# Fonction principale
main() {
    clear
    printf "${PURPLE}%s\n" "🎌 SETUP GITHUB DISTRIBUTION - ANIME HISTORY TRACKER"
    printf "%s\n" "======================================================"
    printf "${NC}\n"
    
    echo "Ce script va configurer une distribution GitHub professionnelle :"
    echo ""
    echo "  📁 Structure complète du repository"
    echo "  🚀 GitHub Actions pour releases automatiques"
    echo "  📚 Documentation utilisateur complète"
    echo "  🔄 Système de mise à jour automatique"
    echo "  🌐 Amélioration détection extension PWA"
    echo "  📝 Templates issues et support"
    echo ""
    
    read -p "Continuer ? [y/N]: " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Opération annulée."
        exit 0
    fi
    
    # Vérifier qu'on est dans le bon répertoire
    if [ ! -d "extension" ] || [ ! -d "pwa" ]; then
        error "❌ Ce script doit être exécuté depuis la racine du projet anime-history-tracker (dossiers extension/ et pwa/ requis)"
    fi
    
    # Vérifier que nous avons les fichiers essentiels
    if [ ! -f "extension/manifest.json" ]; then
        error "❌ extension/manifest.json manquant"
    fi
    
    if [ ! -f "pwa/package.json" ]; then
        error "❌ pwa/package.json manquant"
    fi
    
    setup_github_structure
    create_issue_templates
    create_documentation
    enhance_extension_update_system
    enhance_pwa_extension_detection
    create_changelog
    
    # Commit et push
    info "📤 Commit et push des changements..."
    git add .
    git commit -m "🚀 Setup GitHub distribution complète

✨ GitHub Actions pour releases automatiques
📚 Documentation utilisateur complète  
🔄 Système de mise à jour extension
🌐 Détection extension PWA améliorée
📝 Templates issues et support
📋 Structure repository professionnelle" || true
    
    # Détecter la branche et push
    MAIN_BRANCH=$(git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's@^refs/remotes/origin/@@' || echo "master")
    if ! git show-ref --verify --quiet "refs/heads/$MAIN_BRANCH"; then
        MAIN_BRANCH=$(git branch --show-current)
    fi
    
    git push origin "$MAIN_BRANCH"
    
    echo ""
    echo "🎉 DISTRIBUTION GITHUB CONFIGURÉE AVEC SUCCÈS!"
    echo "=============================================="
    echo ""
    echo "🔗 **Liens importants:**"
    echo "  📦 Releases: https://github.com/$GITHUB_USER/$REPO_NAME/releases"
    echo "  🌐 PWA: https://$GITHUB_USER.github.io/$REPO_NAME/"
    echo "  📚 Docs: https://github.com/$GITHUB_USER/$REPO_NAME/tree/master/docs"
    echo ""
    echo "🚀 **Prochaines étapes:**"
    echo "  1. Créer votre première release:"
    echo "     git tag extension-v1.0.0"
    echo "     git push origin extension-v1.0.0"
    echo ""
    echo "  2. GitHub Actions va automatiquement:"
    echo "     - Builder l'extension et l'APK"
    echo "     - Créer la release avec fichiers ZIP"
    echo "     - Générer les notes de version"
    echo ""
    echo "  3. Partager le lien de téléchargement:"
    echo "     https://github.com/$GITHUB_USER/$REPO_NAME/releases/latest/download/anime-tracker-extension-latest.zip"
    echo ""
    echo "💡 **L'extension est maintenant distribuable professionnellement !**"
}

# Lancement
main "$@"
