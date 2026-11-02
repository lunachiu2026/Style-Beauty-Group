#!/usr/bin/env bash

set -euo pipefail

REPO_URL="${REPO_URL:-https://github.com/lunachiu2026/Style-Beauty-Group.git}"
BRANCH="${BRANCH:-main}"
COMMIT_MESSAGE="${1:-Publish Style Beauty Group website}"

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd -- "${SCRIPT_DIR}/.." && pwd)"

cd "${PROJECT_DIR}"

if ! command -v git >/dev/null 2>&1; then
  echo "錯誤：找不到 git，請先安裝 Git。" >&2
  exit 1
fi

if ! command -v npm >/dev/null 2>&1; then
  echo "錯誤：找不到 npm，請先安裝 Node.js 與 npm。" >&2
  exit 1
fi

echo "[1/6] 執行正式編譯檢查…"
npm run build

if [[ ! -d .git ]]; then
  echo "[2/6] 初始化 Git 儲存庫…"
  git init
else
  echo "[2/6] 已是 Git 儲存庫，略過初始化。"
fi

echo "[3/6] 設定主要分支為 ${BRANCH}…"
git branch -M "${BRANCH}"

if git remote get-url origin >/dev/null 2>&1; then
  CURRENT_ORIGIN="$(git remote get-url origin)"
  if [[ "${CURRENT_ORIGIN}" != "${REPO_URL}" ]]; then
    echo "錯誤：目前 origin 是 ${CURRENT_ORIGIN}" >&2
    echo "預期 origin 是 ${REPO_URL}" >&2
    echo "為避免推送到錯誤位置，腳本已停止。" >&2
    exit 1
  fi
  echo "[4/6] GitHub 遠端已設定。"
else
  echo "[4/6] 設定 GitHub 遠端…"
  git remote add origin "${REPO_URL}"
fi

if [[ -z "$(git config user.name || true)" || -z "$(git config user.email || true)" ]]; then
  echo "錯誤：尚未設定 Git 提交者資訊。請先執行：" >&2
  echo '  git config --global user.name "你的名稱"' >&2
  echo '  git config --global user.email "你的 GitHub 信箱"' >&2
  exit 1
fi

echo "[5/6] 建立 Git 提交…"
git add -A

if git diff --cached --quiet; then
  if ! git rev-parse --verify HEAD >/dev/null 2>&1; then
    echo "錯誤：沒有可提交的檔案。" >&2
    exit 1
  fi
  echo "沒有新的變更，沿用目前提交。"
else
  git commit -m "${COMMIT_MESSAGE}"
fi

echo "[6/6] 推送到 GitHub…"
if ! git push -u origin "${BRANCH}"; then
  echo >&2
  echo "推送失敗，常見原因：" >&2
  echo "  1. 尚未登入 GitHub 或沒有此儲存庫的寫入權限。" >&2
  echo "  2. GitHub 儲存庫已有不同的提交歷史。" >&2
  echo "  3. 網路連線暫時不可用。" >&2
  echo "腳本不會強制覆蓋遠端內容，請處理原因後重新執行。" >&2
  exit 1
fi

echo
echo "完成：網站原始碼已推送到"
echo "https://github.com/lunachiu2026/Style-Beauty-Group"
