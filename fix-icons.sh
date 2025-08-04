#!/bin/bash

# 🎌 Anime History Tracker - Fix Icons Script
# Diagnostique et corrige les problèmes d'icônes

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

# Diagnostic des icônes
diagnose_icons() {
    header "🔍 Diagnostic des icônes"
    
    echo "📋 ÉTAT ACTUEL DES ICÔNES:"
    echo "=========================="
    
    # Icône source
    if [ -f "assets/icons/logo.png" ]; then
        SIZE=$(du -h "assets/icons/logo.png" | cut -f1)
        log "✅ Icône source: assets/icons/logo.png ($SIZE)"
        SOURCE_ICON="assets/icons/logo.png"
    elif [ -f "../icone.png" ]; then
        warn "⚠️  Icône source dans le dossier parent: ../icone.png"
        SOURCE_ICON="../icone.png"
    else
        error "❌ Aucune icône source trouvée (cherchée: assets/icons/logo.png, ../icone.png)"
    fi
    
    # Extension icons
    echo ""
    echo "🔧 ICÔNES EXTENSION:"
    for size in 16 32 48 128; do
        icon="extension/icons/icon${size}.png"
        if [ -f "$icon" ]; then
            log "  ✅ $icon"
        else
            warn "  ❌ $icon manquant"
        fi
    done
    
    # PWA icons
    echo ""
    echo "🌐 ICÔNES PWA:"
    for icon in "pwa/public/icons/icon-192.png" "pwa/public/icons/icon-512.png" "pwa/public/favicon.ico"; do
        if [ -f "$icon" ]; then
            log "  ✅ $icon"
        else
            warn "  ❌ $icon manquant"
        fi
    done
    
    # Mobile icons
    echo ""
    echo "📱 ICÔNES MOBILE:"
    for icon in "mobile/resources/icon-192.png" "mobile/resources/icon-512.png"; do
        if [ -f "$icon" ]; then
            log "  ✅ $icon"
        else
            warn "  ❌ $icon manquant"
        fi
    done
    
    # Capacitor icons (Android)
    echo ""
    echo "🤖 ICÔNES ANDROID (si générées):"
    
    android_icons_found=false
    for dir in "mobile/android/app/src/main/res/mipmap-hdpi" "mobile/android/app/src/main/res/mipmap-mdpi" "mobile/android/app/src/main/res/mipmap-xhdpi" "mobile/android/app/src/main/res/mipmap-xxhdpi" "mobile/android/app/src/main/res/mipmap-xxxhdpi"; do
        if [ -d "$dir" ] && [ -n "$(ls -A "$dir" 2>/dev/null)" ]; then
            log "  ✅ $dir ($(ls "$dir" | wc -l) fichiers)"
            android_icons_found=true
        fi
    done
    
    if [ "$android_icons_found" = "false" ]; then
        warn "  ⚠️  Icônes Android natives non générées (normal si pas encore buildé)"
    fi
}

# Vérifier ImageMagick
check_imagemagick() {
    header "🎨 Vérification ImageMagick"
    
    if command -v convert >/dev/null 2>&1; then
        MAGICK_CMD="convert"
        VERSION=$(convert --version | head -1 | grep -o 'ImageMagick [0-9]\+\.[0-9]\+\.[0-9]\+' || echo "ImageMagick (version inconnue)")
        log "✅ $VERSION disponible (commande: convert)"
    elif command -v magick >/dev/null 2>&1; then
        MAGICK_CMD="magick"
        VERSION=$(magick --version | head -1 | grep -o 'ImageMagick [0-9]\+\.[0-9]\+\.[0-9]\+' || echo "ImageMagick (version inconnue)")
        log "✅ $VERSION disponible (commande: magick)"
    else
        error "❌ ImageMagick non installé. Installez avec: sudo apt install imagemagick"
    fi
}

# Générer toutes les icônes
generate_all_icons() {
    header "🏭 Génération de toutes les icônes"
    
    # Créer tous les dossiers nécessaires
    mkdir -p extension/icons
    mkdir -p pwa/public/icons
    mkdir -p mobile/resources
    mkdir -p assets/icons
    
    # Copier l'icône source si nécessaire
    if [ "$SOURCE_ICON" != "assets/icons/logo.png" ]; then
        cp "$SOURCE_ICON" assets/icons/logo.png
        log "✅ Icône source copiée vers assets/icons/logo.png"
    fi
    
    SOURCE="assets/icons/logo.png"
    
    info "🔧 Génération des icônes extension..."
    $MAGICK_CMD "$SOURCE" -resize 16x16 extension/icons/icon16.png
    $MAGICK_CMD "$SOURCE" -resize 32x32 extension/icons/icon32.png
    $MAGICK_CMD "$SOURCE" -resize 48x48 extension/icons/icon48.png
    $MAGICK_CMD "$SOURCE" -resize 128x128 extension/icons/icon128.png
    log "✅ Icônes extension générées (16, 32, 48, 128px)"
    
    info "🌐 Génération des icônes PWA..."
    $MAGICK_CMD "$SOURCE" -resize 192x192 pwa/public/icons/icon-192.png
    $MAGICK_CMD "$SOURCE" -resize 512x512 pwa/public/icons/icon-512.png
    $MAGICK_CMD "$SOURCE" -resize 32x32 pwa/public/favicon.ico
    log "✅ Icônes PWA générées (192, 512px + favicon)"
    
    info "📱 Génération des icônes mobiles..."
    cp pwa/public/icons/icon-192.png mobile/resources/icon-192.png
    cp pwa/public/icons/icon-512.png mobile/resources/icon-512.png
    log "✅ Icônes mobiles copiées"
    
    # Icônes supplémentaires pour assets
    info "📦 Génération des icônes assets..."
    $MAGICK_CMD "$SOURCE" -resize 64x64 assets/icons/icon-64.png
    $MAGICK_CMD "$SOURCE" -resize 256x256 assets/icons/icon-256.png
    $MAGICK_CMD "$SOURCE" -resize 1024x1024 assets/icons/icon-1024.png
    log "✅ Icônes assets générées (64, 256, 1024px)"
}

# Vérifier et corriger les manifests
fix_manifests() {
    header "📝 Vérification des manifests"
    
    # Extension manifest
    if [ -f "extension/manifest.json" ]; then
        if grep -q '"icons"' extension/manifest.json; then
            log "✅ Extension manifest contient déjà la section icons"
        else
            info "🔧 Ajout de la section icons au manifest extension..."
            # Créer une version corrigée du manifest
            cat > extension/manifest.json.tmp << 'EOF'
{
  "manifest_version": 3,
  "name": "Anime History Tracker",
  "version": "1.0.0",
  "description": "Track your anime viewing history automatically",
  
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
    "default_title": "Anime History"
  },
  
  "icons": {
    "16": "icons/icon16.png",
    "32": "icons/icon32.png",
    "48": "icons/icon48.png",
    "128": "icons/icon128.png"
  },
  
  "externally_connectable": {
    "matches": [
      "https://localhost:3000/*",
      "https://*.github.io/*"
    ]
  }
}
EOF
            mv extension/manifest.json.tmp extension/manifest.json
            log "✅ Extension manifest mis à jour avec les icônes"
        fi
    fi
    
    # PWA manifest
    if [ -f "pwa/public/manifest.json" ]; then
        if grep -q '"icons"' pwa/public/manifest.json; then
            log "✅ PWA manifest contient déjà la section icons"
        else
            info "🔧 Ajout de la section icons au manifest PWA..."
            cat > pwa/public/manifest.json.tmp << 'EOF'
{
  "name": "Anime History Tracker",
  "short_name": "AnimeTracker",
  "description": "Track your anime viewing history automatically",
  "start_url": "/",
  "display": "standalone",
  "theme_color": "#3b82f6",
  "background_color": "#ffffff",
  "icons": [
    {
      "src": "icons/icon-192.png",
      "sizes": "192x192",
      "type": "image/png",
      "purpose": "any maskable"
    },
    {
      "src": "icons/icon-512.png",
      "sizes": "512x512",
      "type": "image/png",
      "purpose": "any maskable"
    }
  ]
}
EOF
            mv pwa/public/manifest.json.tmp pwa/public/manifest.json
            log "✅ PWA manifest mis à jour avec les icônes"
        fi
    else
        warn "⚠️  PWA manifest manquant - création..."
        mkdir -p pwa/public
        cat > pwa/public/manifest.json << 'EOF'
{
  "name": "Anime History Tracker",
  "short_name": "AnimeTracker",
  "description": "Track your anime viewing history automatically",
  "start_url": "/",
  "display": "standalone",
  "theme_color": "#3b82f6",
  "background_color": "#ffffff",
  "icons": [
    {
      "src": "icons/icon-192.png",
      "sizes": "192x192",
      "type": "image/png",
      "purpose": "any maskable"
    },
    {
      "src": "icons/icon-512.png",
      "sizes": "512x512",
      "type": "image/png",
      "purpose": "any maskable"
    }
  ]
}
EOF
        log "✅ PWA manifest créé avec les icônes"
    fi
}

# Vérifier les icônes dans le HTML
fix_html_icons() {
    header "🌐 Vérification des icônes dans HTML"
    
    # Créer index.html s'il n'existe pas
    if [ ! -f "pwa/index.html" ]; then
        warn "⚠️  pwa/index.html manquant - création..."
        mkdir -p pwa
        cat > pwa/index.html << 'EOF'
<!doctype html>
<html lang="fr">
  <head>
    <meta charset="UTF-8" />
    <link rel="icon" type="image/x-icon" href="/favicon.ico" />
    <link rel="apple-touch-icon" href="/icons/icon-192.png" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <meta name="description" content="Track your anime viewing history automatically" />
    <meta name="theme-color" content="#3b82f6" />
    <link rel="manifest" href="/manifest.json" />
    <title>🎌 Anime History Tracker</title>
  </head>
  <body>
    <div id="root"></div>
    <script type="module" src="/src/main.jsx"></script>
  </body>
</html>
EOF
        log "✅ pwa/index.html créé avec toutes les références d'icônes"
        return
    fi
    
    # Vérifier et corriger le HTML existant
    if grep -q "favicon.ico" pwa/index.html; then
        log "✅ Favicon référencé dans index.html"
    else
        info "🔧 Ajout du favicon dans index.html..."
        sed -i '/<head>/a\    <link rel="icon" type="image/x-icon" href="/favicon.ico">' pwa/index.html
        log "✅ Favicon ajouté à index.html"
    fi
    
    if grep -q "apple-touch-icon" pwa/index.html; then
        log "✅ Apple touch icon référencé"
    else
        info "🔧 Ajout de l'apple touch icon..."
        sed -i '/<head>/a\    <link rel="apple-touch-icon" href="/icons/icon-192.png">' pwa/index.html
        log "✅ Apple touch icon ajouté"
    fi
    
    if grep -q "manifest.json" pwa/index.html; then
        log "✅ Manifest PWA référencé"
    else
        info "🔧 Ajout du manifest PWA..."
        sed -i '/<head>/a\    <link rel="manifest" href="/manifest.json">' pwa/index.html
        log "✅ Manifest PWA ajouté"
    fi
}

# Générer les icônes Android natives (si Capacitor est configuré)
generate_android_icons() {
    header "🤖 Génération des icônes Android natives"
    
    if [ -d "mobile/android" ]; then
        info "📱 Génération des icônes Android via Capacitor..."
        cd mobile
        
        # Timeout pour éviter les blocages
        timeout_duration=30
        
        # Vérifier si cordova-res est installé avec timeout
        info "🔍 Vérification de cordova-res..."
        if timeout $timeout_duration npx cordova-res --version >/dev/null 2>&1; then
            log "✅ cordova-res disponible"
        else
            warn "⚠️  cordova-res non disponible ou timeout"
            info "⏩ Génération manuelle des icônes Android de base..."
            
            # Créer les dossiers Android manuellement
            mkdir -p android/app/src/main/res/mipmap-hdpi
            mkdir -p android/app/src/main/res/mipmap-mdpi  
            mkdir -p android/app/src/main/res/mipmap-xhdpi
            mkdir -p android/app/src/main/res/mipmap-xxhdpi
            mkdir -p android/app/src/main/res/mipmap-xxxhdpi
            
            # Générer les icônes Android avec ImageMagick
            if [ -f "resources/icon-512.png" ]; then
                source_icon="resources/icon-512.png"
            elif [ -f "../assets/icons/logo.png" ]; then
                source_icon="../assets/icons/logo.png"
            else
                warn "⚠️  Aucune icône source trouvée pour Android"
                cd ..
                return 1
            fi
            
            info "🎨 Génération manuelle des icônes Android..."
            $MAGICK_CMD "$source_icon" -resize 72x72 android/app/src/main/res/mipmap-hdpi/ic_launcher.png
            $MAGICK_CMD "$source_icon" -resize 48x48 android/app/src/main/res/mipmap-mdpi/ic_launcher.png
            $MAGICK_CMD "$source_icon" -resize 96x96 android/app/src/main/res/mipmap-xhdpi/ic_launcher.png
            $MAGICK_CMD "$source_icon" -resize 144x144 android/app/src/main/res/mipmap-xxhdpi/ic_launcher.png
            $MAGICK_CMD "$source_icon" -resize 192x192 android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png
            
            # Icônes rondes aussi
            $MAGICK_CMD "$source_icon" -resize 72x72 android/app/src/main/res/mipmap-hdpi/ic_launcher_round.png
            $MAGICK_CMD "$source_icon" -resize 48x48 android/app/src/main/res/mipmap-mdpi/ic_launcher_round.png
            $MAGICK_CMD "$source_icon" -resize 96x96 android/app/src/main/res/mipmap-xhdpi/ic_launcher_round.png
            $MAGICK_CMD "$source_icon" -resize 144x144 android/app/src/main/res/mipmap-xxhdpi/ic_launcher_round.png
            $MAGICK_CMD "$source_icon" -resize 192x192 android/app/src/main/res/mipmap-xxxhdpi/ic_launcher_round.png
            
            log "✅ Icônes Android générées manuellement"
            cd ..
            return 0
        fi
        
        # Essayer cordova-res avec timeout
        if [ -f "resources/icon-512.png" ]; then
            info "🚀 Lancement cordova-res avec timeout ($timeout_duration secondes)..."
            
            if timeout $timeout_duration npx cordova-res android --skip-config --copy 2>/dev/null; then
                log "✅ Icônes Android natives générées via cordova-res"
            else
                warn "⚠️  cordova-res timeout ou échoué - utilisation méthode manuelle"
                
                # Fallback vers méthode manuelle
                mkdir -p android/app/src/main/res/mipmap-hdpi
                mkdir -p android/app/src/main/res/mipmap-mdpi  
                mkdir -p android/app/src/main/res/mipmap-xhdpi
                mkdir -p android/app/src/main/res/mipmap-xxhdpi
                mkdir -p android/app/src/main/res/mipmap-xxxhdpi
                
                source_icon="resources/icon-512.png"
                $MAGICK_CMD "$source_icon" -resize 72x72 android/app/src/main/res/mipmap-hdpi/ic_launcher.png
                $MAGICK_CMD "$source_icon" -resize 48x48 android/app/src/main/res/mipmap-mdpi/ic_launcher.png
                $MAGICK_CMD "$source_icon" -resize 96x96 android/app/src/main/res/mipmap-xhdpi/ic_launcher.png
                $MAGICK_CMD "$source_icon" -resize 144x144 android/app/src/main/res/mipmap-xxhdpi/ic_launcher.png
                $MAGICK_CMD "$source_icon" -resize 192x192 android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png
                
                log "✅ Icônes Android générées en méthode de secours"
            fi
        else
            warn "⚠️  resources/icon-512.png manquant pour cordova-res"
        fi
        
        cd ..
    else
        info "⏩ Dossier Android non trouvé - sera créé au premier build APK"
        warn "💡 Lancez './build-apk.sh' d'abord pour créer la structure Android"
    fi
}

# Résumé final
show_icon_summary() {
    header "📊 Résumé des icônes"
    
    echo "✅ ICÔNES GÉNÉRÉES:"
    echo "==================="
    
    # Compter les icônes générées
    extension_count=$(find extension/icons -name "*.png" 2>/dev/null | wc -l)
    pwa_count=$(find pwa/public/icons -name "*.png" 2>/dev/null | wc -l)
    mobile_count=$(find mobile/resources -name "*.png" 2>/dev/null | wc -l)
    
    printf "🔧 Extension:     %d icônes\n" "$extension_count"
    printf "🌐 PWA:           %d icônes + favicon\n" "$pwa_count"
    printf "📱 Mobile:        %d icônes\n" "$mobile_count"
    
    if [ -d "mobile/android/app/src/main/res" ]; then
        android_count=$(find mobile/android/app/src/main/res -name "*.png" 2>/dev/null | wc -l)
        printf "🤖 Android:       %d icônes natives\n" "$android_count"
    fi
    
    echo ""
    echo "🚀 PROCHAINES ÉTAPES:"
    echo "  1. ./build-apk.sh     # Rebuild avec les nouvelles icônes"
    echo "  2. Tester l'extension et la PWA"
    echo "  3. Vérifier les icônes sur mobile"
    
    if [ -f "pwa/public/favicon.ico" ]; then
        echo ""
        echo "💡 Favicon généré: pwa/public/favicon.ico"
        echo "   Il apparaîtra dans l'onglet du navigateur"
    fi
}

# Fonction principale
main() {
    clear
    printf "${PURPLE}%s\n" "🎌 ANIME HISTORY TRACKER - FIX ICONS"
    printf "%s\n" "====================================="
    printf "${NC}\n"
    
    # Vérifier qu'on est dans le bon répertoire
    if [ ! -f "package.json" ]; then
        error "❌ Ce script doit être exécuté depuis la racine du projet anime-history-tracker"
    fi
    
    diagnose_icons
    check_imagemagick
    generate_all_icons
    fix_manifests
    fix_html_icons
    generate_android_icons
    show_icon_summary
}

# Gestion des options
case "${1:-}" in
    --diagnose-only)
        diagnose_icons
        exit 0
        ;;
    --generate-only)
        check_imagemagick
        generate_all_icons
        exit 0
        ;;
    --help|-h)
        echo "Usage: $0 [OPTIONS]"
        echo ""
        echo "Diagnostique et corrige les problèmes d'icônes"
        echo ""
        echo "Options:"
        echo "  --diagnose-only   Diagnostic uniquement"
        echo "  --generate-only   Génération uniquement"
        echo "  --help, -h        Afficher cette aide"
        echo ""
        echo "Sans option: Diagnostic complet + correction"
        exit 0
        ;;
    "")
        main
        ;;
    *)
        error "Option inconnue: $1 (utilisez --help pour l'aide)"
        ;;
esac
