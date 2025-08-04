#!/usr/bin/env node

const fs = require('fs').promises;
const path = require('path');
const archiver = require('archiver');

async function buildExtension() {
  console.log('🔧 Building extension...');
  
  const extensionDir = path.join(__dirname, '../extension');
  const outputDir = path.join(__dirname, '../dist');
  
  try {
    // Créer le répertoire de sortie
    await fs.mkdir(outputDir, { recursive: true });
    
    // Créer l'archive ZIP
    const output = require('fs').createWriteStream(path.join(outputDir, 'anime-tracker-extension.zip'));
    const archive = archiver('zip', { zlib: { level: 9 } });
    
    output.on('close', () => {
      console.log(`✅ Extension packagée: ${archive.pointer()} bytes`);
    });
    
    archive.on('error', (err) => {
      throw err;
    });
    
    archive.pipe(output);
    
    // Ajouter tous les fichiers de l'extension
    archive.directory(extensionDir, false);
    
    await archive.finalize();
    
    console.log('🎉 Extension build terminé!');
    
  } catch (error) {
    console.error('❌ Erreur build extension:', error);
    process.exit(1);
  }
}

buildExtension();
