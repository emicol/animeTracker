#!/bin/bash

# 🎌 Anime History Tracker - Guide de publication extension GitHub
# Publie l'extension sur GitHub et la rend installable

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

# Préparer l'extension pour publication
prepare_extension() {
    header "📦 Préparation de l'extension pour publication"
    
    # Vérifier qu'on est dans le bon répertoire
    if [ ! -f "package.json" ] || [ ! -d "extension" ]; then
        error "❌ Ce script doit être exécuté depuis la racine du projet anime-history-tracker"
    fi
    
    cd extension
    
    # Vérifier les fichiers essentiels
    required_files=("manifest.json" "background.js" "content.js" "popup.html" "popup.js")
    for file in "${required_files[@]}"; do
        if [ ! -f "$file" ]; then
            error "❌ Fichier manquant: $file"
        fi
    done
    log "✅ Tous les fichiers essentiels présents"
    
    # Vérifier les icônes
    if [ ! -d "icons" ] || [ -z "$(ls -A icons 2>/dev/null)" ]; then
        warn "⚠️  Icônes manquantes - génération automatique..."
        cd ..
        ./fix-icons.sh --generate-only
        cd extension
    fi
    log "✅ Icônes vérifiées"
    
    # Corriger le manifest pour GitHub
    info "🔧 Optimisation du manifest pour GitHub..."
    cat > manifest.json << 'EOF'
{
  "manifest_version": 3,
  "name": "Anime History Tracker",
  "version": "1.0.0",
  "description": "Track your anime viewing history automatically on Anime-Sama",
  
  "permissions": [
    "storage",
    "activeTab",
    "tabs",
    "alarms"
  ],
  
  "host_permissions": [
    "https://anime-sama.fr/*"
  ],
  
  "background": {
    "service_worker": "background.js"
  },
  
  "content_scripts": [
    {
      "matches": [
        "https://anime-sama.fr/catalogue/*"
      ],
      "js": ["content.js"],
      "run_at": "document_idle"
    }
  ],
  
  "action": {
    "default_popup": "popup.html",
    "default_title": "Anime History Tracker"
  },
  
  "icons": {
    "16": "icons/icon16.png",
    "32": "icons/icon32.png",
    "48": "icons/icon48.png",
    "128": "icons/icon128.png"
  },
  
  "externally_connectable": {
    "matches": [
      "https://emicol.github.io/*"
    ]
  },
  
  "homepage_url": "https://github.com/emicol/animeTracker",
  "author": "emicol"
}
EOF
    log "✅ Manifest optimisé pour GitHub"
    
    cd ..
}

# Créer une release GitHub
create_github_release() {
    header "🚀 Création d'une release GitHub"
    
    # Mettre à jour la version
    info "📅 Mise à jour de la version..."
    ./update-version.sh
    
    # Créer le package extension
    info "📦 Création du package extension..."
    cd extension
    
    # Version depuis le manifest
    VERSION=$(grep '"version"' manifest.json | sed 's/.*"version": "\([^"]*\)".*/\1/')
    
    # Créer l'archive ZIP
    ZIP_NAME="anime-tracker-extension-v${VERSION}.zip"
    zip -r "../dist/$ZIP_NAME" . -x "*.zip" "node_modules/*" ".git/*" "*.md"
    
    log "✅ Extension packagée: dist/$ZIP_NAME"
    
    cd ..
    
    # Créer le tag et la release
    info "🏷️  Création du tag Git..."
    git add .
    git commit -m "🔖 Release extension v$VERSION

📦 Extension prête pour installation
🎌 Compatible Anime-Sama.fr
✨ Tracking automatique + PWA sync" || true
    
    git tag "extension-v$VERSION" || warn "⚠️  Tag déjà existant"
    git push origin main
    git push origin "extension-v$VERSION" || warn "⚠️  Tag déjà poussé"
    
    log "✅ Release v$VERSION créée sur GitHub"
    
    echo ""
    echo "🎉 EXTENSION PUBLIÉE SUR GITHUB!"
    echo "================================"
    echo "📦 Fichier: dist/$ZIP_NAME"
    echo "🏷️  Version: $VERSION"
    echo "🔗 GitHub: https://github.com/emicol/animeTracker/releases"
    echo ""
}

# Créer les instructions d'installation
create_installation_guide() {
    header "📚 Création du guide d'installation"
    
    cat > EXTENSION_INSTALL.md << 'EOF'
# 🎌 Installation Extension Anime History Tracker

## 📥 Téléchargement

1. **Téléchargez** la dernière version depuis [GitHub Releases](https://github.com/emicol/animeTracker/releases)
2. **Cherchez** le fichier `anime-tracker-extension-vX.X.X.zip`
3. **Téléchargez** le fichier ZIP

## 🔧 Installation Chrome/Brave

### Méthode 1: Installation directe (Recommandée)

1. **Ouvrez** votre navigateur (Chrome/Brave/Edge)
2. **Allez** dans `chrome://extensions/` (ou `brave://extensions/`)
3. **Activez** le "Mode développeur" (coin supérieur droit)
4. **Cliquez** sur "Charger l'extension non empaquetée"
5. **Sélectionnez** le dossier décompressé de l'extension
6. **L'extension** apparaît dans la barre d'outils ! 🎉

### Méthode 2: Depuis le ZIP

1. **Décompressez** le fichier ZIP téléchargé
2. **Suivez** les étapes de la méthode 1

## ✅ Vérification

1. **Visitez** [Anime-Sama.fr](https://anime-sama.fr)
2. **Regardez** un épisode d'anime
3. **Cliquez** sur l'icône extension (🎌)
4. **Vérifiez** que vos animes apparaissent

## 🌐 Utilisation avec la PWA

1. **Ouvrez** [Anime Tracker PWA](https://emicol.github.io/animeTracker/)
2. **L'extension** se connecte automatiquement
3. **Profitez** de votre historique complet ! 📊

## 🔧 Dépannage

### Extension non détectée
- ✅ Vérifiez que l'extension est **activée**
- ✅ **Rechargez** la page Anime-Sama
- ✅ **Consultez** la console développeur (F12)

### Historique vide
- ✅ **Regardez** au moins 30 secondes d'un épisode
- ✅ **Vérifiez** que vous êtes sur `anime-sama.fr/catalogue/`

### PWA non connectée
- ✅ **Actualisez** la page PWA
- ✅ **Vérifiez** que l'extension est installée et active

## 📱 Versions disponibles

- 🔧 **Extension navigateur** (cette installation)
- 🌐 **PWA** → [emicol.github.io/animeTracker](https://emicol.github.io/animeTracker/)
- 📱 **APK mobile** → Releases GitHub

---

💡 **Besoin d'aide ?** → [Issues GitHub](https://github.com/emicol/animeTracker/issues)
EOF
    
    log "✅ Guide d'installation créé: EXTENSION_INSTALL.md"
}

# Créer un serveur de développement pour tester l'installation
create_dev_server() {
    header "🧪 Serveur de test d'installation"
    
    cat > serve-extension.js << 'EOF'
const http = require('http');
const fs = require('fs');
const path = require('path');

const PORT = 8081;

const server = http.createServer((req, res) => {
    res.setHeader('Access-Control-Allow-Origin', '*');
    res.setHeader('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
    res.setHeader('Access-Control-Allow-Headers', 'Content-Type');
    
    if (req.url === '/') {
        // Page d'installation
        res.writeHead(200, { 'Content-Type': 'text/html; charset=utf-8' });
        res.end(`
<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>🎌 Installation Extension Anime Tracker</title>
    <style>
        body { 
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
            max-width: 800px; 
            margin: 50px auto; 
            padding: 20px;
            background: #f8fafc;
        }
        .container {
            background: white;
            border-radius: 12px;
            padding: 30px;
            box-shadow: 0 4px 6px rgba(0, 0, 0, 0.1);
        }
        .download-btn {
            display: inline-block;
            background: linear-gradient(135deg, #3b82f6, #1d4ed8);
            color: white;
            padding: 15px 30px;
            text-decoration: none;
            border-radius: 8px;
            font-weight: 600;
            margin: 10px 5px;
        }
        .step {
            background: #eff6ff;
            border-left: 4px solid #3b82f6;
            padding: 15px;
            margin: 15px 0;
        }
        .warning {
            background: #fef3c7;
            border-left: 4px solid #f59e0b;
            padding: 15px;
            margin: 15px 0;
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>🎌 Anime History Tracker - Installation Extension</h1>
        
        <div class="warning">
            <strong>⚠️  Mode développeur requis</strong><br>
            Cette extension n'est pas encore sur le Chrome Web Store. 
            L'installation nécessite le mode développeur.
        </div>
        
        <h2>📥 Étape 1: Télécharger</h2>
        <p>Téléchargez la dernière version de l'extension:</p>
        <a href="/download" class="download-btn">📦 Télécharger Extension ZIP</a>
        <a href="https://github.com/emicol/animeTracker/releases" class="download-btn">🔗 GitHub Releases</a>
        
        <h2>🔧 Étape 2: Installation</h2>
        
        <div class="step">
            <strong>1.</strong> Décompressez le fichier ZIP téléchargé
        </div>
        
        <div class="step">
            <strong>2.</strong> Ouvrez <code>chrome://extensions/</code> dans votre navigateur
        </div>
        
        <div class="step">
            <strong>3.</strong> Activez le "Mode développeur" (coin supérieur droit)
        </div>
        
        <div class="step">
            <strong>4.</strong> Cliquez "Charger l'extension non empaquetée"
        </div>
        
        <div class="step">
            <strong>5.</strong> Sélectionnez le dossier décompressé
        </div>
        
        <h2>✅ Étape 3: Test</h2>
        <p>1. Visitez <a href="https://anime-sama.fr" target="_blank">Anime-Sama.fr</a></p>
        <p>2. Regardez un épisode d'anime</p>
        <p>3. Cliquez sur l'icône extension 🎌</p>
        <p>4. Ouvrez la <a href="https://emicol.github.io/animeTracker/" target="_blank">PWA</a></p>
        
        <h2>🚀 Liens utiles</h2>
        <a href="https://emicol.github.io/animeTracker/" class="download-btn">🌐 Ouvrir PWA</a>
        <a href="https://github.com/emicol/animeTracker" class="download-btn">📚 Documentation</a>
    </div>
</body>
</html>
        `);
    } else if (req.url === '/download') {
        // Téléchargement de l'extension
        const zipFiles = fs.readdirSync('dist').filter(f => f.includes('extension') && f.endsWith('.zip'));
        
        if (zipFiles.length > 0) {
            const latestZip = zipFiles.sort().reverse()[0];
            const zipPath = path.join('dist', latestZip);
            
            res.writeHead(200, {
                'Content-Type': 'application/zip',
                'Content-Disposition': `attachment; filename="${latestZip}"`
            });
            
            fs.createReadStream(zipPath).pipe(res);
            console.log(`📦 Extension téléchargée: ${latestZip}`);
        } else {
            res.writeHead(404, { 'Content-Type': 'text/plain' });
            res.end('Extension ZIP non trouvée');
        }
    } else {
        res.writeHead(404, { 'Content-Type': 'text/plain' });
        res.end('404 - Page non trouvée');
    }
});

server.listen(PORT, () => {
    console.log(`🚀 Serveur d'installation extension: http://localhost:${PORT}`);
    console.log(`📦 Instructions d'installation disponibles`);
    console.log(`🎌 Testez l'installation depuis cette page`);
});
EOF
    
    log "✅ Serveur de test créé: serve-extension.js"
    
    # Démarrer le serveur si demandé
    read -p "🚀 Voulez-vous démarrer le serveur de test maintenant ? [y/N]: " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        info "🌐 Démarrage du serveur..."
        node serve-extension.js &
        SERVER_PID=$!
        
        # Ouvrir dans le navigateur
        if command -v xdg-open >/dev/null 2>&1; then
            xdg-open "http://localhost:8081" 2>/dev/null &
        fi
        
        echo ""
        echo "🎉 SERVEUR DE TEST ACTIF!"
        echo "========================"
        echo "🌐 URL: http://localhost:8081"
        echo "📦 Téléchargement: http://localhost:8081/download"
        echo "⏹️  Arrêter: Ctrl+C ou kill $SERVER_PID"
        echo ""
        
        wait $SERVER_PID
    fi
}

# Fonction principale
main() {
    clear
    printf "${PURPLE}%s\n" "🎌 ANIME HISTORY TRACKER - PUBLICATION EXTENSION"
    printf "%s\n" "=================================================="
    printf "${NC}\n"
    
    echo "Ce script va:"
    echo "  1. 📦 Préparer l'extension pour publication"
    echo "  2. 🚀 Créer une release GitHub avec ZIP"
    echo "  3. 📚 Générer les instructions d'installation"
    echo "  4. 🧪 Créer un serveur de test d'installation"
    echo ""
    
    read -p "Continuer ? [y/N]: " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Opération annulée."
        exit 0
    fi
    
    prepare_extension
    create_github_release
    create_installation_guide
    create_dev_server
    
    echo ""
    echo "🎉 EXTENSION PUBLIÉE AVEC SUCCÈS!"
    echo "================================="
    echo ""
    echo "📋 PROCHAINES ÉTAPES:"
    echo "  1. 🔗 Visitez: https://github.com/emicol/animeTracker/releases"
    echo "  2. 📦 Partagez le lien de téléchargement"
    echo "  3. 📚 Utilisez EXTENSION_INSTALL.md comme guide"
    echo "  4. 🧪 Testez avec le serveur local"
    echo ""
    echo "💡 L'extension est maintenant installable par n'importe qui !"
}

# Lancement
main "$@"
