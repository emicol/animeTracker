#!/usr/bin/env node

const { execSync } = require('child_process');
const fs = require('fs');
const path = require('path');

function generateIcons() {
  console.log('🎨 Generating icons from source...');
  
  const sourceIcon = path.join(__dirname, '../assets/icons/logo.png');
  
  if (!fs.existsSync(sourceIcon)) {
    console.error('❌ Source icon not found:', sourceIcon);
    process.exit(1);
  }
  
  // Check for ImageMagick
  let magickCmd = 'convert';
  try {
    execSync('convert -version', { stdio: 'ignore' });
  } catch {
    try {
      execSync('magick -version', { stdio: 'ignore' });
      magickCmd = 'magick';
    } catch {
      console.error('❌ ImageMagick not found. Install with: sudo apt install imagemagick');
      process.exit(1);
    }
  }
  
  console.log(`✅ Using ${magickCmd} for icon generation`);
  
  // Extension icons
  const extensionSizes = [16, 32, 48, 128];
  extensionSizes.forEach(size => {
    execSync(`${magickCmd} "${sourceIcon}" -resize ${size}x${size} "extension/icons/icon${size}.png"`);
  });
  console.log('✅ Extension icons generated');
  
  // PWA icons
  execSync(`${magickCmd} "${sourceIcon}" -resize 192x192 "pwa/public/icons/icon-192.png"`);
  execSync(`${magickCmd} "${sourceIcon}" -resize 512x512 "pwa/public/icons/icon-512.png"`);
  execSync(`${magickCmd} "${sourceIcon}" -resize 32x32 "pwa/public/favicon.ico"`);
  console.log('✅ PWA icons generated');
  
  // Asset icons
  const assetSizes = [64, 256, 1024];
  assetSizes.forEach(size => {
    execSync(`${magickCmd} "${sourceIcon}" -resize ${size}x${size} "assets/icons/icon-${size}.png"`);
  });
  console.log('✅ Asset icons generated');
  
  console.log('🎉 All icons generated successfully!');
}

generateIcons();
