#!/bin/bash
# 每日 AI 资讯自动搜索 —— 调用 Claude Code CLI 搜索并写入 Obsidian
# 由 launchd 每天早上 9 点触发

set -euo pipefail

LOG_DIR="$HOME/ai-news-daily/logs"
mkdir -p "$LOG_DIR"
LOG_FILE="$LOG_DIR/$(date +%Y-%m-%d).log"

# 当天去重标记：成功跑完会生成 .done-YYYY-MM-DD。
# 若今天已跑过（无论是 9 点准时触发还是开机后补跑），直接跳过，避免重复搜索。
DONE_MARKER="$LOG_DIR/.done-$(date +%Y-%m-%d)"
if [[ -f "$DONE_MARKER" ]]; then
    echo "[$(date)] 今天已经跑过 AI 资讯了，跳过本次触发。" >> "$LOG_FILE"
    exit 0
fi

exec > >(tee -a "$LOG_FILE") 2>&1

# 失败通知：脚本若异常退出（如 claude 连不上 API、代理没开），弹一条 macOS 通知，
# 这样跑挂了当场就能看见，不用等几天后才发现。RUN_OK 在正常收尾处置 1。
RUN_OK=0
notify() { /usr/bin/osascript -e "display notification \"$2\" with title \"$1\"" >/dev/null 2>&1 || true; }
trap '[[ $RUN_OK -eq 1 ]] || notify "AI资讯 ❌ 抓取失败" "请检查代理/网络，手动补跑: bash ~/ai-news-daily/fetch-ai-news.sh"' EXIT

echo "===== $(date) 开始搜索 AI 资讯 ====="

VAULT_VIDEO="$HOME/Library/Mobile Documents/iCloud~md~obsidian/Documents/ZangHuA/ZangHuA/AI资讯/视频文件"
VAULT_ARTICLE="$HOME/Library/Mobile Documents/iCloud~md~obsidian/Documents/ZangHuA/ZangHuA/AI资讯/文章"

TODAY=$(date +%Y.%-m.%-d)
YEAR=$(date +%Y)

PROMPT="你是麦田的 AI 资讯助理。请完成以下任务：

## 任务
搜索下面这些 AI 公司核心负责人 / 关键人物最近 3 天内的最新采访视频和文章。

重点关注这些人物：
- Anthropic：Dario Amodei、Daniela Amodei
- OpenAI：Sam Altman、Greg Brockman
- Google / DeepMind：Demis Hassabis、Sundar Pichai
- NVIDIA：Jensen Huang（黄仁勋）
- Meta：Mark Zuckerberg、Yann LeCun
- xAI：Elon Musk
- Microsoft AI：Mustafa Suleyman
- Thinking Machines Lab：Mira Murati
- SSI（Safe Superintelligence）：Ilya Sutskever

## 搜索方法
用 WebSearch 工具搜索。英文搜索效果更好，关键词用「人名 + interview/podcast/talk + ${YEAR}」的组合，例如：
- \"Dario Amodei interview ${YEAR}\"
- \"Sam Altman podcast ${YEAR}\"
- \"Jensen Huang AI interview ${YEAR}\"
- \"Mira Murati interview ${YEAR}\"
- 上面列出的每个人物都搜一搜，并加上 video / podcast / talk / keynote 等变体。

### 优先关注的优质来源（这些平台经常出高质量的 AI 大佬深度访谈）
- 播客类：Lex Fridman、Dwarkesh Patel、Decoder with Nilay Patel、Hard Fork、No Priors、a16z Podcast、Big Technology、20VC、All-In、BG2 Pod
- 媒体类：The Verge、TechCrunch、Wired、Bloomberg、The Information、Time、Fortune、Financial Times、纽约时报
- 视频 / 大会：YouTube，以及各家发布会和大会主题演讲（如 NVIDIA GTC、Google I/O、OpenAI DevDay）
- 搜索时可以把来源名也当关键词，比如 \"Demis Hassabis Lex Fridman\"、\"Sam Altman The Verge\"。

## 输出要求
对每条有价值的新内容，在对应目录创建一个 Markdown 笔记：
- 视频 → $VAULT_VIDEO/
- 文章 → $VAULT_ARTICLE/

文件名格式：${TODAY}-{公司}-{简短标题}.md

### 视频笔记模板
\`\`\`markdown
# ${TODAY} - {公司} - {标题}

## 基本信息

- **人物**：{姓名}（{职位}）
- **日期**：{发布日期}
- **来源**：{媒体/频道名}
- **类型**：{播客/视频采访/演讲}

## 链接

- [{平台名}]({URL})

## 核心话题

- {话题1}
- {话题2}
- {话题3}

#AI资讯 #{公司} #{人物姓} #{关键主题标签}
\`\`\`

### 文章笔记模板
\`\`\`markdown
# ${TODAY} - {公司} - {标题}

## 基本信息

- **人物**：{姓名}（{职位}）
- **日期**：{发布日期}
- **来源**：{媒体/频道名}
- **类型**：文章采访

## 链接

- [{媒体名}]({URL})

## 内容总结

{用 WebFetch 工具读取原文后，用简体中文写一份完整总结。
总结要覆盖采访的主要内容：谈了哪些话题、说了什么观点、有什么重要信息或金句。
目标是让人读完总结就大致知道这篇采访聊了什么，不需要再点进原文。
长度不限，以能清楚描述采访内容为准，自然段落，不要只列bullet点。}

#AI资讯 #{公司} #{人物姓} #{关键主题标签}
\`\`\`

## 重要规则
1. **内容必须跟 AI 实质相关**：只收录主要在谈人工智能、谈所在公司的 AI 产品/战略、或谈 AI 对行业和社会影响的内容。如果只是这个人物露了个面、但讲的东西跟 AI 关系不大（比如普通的大学毕业典礼演讲、跟 AI 无关的商业或个人话题），一律不要收录。
2. 只收录最近 3 天内发布的内容，跳过更早的。
3. **严格查重，绝不重复收录同一个采访**：每个采访的原文链接 URL 是它唯一的身份证——标题和日期会变，URL 不会变。在创建任何一篇新笔记之前，必须先用 Grep 工具在两个笔记目录（$VAULT_VIDEO 和 $VAULT_ARTICLE）里搜索这条内容的来源 URL（可只搜 URL 里最有辨识度的一段，比如文章链接里的路径/slug）。只要已有任意一篇笔记包含相同的 URL，就说明这条采访之前已经收录过——哪怕它之前用的文件名、标题、日期写法不一样——也要直接跳过、绝不再写一份。判断是否重复一律以 URL 为准，不要只看标题像不像。
4. 如果搜不到新内容，就不创建文件，直接说明即可。
5. 每条笔记的链接必须是真实可访问的 URL，不要编造。
6. 文章笔记必须先用 WebFetch 读取原文，再写总结；视频笔记列核心话题即可（无法抓取视频内容）。
7. 链接格式必须是 Markdown 可点击格式：[文字](URL)，不要写裸 URL。
8. 用简体中文写笔记。"

/opt/homebrew/bin/claude --dangerously-skip-permissions -p "$PROMPT" --model claude-sonnet-4-6 2>&1

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

# 打上当天完成标记，防止开机/登录时重复补跑
touch "$DONE_MARKER"

# 标记本次运行成功（让 EXIT trap 不弹失败通知），并弹一条成功通知
RUN_OK=1
notify "AI资讯 ✅ 已更新" "今日抓取完成，已备份到 GitHub"
