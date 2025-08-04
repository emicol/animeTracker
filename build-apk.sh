#!/bin/bash

# 🎌 Anime History Tracker - Build APK Script
# Compile et génère un APK signé prêt pour distribution

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
    # Vérifier qu'on est dans le bon répertoire
    if [ ! -f "package.json" ] || [ ! -d "mobile" ]; then
        error "❌ Ce script doit être exécuté depuis la racine du projet anime-history-tracker"
    fi
    
    # Vérifier Node.js
    if ! node --version >/dev/null 2>&1; then
        error "❌ Node.js non trouvé - requis pour le build"
    fi
    
    # Vérifier npm
    if ! npm --version >/dev/null 2>&1; then
        error "❌ npm non trouvé - requis pour le build"
    fi
    
    # Vérifier que le dossier mobile existe
    if [ ! -d "mobile" ]; then
        error "❌ Dossier mobile non trouvé"
    fi
    
    # Vérification intelligente des dépendances PWA
    if [ ! -d "pwa/node_modules" ] || [ ! -f "pwa/package-lock.json" ] || [ "pwa/package.json" -nt "pwa/package-lock.json" ]; then
        warn "⚠️  Dépendances PWA à installer/mettre à jour"
        cd pwa && npm install && cd ..
        log "✅ Dépendances PWA installées"
    fi
    
    # Vérification intelligente des dépendances mobile
    if [ ! -d "mobile/node_modules" ] || [ ! -f "mobile/package-lock.json" ] || [ "mobile/package.json" -nt "mobile/package-lock.json" ]; then
        warn "⚠️  Dépendances mobile à installer/mettre à jour"
        cd mobile && npm install && cd ..
        log "✅ Dépendances mobile installées"
    fi
    
    log "✅ Environnement vérifié"
}

# Nettoyer les builds précédents
clean_previous_builds() {
    header "🧹 Nettoyage des builds précédents"
    
    # Nettoyer PWA
    if [ -d "pwa/dist" ]; then
        rm -rf pwa/dist
        log "✅ Cache PWA nettoyé"
    fi
    
    # Nettoyer mobile www
    if [ -d "mobile/www" ]; then
        rm -rf mobile/www/*
        log "✅ Cache mobile nettoyé"
    fi
    
    # Nettoyer Android build
    if [ -d "mobile/android/app/build" ]; then
        rm -rf mobile/android/app/build
        log "✅ Cache Android nettoyé"
    fi
    
    # Créer les dossiers nécessaires
    mkdir -p mobile/www
    mkdir -p dist
}

# Build de la PWA
build_pwa() {
    header "⚛️  Build PWA React"
    
    cd pwa
    
    info "📦 Installation/mise à jour des dépendances PWA..."
    npm install
    
    info "🏗️  Compilation PWA pour production..."
    npm run build
    
    if [ ! -d "dist" ] || [ -z "$(ls -A dist)" ]; then
        error "❌ Échec du build PWA - dossier dist vide"
    fi
    
    log "✅ PWA compilée avec succès"
    
    cd ..
}

# Copier la PWA vers mobile
sync_pwa_to_mobile() {
    header "📱 Synchronisation PWA → Mobile"
    
    # Copier les fichiers de la PWA vers le dossier mobile
    cp -r pwa/dist/* mobile/www/
    
    # Vérifier que les fichiers sont copiés
    if [ ! -f "mobile/www/index.html" ]; then
        error "❌ Échec de la copie PWA vers mobile"
    fi
    
    log "✅ PWA synchronisée vers mobile"
}

# Synchronisation Capacitor
sync_capacitor() {
    header "⚡ Synchronisation Capacitor"
    
    cd mobile
    
    # Vérifier si la plateforme Android existe
    if [ ! -d "android" ]; then
        info "🤖 Ajout de la plateforme Android..."
        npx cap add android
        log "✅ Plateforme Android ajoutée"
    fi
    
    info "🔄 Capacitor sync..."
    npx cap sync android
    
    log "✅ Capacitor synchronisé"
    
    cd ..
}

# Vérifier la configuration Android
check_android_config() {
    header "🤖 Vérification configuration Android"
    
    # Vérifier que le dossier Android existe
    if [ ! -d "mobile/android" ]; then
        warn "⚠️  Dossier Android manquant - génération automatique..."
        cd mobile
        npx cap add android
        cd ..
    fi
    
    # Vérifier le build.gradle
    GRADLE_FILE="mobile/android/app/build.gradle"
    if [ ! -f "$GRADLE_FILE" ]; then
        warn "⚠️  build.gradle manquant - configuration par défaut"
        
        # Créer un build.gradle basique
        mkdir -p "mobile/android/app"
        cat > "$GRADLE_FILE" << 'EOF'
apply plugin: 'com.android.application'

android {
    compileSdkVersion 34
    namespace "com.emicol.animetracker"

    defaultConfig {
        applicationId "com.emicol.animetracker"
        minSdkVersion 22
        targetSdkVersion 34
        versionCode 1
        versionName "1.0.0"
    }

    buildTypes {
        release {
            minifyEnabled false
            proguardFiles getDefaultProguardFile('proguard-android-optimize.txt'), 'proguard-rules.pro'
        }
    }
}

dependencies {
    implementation project(':capacitor-android')
    implementation 'androidx.appcompat:appcompat:1.6.1'
    implementation 'com.google.android.material:material:1.9.0'
}
EOF
        log "✅ build.gradle créé avec configuration de base"
    fi
    
    # Vérifier les permissions Android
    MANIFEST_FILE="mobile/android/app/src/main/AndroidManifest.xml"
    if [ -f "$MANIFEST_FILE" ]; then
        log "✅ AndroidManifest.xml trouvé"
    else
        warn "⚠️  AndroidManifest.xml sera généré par Capacitor"
    fi
    
    log "✅ Configuration Android vérifiée"
}

# Build APK
build_android_apk() {
    header "🏗️  Build APK Android"
    
    cd mobile/android
    
    # Vérifier que gradlew existe
    if [ ! -f "./gradlew" ]; then
        error "❌ gradlew non trouvé - vérifiez l'installation Capacitor Android"
    fi
    
    # Rendre gradlew exécutable
    chmod +x ./gradlew
    
    info "🔨 Compilation APK debug..."
    ./gradlew assembleDebug
    
    # Vérifier si on peut faire un build release
    if grep -q "signingConfigs" app/build.gradle; then
        info "🔐 Configuration de signature trouvée - build release..."
        ./gradlew assembleRelease
        
        RELEASE_APK="app/build/outputs/apk/release/app-release.apk"
        if [ -f "$RELEASE_APK" ]; then
            APK_TYPE="release"
            APK_PATH="$RELEASE_APK"
            log "✅ APK Release généré"
        else
            warn "⚠️  Échec build release - utilisation du debug"
            APK_TYPE="debug"
            APK_PATH="app/build/outputs/apk/debug/app-debug.apk"
        fi
    else
        info "🔓 Pas de signature configurée - build debug uniquement"
        APK_TYPE="debug"
        APK_PATH="app/build/outputs/apk/debug/app-debug.apk"
    fi
    
    cd ../..
    
    # Vérifier que l'APK existe
    if [ ! -f "mobile/android/$APK_PATH" ]; then
        error "❌ Échec de la génération APK"
    fi
    
    log "✅ APK $APK_TYPE généré: $APK_PATH"
}

# Copier l'APK vers dist
distribute_apk() {
    header "📦 Distribution APK"
    
    SOURCE_APK="mobile/android/$APK_PATH"
    TIMESTAMP=$(date +%Y%m%d-%H%M%S)
    VERSION=$(grep '"version"' package.json | sed 's/.*"version": "\([^"]*\)".*/\1/')
    
    # Nom de fichier intelligent
    if [ "$APK_TYPE" = "release" ]; then
        FINAL_NAME="anime-tracker-v${VERSION}-${TIMESTAMP}.apk"
        LATEST_NAME="anime-tracker-release.apk"
    else
        FINAL_NAME="anime-tracker-v${VERSION}-debug-${TIMESTAMP}.apk"
        LATEST_NAME="anime-tracker-debug.apk"
    fi
    
    # Copier vers dist
    cp "$SOURCE_APK" "dist/$FINAL_NAME"
    cp "$SOURCE_APK" "dist/$LATEST_NAME"
    
    # Informations sur l'APK
    APK_SIZE=$(du -h "dist/$FINAL_NAME" | cut -f1)
    
    log "✅ APK copié vers dist/"
    info "📱 Fichier: $FINAL_NAME"
    info "📊 Taille: $APK_SIZE"
    info "🔗 Lien rapide: dist/$LATEST_NAME"
}

# Afficher les informations finales
show_summary() {
    header "🎉 BUILD APK TERMINÉ AVEC SUCCÈS"
    
    echo "📊 RÉSUMÉ DU BUILD:"
    echo "==================="
    printf "📱 Type APK:        %s\n" "$APK_TYPE"
    printf "📦 Fichier:         %s\n" "$FINAL_NAME"
    printf "📊 Taille:          %s\n" "$APK_SIZE"
    printf "📅 Date:            %s\n" "$(date +'%Y-%m-%d %H:%M:%S')"
    
    if [ -f "dist/$LATEST_NAME" ]; then
        echo ""
        echo "📂 FICHIERS GÉNÉRÉS:"
        ls -lah dist/*.apk 2>/dev/null | tail -5 || true
    fi
    
    echo ""
    echo "🚀 PROCHAINES ÉTAPES:"
    echo "  1. Tester l'APK: adb install dist/$LATEST_NAME"
    echo "  2. Partager: dist/$FINAL_NAME"
    echo "  3. Serveur QR: ./serve-apk.sh"
    
    if [ "$APK_TYPE" = "debug" ]; then
        echo ""
        echo "💡 CONSEIL: Pour un APK release signé:"
        echo "  1. Configurer keystore dans mobile/android/app/build.gradle"
        echo "  2. Relancer ce script"
    fi
    
    # Proposer de démarrer le serveur QR
    echo ""
    read -p "📱 Voulez-vous démarrer le serveur QR pour télécharger sur mobile ? [y/N]: " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        if [ -f "./serve-apk.sh" ]; then
            ./serve-apk.sh
        else
            echo "❌ serve-apk.sh non trouvé - créez-le d'abord"
        fi
    fi
}

# Fonction principale
main() {
    clear
    printf "${PURPLE}%s\n" "🎌 ANIME HISTORY TRACKER - BUILD APK"
    printf "%s\n" "======================================="
    printf "${NC}\n"
    
    check_environment
    clean_previous_builds
    build_pwa
    sync_pwa_to_mobile
    sync_capacitor
    check_android_config
    build_android_apk
    distribute_apk
    show_summary
}

# Gestion des options
case "${1:-}" in
    --clean-only)
        clean_previous_builds
        echo "🧹 Nettoyage terminé"
        exit 0
        ;;
    --pwa-only)
        check_environment
        build_pwa
        echo "⚛️  Build PWA terminé"
        exit 0
        ;;
    --help|-h)
        echo "Usage: $0 [OPTIONS]"
        echo ""
        echo "Options:"
        echo "  --clean-only    Nettoyer uniquement les caches"
        echo "  --pwa-only      Builder uniquement la PWA"
        echo "  --help, -h      Afficher cette aide"
        echo ""
        echo "Sans option: Build complet PWA + APK"
        exit 0
        ;;
    "")
        main
        ;;
    *)
        error "Option inconnue: $1 (utilisez --help pour l'aide)"
        ;;
esac
