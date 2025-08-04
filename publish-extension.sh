#!/bin/bash

# 🎌 Anime History Tracker - Update Version Script
# Met à jour automatiquement les versions dans tous les fichiers du projet

set -e

# Couleurs
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

log() { printf "${GREEN}[$(date +'%H:%M:%S')]${NC} %s\n" "$1"; }
info() { printf "${BLUE}[INFO]${NC} %s\n" "$1"; }
warn() { printf "${YELLOW}[WARN]${NC} %s\n" "$1"; }
error() { printf "${RED}[ERROR]${NC} %s\n" "$1"; exit 1; }

# Vérifier qu'on est dans le bon répertoire
if [ ! -f "package.json" ] || [ ! -d "mobile" ]; then
    error "❌ Ce script doit être exécuté depuis la racine du projet anime-history-tracker"
fi

echo "🎌 ANIME HISTORY TRACKER - UPDATE VERSION"
echo "========================================"

# Calculer les versions
CURRENT_YEAR=$(date +%Y)
BASE_YEAR=2024
YEAR_OFFSET=$((CURRENT_YEAR - BASE_YEAR))

MONTH_DAY=$(date +%m%d)
HOUR_MIN=$(date +%H%M)

# Version Android (max 2,147,483,647)
if [ $YEAR_OFFSET -gt 9 ]; then
    VERSION_CODE="$(date +%y%m%d%H%M | sed 's/^20//')"
else
    VERSION_CODE="${YEAR_OFFSET}${MONTH_DAY}${HOUR_MIN}"
fi

# Version lisible
VERSION_NAME=$(date +%Y.%m.%d.%H%M)

# Version npm (semantic versioning)
MAJOR=1
MINOR=$(date +%m | sed 's/^0//')  # Mois sans 0 initial
PATCH=$(date +%d%H | sed 's/^0*//')  # Jour+heure sans 0 initiaux
NPM_VERSION="${MAJOR}.${MINOR}.${PATCH}"

log "📱 Version Android: $VERSION_CODE"
log "🏷️  Version Name: $VERSION_NAME"
log "📦 Version NPM: $NPM_VERSION"

# 1. Mettre à jour package.json racine
info "🔄 Mise à jour package.json racine..."
if [ -f "package.json" ]; then
    sed -i.bak "s/\"version\": \"[^\"]*\"/\"version\": \"$NPM_VERSION\"/" package.json
    log "✅ package.json racine mis à jour"
fi

# 2. Mettre à jour PWA package.json
info "🔄 Mise à jour PWA package.json..."
if [ -f "pwa/package.json" ]; then
    sed -i.bak "s/\"version\": \"[^\"]*\"/\"version\": \"$NPM_VERSION\"/" pwa/package.json
    log "✅ PWA package.json mis à jour"
fi

# 3. Mettre à jour Mobile package.json
info "🔄 Mise à jour Mobile package.json..."
if [ -f "mobile/package.json" ]; then
    sed -i.bak "s/\"version\": \"[^\"]*\"/\"version\": \"$NPM_VERSION\"/" mobile/package.json
    log "✅ Mobile package.json mis à jour"
fi

# 4. Mettre à jour Extension manifest.json
info "🔄 Mise à jour Extension manifest..."
if [ -f "extension/manifest.json" ]; then
    sed -i.bak "s/\"version\": \"[^\"]*\"/\"version\": \"$NPM_VERSION\"/" extension/manifest.json
    log "✅ Extension manifest mis à jour"
fi

# 5. Mettre à jour PWA manifest.json
info "🔄 Mise à jour PWA manifest..."
if [ -f "pwa/public/manifest.json" ]; then
    sed -i.bak "s/\"version\": \"[^\"]*\"/\"version\": \"$NPM_VERSION\"/" pwa/public/manifest.json
    log "✅ PWA manifest mis à jour"
fi

# 6. Mettre à jour Capacitor config
info "🔄 Mise à jour Capacitor config..."
if [ -f "mobile/capacitor.config.ts" ]; then
    # Ajouter ou mettre à jour la version dans le config
    if grep -q "version:" mobile/capacitor.config.ts; then
        sed -i.bak "s/version: '[^']*'/version: '$NPM_VERSION'/" mobile/capacitor.config.ts
    else
        # Ajouter la version après appName
        sed -i.bak "/appName:/a\\
  version: '$NPM_VERSION'," mobile/capacitor.config.ts
    fi
    log "✅ Capacitor config mis à jour"
fi

# 7. Mettre à jour Android build.gradle (si il existe)
GRADLE_FILE="mobile/android/app/build.gradle"
if [ -f "$GRADLE_FILE" ]; then
    info "🔄 Mise à jour Android build.gradle..."
    
    # Créer sauvegarde
    cp "$GRADLE_FILE" "$GRADLE_FILE.backup-$(date +%Y%m%d-%H%M%S)"
    
    # Mettre à jour versionCode et versionName
    sed -i.bak \
        -e "s/versionCode [0-9]*/versionCode $VERSION_CODE/" \
        -e "s/versionName \"[^\"]*\"/versionName \"$VERSION_NAME\"/" \
        "$GRADLE_FILE"
    
    # Vérifier les changements
    if grep -q "versionCode $VERSION_CODE" "$GRADLE_FILE" && grep -q "versionName \"$VERSION_NAME\"" "$GRADLE_FILE"; then
        log "✅ Android build.gradle mis à jour"
        
        info "🔍 Versions Android dans build.gradle:"
        grep "versionCode\|versionName" "$GRADLE_FILE" | sed 's/^/    /'
    else
        warn "⚠️  Échec mise à jour build.gradle - vérification manuelle nécessaire"
    fi
else
    warn "⚠️  Fichier build.gradle Android non trouvé - sera créé au premier build"
fi

# 8. Nettoyer les fichiers de sauvegarde
info "🧹 Nettoyage des fichiers temporaires..."
find . -name "*.bak" -delete 2>/dev/null || true

# 9. Afficher un résumé
echo ""
echo "📊 RÉSUMÉ DES VERSIONS MISES À JOUR:"
echo "=================================="
printf "📦 NPM Version:     %s\n" "$NPM_VERSION"
printf "📱 Android Code:    %s\n" "$VERSION_CODE"
printf "🏷️  Android Name:    %s\n" "$VERSION_NAME"
printf "📅 Date:            %s\n" "$(date +'%Y-%m-%d %H:%M:%S')"

# 10. Optionnel: Commit automatique
read -p "🤔 Voulez-vous créer un commit avec ces changements ? [y/N]: " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    if git diff --quiet; then
        warn "Aucun changement à commiter"
    else
        git add .
        git commit -m "🔄 Version bump to $NPM_VERSION

- Android versionCode: $VERSION_CODE
- Android versionName: $VERSION_NAME
- NPM version: $NPM_VERSION
- Auto-generated on $(date +'%Y-%m-%d %H:%M:%S')"
        log "✅ Commit créé avec les nouvelles versions"
        
        read -p "🚀 Pousser vers GitHub ? [y/N]: " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            # Détecter la branche principale
            MAIN_BRANCH=$(git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's@^refs/remotes/origin/@@' || echo "master")
            if ! git show-ref --verify --quiet "refs/heads/$MAIN_BRANCH"; then
                MAIN_BRANCH=$(git branch --show-current)
            fi
            
            info "🌿 Push vers branche: $MAIN_BRANCH"
            git push origin "$MAIN_BRANCH"
            log "✅ Changements poussés vers GitHub"
        fi
    fi
fi

echo ""
echo "🎉 MISE À JOUR DES VERSIONS TERMINÉE !"
echo ""
echo "📋 Prochaines étapes suggérées:"
echo "  1. npm run build:all      # Build complet"
echo "  2. npm run build:apk      # Générer APK Android"
echo "  3. npm run deploy:github  # Déployer PWA"
