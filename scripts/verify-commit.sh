#!/usr/bin/env bash
# verify-commit.sh
# pre-commit 훅에서 사용. 빠른 검증만 (빌드 제외).

set -e

echo "🔐 인프라 무결성 검증..."
bash scripts/check-infra.sh

echo "🔍 타입 체크..."
npx tsc --noEmit

echo "🧹 변경 파일 린트..."
npx lint-staged

echo "✅ 커밋 검증 통과"
