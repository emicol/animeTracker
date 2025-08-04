#!/bin/bash

# 🎌 Anime History Tracker - Serve APK Script
# Démarre un serveur local et génère un QR code pour télécharger l'APK

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

# Vérifier l'environnement
check_environment() {
    if [ ! -d "dist" ]; then
        error "❌ Dossier dist non trouvé - lancez d'abord './build-apk.sh'"
    fi
    
    # Chercher un APK
    APK_FILE=$(find dist -name "*.apk" -type f | head -1)
    if [ -z "$APK_FILE" ]; then
        error "❌ Aucun APK trouvé dans dist/ - lancez d'abord './build-apk.sh'"
    fi
    
    APK_NAME=$(basename "$APK_FILE")
    APK_SIZE=$(du -h "$APK_FILE" | cut -f1)
    
    log "✅ APK trouvé: $APK_NAME ($APK_SIZE)"
}

# Trouver un port disponible
find_available_port() {
    local start_port=${1:-8080}
    local port=$start_port
    
    while [ $port -le 9000 ]; do
        if ! ss -tuln | grep -q ":$port "; then
            echo $port
            return 0
        fi
        port=$((port + 1))
    done
    
    error "❌ Aucun port disponible trouvé entre $start_port et 9000"
}

# Obtenir l'IP locale
get_local_ip() {
    # Essayer différentes méthodes pour obtenir l'IP locale
    local ip
    
    # Méthode 1: ip route (Linux moderne)
    if command -v ip >/dev/null 2>&1; then
        ip=$(ip route get 8.8.8.8 2>/dev/null | grep -oP 'src \K\S+' | head -1)
        if [ -n "$ip" ] && [ "$ip" != "127.0.0.1" ]; then
            echo "$ip"
            return 0
        fi
    fi
    
    # Méthode 2: hostname -I (Ubuntu/Debian)
    if command -v hostname >/dev/null 2>&1; then
        ip=$(hostname -I 2>/dev/null | awk '{print $1}')
        if [ -n "$ip" ] && [ "$ip" != "127.0.0.1" ]; then
            echo "$ip"
            return 0
        fi
    fi
    
    # Méthode 3: ifconfig (classique)
    if command -v ifconfig >/dev/null 2>&1; then
        ip=$(ifconfig 2>/dev/null | grep -Eo 'inet (addr:)?([0-9]*\.){3}[0-9]*' | grep -Eo '([0-9]*\.){3}[0-9]*' | grep -v '127.0.0.1' | head -1)
        if [ -n "$ip" ]; then
            echo "$ip"
            return 0
        fi
    fi
    
    # Fallback
    echo "192.168.1.100"
    warn "⚠️  IP locale non détectée automatiquement - utilisation de 192.168.1.100"
    warn "⚠️  Modifiez manuellement si nécessaire"
}

# Créer le serveur Node.js
create_server() {
    header "🌐 Création du serveur APK"
    
    PORT=$(find_available_port 8080)
    LOCAL_IP=$(get_local_ip)
    
    log "📡 Port choisi: $PORT"
    log "🌍 IP locale: $LOCAL_IP"
    
    # Créer le serveur Node.js temporaire
    cat > serve-apk-temp.js << EOF
const http = require('http');
const fs = require('fs');
const path = require('path');
const url = require('url');

const PORT = $PORT;
const APK_FILE = '$APK_FILE';
const APK_NAME = '$APK_NAME';
const APK_SIZE = '$APK_SIZE';

const server = http.createServer((req, res) => {
    const parsedUrl = url.parse(req.url, true);
    const pathname = parsedUrl.pathname;
    
    // CORS headers pour tous les requests
    res.setHeader('Access-Control-Allow-Origin', '*');
    res.setHeader('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
    res.setHeader('Access-Control-Allow-Headers', 'Content-Type');
    
    console.log(\`📱 [\${new Date().toLocaleTimeString()}] \${req.method} \${pathname} - \${req.headers['user-agent'] || 'Unknown'}\`);
    
    if (pathname === '/') {
        // Page d'accueil avec infos sur l'APK
        res.writeHead(200, { 'Content-Type': 'text/html; charset=utf-8' });
        res.end(\`
<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>🎌 Anime History Tracker - Download APK</title>
    <style>
        body { 
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
            max-width: 600px; 
            margin: 50px auto; 
            padding: 20px;
            background: #f8fafc;
            line-height: 1.6;
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
            font-size: 18px;
            margin: 20px 0;
            text-align: center;
            transition: transform 0.2s;
        }
        .download-btn:hover {
            transform: translateY(-2px);
        }
        .info {
            background: #eff6ff;
            border: 1px solid #bfdbfe;
            border-radius: 8px;
            padding: 15px;
            margin: 20px 0;
        }
        .warning {
            background: #fef3c7;
            border: 1px solid #f59e0b;
            border-radius: 8px;
            padding: 15px;
            margin: 20px 0;
        }
        h1 { color: #1e293b; margin-bottom: 10px; }
        h2 { color: #3b82f6; margin-top: 30px; }
        .stats { display: flex; gap: 20px; flex-wrap: wrap; }
        .stat { background: #f1f5f9; padding: 10px; border-radius: 6px; flex: 1; min-width: 120px; }
        .qr-info { text-align: center; margin: 20px 0; color: #6b7280; }
    </style>
</head>
<body>
    <div class="container">
        <h1>🎌 Anime History Tracker</h1>
        <p>Téléchargez la dernière version de l'application mobile</p>
        
        <div class="stats">
            <div class="stat">
                <strong>📦 Fichier:</strong><br>\${APK_NAME}
            </div>
            <div class="stat">
                <strong>📊 Taille:</strong><br>\${APK_SIZE}
            </div>
            <div class="stat">
                <strong>📅 Généré:</strong><br>\${new Date().toLocaleDateString('fr-FR')}
            </div>
        </div>
        
        <a href="/download" class="download-btn">
            📱 Télécharger APK
        </a>
        
        <div class="info">
            <h2>📋 Instructions d'installation:</h2>
            <ol>
                <li>Téléchargez l'APK en cliquant sur le bouton ci-dessus</li>
                <li>Activez "Sources inconnues" dans les paramètres Android</li>
                <li>Ouvrez le fichier téléchargé pour installer</li>
                <li>Profitez de votre tracker d'animes ! 🎌</li>
            </ol>
        </div>
        
        <div class="warning">
            <strong>⚠️  Sécurité:</strong> Cet APK est généré localement depuis votre code source. 
            Il est sûr tant que votre réseau local est sécurisé.
        </div>
        
        <div class="qr-info">
            <small>💡 Vous avez scanné un QR code pour arriver ici</small>
        </div>
    </div>
</body>
</html>
        \`);
        
    } else if (pathname === '/download') {
        // Téléchargement de l'APK
        if (fs.existsSync(APK_FILE)) {
            const stat = fs.statSync(APK_FILE);
            
            res.writeHead(200, {
                'Content-Type': 'application/vnd.android.package-archive',
                'Content-Disposition': \`attachment; filename="\${APK_NAME}"\`,
                'Content-Length': stat.size
            });
            
            const stream = fs.createReadStream(APK_FILE);
            stream.pipe(res);
            
            console.log(\`📦 Téléchargement démarré: \${APK_NAME}\`);
        } else {
            res.writeHead(404, { 'Content-Type': 'text/plain' });
            res.end('APK non trouvé');
        }
        
    } else if (pathname === '/info') {
        // Informations JSON pour les développeurs
        res.writeHead(200, { 'Content-Type': 'application/json' });
        res.end(JSON.stringify({
            name: 'Anime History Tracker',
            apk: APK_NAME,
            size: APK_SIZE,
            downloadUrl: \`http://$LOCAL_IP:\${PORT}/download\`,
            generated: new Date().toISOString()
        }, null, 2));
        
    } else {
        res.writeHead(404, { 'Content-Type': 'text/plain' });
        res.end('404 - Page non trouvée');
    }
});

server.listen(PORT, '0.0.0.0', () => {
    console.log(\`🚀 Serveur APK démarré sur http://localhost:\${PORT}\`);
    console.log(\`🌐 Accessible sur le réseau: http://$LOCAL_IP:\${PORT}\`);
    console.log(\`📱 URL de téléchargement: http://$LOCAL_IP:\${PORT}/download\`);
    console.log(\`\nAppuyez sur Ctrl+C pour arrêter le serveur\`);
});

// Gestion de l'arrêt propre
process.on('SIGINT', () => {
    console.log(\`\n\n🛑 Serveur arrêté - Merci d'avoir utilisé Anime History Tracker!\`);
    process.exit(0);
});
EOF
    
    log "✅ Serveur créé: serve-apk-temp.js"
}

# Générer le QR code
generate_qr_code() {
    header "📱 Génération du QR Code"
    
    QR_URL="http://$LOCAL_IP:$PORT"
    QR_FILE="qr-code-apk.png"
    
    # Vérifier si qrcode est installé
    if ! command -v qrcode >/dev/null 2>&1; then
        info "📦 Installation du générateur QR code..."
        npm install -g qrcode-terminal qrcode 2>/dev/null || {
            warn "⚠️  Impossible d'installer qrcode globalement"
            info "💡 Installation locale..."
            npm install qrcode-terminal qrcode
        }
    fi
    
    # Générer QR code en image
    if command -v qrcode >/dev/null 2>&1; then
        qrcode "$QR_URL" --output "$QR_FILE" --width 300
        log "✅ QR Code généré: $QR_FILE"
    elif [ -f "node_modules/.bin/qrcode" ]; then
        npx qrcode "$QR_URL" --output "$QR_FILE" --width 300
        log "✅ QR Code généré: $QR_FILE"
    fi
    
    # Afficher QR code en terminal
    if command -v qrcode-terminal >/dev/null 2>&1; then
        echo ""
        echo "📱 QR CODE POUR TÉLÉCHARGEMENT:"
        echo "=============================="
        qrcode-terminal "$QR_URL" --small
    elif [ -f "node_modules/.bin/qrcode-terminal" ]; then
        echo ""
        echo "📱 QR CODE POUR TÉLÉCHARGEMENT:"
        echo "=============================="
        npx qrcode-terminal "$QR_URL" --small
    else
        warn "⚠️  QR code terminal non disponible"
    fi
    
    echo ""
    log "🔗 URL directe: $QR_URL"
    log "📱 Téléchargement: $QR_URL/download"
}

# Ouvrir le QR code et démarrer le serveur
start_server() {
    header "🚀 Démarrage du serveur"
    
    # Ouvrir l'image QR code si possible
    if [ -f "$QR_FILE" ]; then
        if command -v xdg-open >/dev/null 2>&1; then
            xdg-open "$QR_FILE" 2>/dev/null &
            log "✅ QR Code ouvert dans le visualiseur d'images"
        elif command -v open >/dev/null 2>&1; then
            open "$QR_FILE" 2>/dev/null &
            log "✅ QR Code ouvert dans le visualiseur d'images"
        fi
    fi
    
    # Ouvrir le navigateur sur l'URL locale
    if command -v xdg-open >/dev/null 2>&1; then
        xdg-open "http://localhost:$PORT" 2>/dev/null &
    elif command -v open >/dev/null 2>&1; then
        open "http://localhost:$PORT" 2>/dev/null &
    fi
    
    echo ""
    info "🌟 SERVEUR APK PRÊT!"
    info "📱 Scannez le QR code avec votre téléphone"
    info "🌐 Ou allez sur: http://$LOCAL_IP:$PORT"
    info "⏹️  Ctrl+C pour arrêter"
    echo ""
    
    # Démarrer le serveur Node.js
    node serve-apk-temp.js
}

# Nettoyage à la sortie
cleanup() {
    info "🧹 Nettoyage des fichiers temporaires..."
    rm -f serve-apk-temp.js
    log "✅ Nettoyage terminé"
}

trap cleanup EXIT

# Fonction principale
main() {
    clear
    printf "${PURPLE}%s\n" "🎌 ANIME HISTORY TRACKER - SERVEUR APK"
    printf "%s\n" "========================================"
    printf "${NC}\n"
    
    check_environment
    create_server
    generate_qr_code
    start_server
}

# Gestion des options
case "${1:-}" in
    --port)
        if [ -z "$2" ]; then
            error "❌ Port manquant. Usage: $0 --port 8080"
        fi
        PORT_OVERRIDE="$2"
        main
        ;;
    --help|-h)
        echo "Usage: $0 [OPTIONS]"
        echo ""
        echo "Démarre un serveur local pour télécharger l'APK via QR code"
        echo ""
        echo "Options:"
        echo "  --port NUM      Forcer un port spécifique"
        echo "  --help, -h      Afficher cette aide"
        echo ""
        echo "Le serveur trouve automatiquement un port libre (8080-9000)"
        exit 0
        ;;
    "")
        main
        ;;
    *)
        error "Option inconnue: $1 (utilisez --help pour l'aide)"
        ;;
esac
