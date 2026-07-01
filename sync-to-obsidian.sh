#!/bin/bash
# 自动同步 AI 资讯到 Obsidian vault
REPO_DIR="$HOME/ai-news-daily"
VAULT_DIR="$HOME/Library/Mobile Documents/iCloud~md~obsidian/Documents/ZangHuA/ZangHuA/AI资讯"

cd "$REPO_DIR" || exit 1
git pull --quiet origin main 2>/dev/null || true

rsync -av --ignore-existing "$REPO_DIR/AI资讯/视频文件/" "$VAULT_DIR/视频文件/" 2>/dev/null || true
rsync -av --ignore-existing "$REPO_DIR/AI资讯/文章/" "$VAULT_DIR/文章/" 2>/dev/null || true

exit 0
