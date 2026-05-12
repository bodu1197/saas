#!/usr/bin/env bash
# verify-task.sh
# AI가 작업 단위를 끝낼 때마다 실행하는 검증 스크립트.
# 모든 단계가 통과해야만 "완료" 보고 가능.

set -e

echo "🔐 [1/8] 인프라 무결성 검증..."
bash scripts/check-infra.sh

echo "🔑 [2/8] 환경 변수 검증..."
bash scripts/check-env.sh

echo "🎓 [3/8] 학습된 교훈 검사..."
bash scripts/check-lessons.sh

echo "🔍 [4/8] 타입 체크 (tsc --noEmit)..."
npx tsc --noEmit

echo "🧹 [5/8] 린트 검사 (ESLint)..."
npx eslint . --max-warnings=0

echo "💅 [6/8] 포맷 검사 (Prettier)..."
npx prettier --check .

echo "🧪 [7/8] 단위 테스트..."
if [ -f "vitest.config.ts" ] || [ -f "vitest.config.js" ]; then
  npx vitest run
else
  echo "  (테스트 설정 없음 - 스킵)"
fi

echo "🏗️  [8/8] 빌드 검증..."
npx next build

echo ""
echo "✅ 모든 검증 통과. 작업을 완료로 보고해도 좋습니다."
echo ""
echo "💡 작업 회고를 잊지 마세요: /회고 또는 docs/LESSONS.md 갱신 검토"
