#!/usr/bin/env node

const { execSync } = require('child_process');
const path = require('path');

async function deployToGitHub() {
  console.log('🚀 Deploying to GitHub Pages...');
  
  try {
    // Build PWA
    console.log('📦 Building PWA...');
    execSync('cd pwa && npm run build', { stdio: 'inherit' });
    
    // Deploy via git subtree
    console.log('🌐 Deploying to gh-pages...');
    execSync('git subtree push --prefix pwa/dist origin gh-pages', { stdio: 'inherit' });
    
    console.log('🎉 Deployment terminé!');
    console.log('📱 URL: https://emicol.github.io/animeTracker/');
    
  } catch (error) {
    console.error('❌ Erreur deployment:', error.message);
    process.exit(1);
  }
}

deployToGitHub();
