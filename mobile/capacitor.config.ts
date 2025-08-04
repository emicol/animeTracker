import { CapacitorConfig } from '@capacitor/cli';

const config: CapacitorConfig = {
  appId: 'com.emicol.animetracker',
  appName: 'Anime History Tracker',
  webDir: 'www',
  server: {
    androidScheme: 'https'
  },
  plugins: {
    StatusBar: {
      backgroundColor: '#3b82f6',
      style: 'light'
    },
    SplashScreen: {
      launchShowDuration: 2000,
      backgroundColor: '#3b82f6',
      showSpinner: false
    }
  },
  android: {
    buildOptions: {
      keystorePath: 'anime-tracker.keystore',
      keystoreAlias: 'anime-tracker-key'
    }
  }
};

export default config;
