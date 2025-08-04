# 📦 Installation

## Prérequis

- Node.js 18+
- npm 9+
- Git

## Installation complète

```bash
# Cloner le projet
git clone git@github.com:emicol/animeTracker.git
cd animeTracker

# Installer toutes les dépendances
npm run install:all

# Lancer en mode développement
npm run dev
```

## Par composant

### PWA React
```bash
cd pwa
npm install
npm run dev
```

### Extension
```bash
cd extension
npm install
npm run build
```

### Application mobile
```bash
cd mobile
npm install
npx cap sync
npm run android
```
