#!/usr/bin/env bash
set -euo pipefail

# deploy_ghpages.sh
# Builds Flutter web and deploys build/web to the gh-pages branch.
# Usage: ./scripts/deploy_ghpages.sh

# Configuration
BRANCH=gh-pages
BUILD_DIR=build/web
WORKTREE_DIR=.gh-pages
REMOTE=${REMOTE:-origin}

echo "Starting web build + deploy to '${BRANCH}' (remote: ${REMOTE})"

# 1) Build web
echo "Running: flutter build web --release"
flutter build web --release

# 2) Ensure remote exists and fetch
git fetch ${REMOTE}

# 3) Create branch remotely if it doesn't exist (create orphan branch locally and push)
if ! git ls-remote --exit-code --heads ${REMOTE} ${BRANCH} >/dev/null 2>&1; then
  echo "Remote branch ${BRANCH} does not exist; creating it..."
  git checkout --orphan ${BRANCH}
  git rm -rf . >/dev/null 2>&1 || true
  # create an empty commit so branch exists
  git commit --allow-empty -m "chore: initialize ${BRANCH} branch"
  git push ${REMOTE} ${BRANCH}
  # return to previous branch
  git checkout -
fi

# 4) Remove any existing worktree, then add worktree for gh-pages
if [ -d "${WORKTREE_DIR}" ]; then
  echo "Removing existing worktree '${WORKTREE_DIR}'"
  git worktree remove -f ${WORKTREE_DIR}
fi

echo "Checking out ${BRANCH} to worktree ${WORKTREE_DIR}"
git worktree add ${WORKTREE_DIR} ${REMOTE}/${BRANCH}

# 5) Copy build output into worktree (delete existing files first)
echo "Clearing ${WORKTREE_DIR} and copying ${BUILD_DIR} -> ${WORKTREE_DIR}"
rm -rf ${WORKTREE_DIR}/*
cp -r ${BUILD_DIR}/* ${WORKTREE_DIR}/

# 6) Commit & push
pushd ${WORKTREE_DIR} >/dev/null
  git add --all
  # Only commit if there are changes
  if git diff --staged --quiet && git status --porcelain | grep -q .; then
    echo "No changes to commit."
  else
    git commit -m "chore: deploy web build $(date -u +"%Y-%m-%d %H:%M:%S UTC")" || true
    git push ${REMOTE} HEAD:${BRANCH}
  fi
popd >/dev/null

# 7) Clean up
echo "Removing worktree ${WORKTREE_DIR}"
git worktree remove ${WORKTREE_DIR}

echo "Deploy complete. Branch: ${BRANCH} pushed to ${REMOTE}."