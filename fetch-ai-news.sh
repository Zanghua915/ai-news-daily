#!/bin/bash
# 每日 AI 资讯自动搜索 —— 调用 Claude Code CLI 搜索并写入 Obsidian
# 由 launchd 每天早上 9 点触发

set -euo pipefail

LOG_DIR="$HOME/ai-news-daily/logs"
mkdir -p "$LOG_DIR"
LOG_FILE="$LOG_DIR/$(date +%Y-%m-%d).log"

exec > >(tee -a "$LOG_FILE") 2>&1
echo "===== $(date) 开始搜索 AI 资讯 ====="

VAULT_VIDEO="$HOME/Library/Mobile Documents/iCloud~md~obsidian/Documents/ZangHuA/ZangHuA/AI资讯/视频文件"
VAULT_ARTICLE="$HOME/Library/Mobile Documents/iCloud~md~obsidian/Documents/ZangHuA/ZangHuA/AI资讯/文章"

TODAY=$(date +%Y.%-m.%-d)

PROMPT="你是麦田的 AI 资讯助理。请完成以下任务：

## 任务
搜索 AI 三巨头（Anthropic、OpenAI、Google DeepMind）负责人最近 3 天内的最新采访视频和文章。

重点关注这些人物：
- Anthropic：Dario Amodei、Daniela Amodei
- OpenAI：Sam Altman
- Google DeepMind：Demis Hassabis、Sundar Pichai

## 搜索方法
用 WebSearch 工具搜索以下关键词（英文搜索效果更好）：
- \"Dario Amodei interview 2026\"
- \"Sam Altman interview 2026\"
- \"Demis Hassabis interview 2026\"
- 以及类似变体，加上 video / podcast / talk 等关键词

## 输出要求
对每条有价值的新内容，在对应目录创建一个 Markdown 笔记：
- 视频 → $VAULT_VIDEO/
- 文章 → $VAULT_ARTICLE/

文件名格式：${TODAY}-{公司}-{简短标题}.md

笔记模板：
\`\`\`markdown
# ${TODAY} - {公司} - {标题}

## 基本信息

- **人物**：{姓名}（{职位}）
- **日期**：{发布日期}
- **来源**：{媒体/频道名}
- **类型**：{视频采访/播客/文章/演讲}

## 链接

- {平台名}：{URL}

## 核心话题

- {话题1}
- {话题2}
- {话题3}

#AI资讯 #{公司} #{人物姓} #{关键主题标签}
\`\`\`

## 重要规则
1. 只收录最近 3 天内发布的内容，跳过更早的。
2. 写入前先检查目录里是否已有同主题的笔记，避免重复。
3. 如果搜不到新内容，就不创建文件，直接说明即可。
4. 每条笔记的链接必须是真实可访问的 URL，不要编造。
5. 用简体中文写笔记。"

/Applications/cmux.app/Contents/Resources/bin/claude --dangerously-skip-permissions -p "$PROMPT" --model claude-sonnet-4-6 2>&1

echo "===== $(date) 搜索完成 ====="

# 同步到 GitHub 备份
REPO_DIR="$HOME/ai-news-daily"
rsync -av --ignore-existing "$VAULT_VIDEO/" "$REPO_DIR/AI资讯/视频文件/" 2>/dev/null || true
rsync -av --ignore-existing "$VAULT_ARTICLE/" "$REPO_DIR/AI资讯/文章/" 2>/dev/null || true
cd "$REPO_DIR"
if [[ -n $(git status --porcelain 2>/dev/null) ]]; then
    git add -A
    git commit -m "auto: ${TODAY} AI 资讯更新" 2>/dev/null || true
    git push origin main 2>/dev/null || true
fi

echo "===== $(date) 全部完成 ====="
