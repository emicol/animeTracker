# 🛠️ Guide de développement

## Architecture

- **extension/** - Extension navigateur (Manifest V3)
- **pwa/** - Progressive Web App React
- **mobile/** - Application mobile Capacitor
- **shared/** - Code partagé entre plateformes

## Workflow de développement

1. Modifier le code
2. Tester en local
3. Build et déploiement

## Scripts utiles

```bash
# Développement
npm run dev:pwa          # PWA React
npm run dev:extension    # Extension

# Build
npm run build:all        # Tout
npm run build:pwa        # PWA uniquement
npm run build:extension  # Extension uniquement

# Déploiement
npm run deploy:github    # GitHub Pages
```

## Structure des données

```typescript
interface HistoryEntry {
  id: string;
  animeName: string;
  displayTitle: string;
  season: string;
  language: string;
  episode?: number;
  timestamp: number;
  watchDuration?: number;
}
```
