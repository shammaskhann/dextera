#!/bin/bash

# Stop execution if any command fails
set -e

echo "====================================================="
echo " Deploying Flutter Web to GitHub Pages"
echo "====================================================="

# Build the web app with the base-href set to the repository name
echo "Building Flutter Web release..."
# IMPORTANT: The base-href must match the repository name for GitHub Pages
flutter build web --release --base-href "/"

echo "Navigating to build/web directory..."
cd build/web || exit
echo "dextera.online" > CNAME

echo "Initializing a temporary git repo..."
git init
# Make sure the initial branch is named main
git branch -M main

echo "Adding files to the git repo..."
git add .

echo "Committing files..."
git commit -m "🚀 Deploy Web Build to GitHub Pages"

# Force push to the gh-pages branch of the repository
echo "Force pushing to the gh-pages branch on GitHub..."
git push -f https://github.com/shammaskhann/dextera.git main:gh-pages

echo "====================================================="
echo "✅ Deployment completed!"
echo "If this is your first time deploying, make sure to enable GitHub Pages:"
echo "1. Go to your repository settings on GitHub: https://github.com/shammaskhann/dextera/settings/pages"
echo "2. Set the 'Source' under 'Build and deployment' to 'Deploy from a branch'"
echo "3. Select the 'gh-pages' branch and '/ (root)' folder"
echo "4. Save."
echo "Your app will be live at: https://dextera.online"
echo "Note: It may take a few minutes for GitHub Pages to update."
echo "====================================================="
