#!/usr/bin/env bash
# check-env.sh
# .env.local의 값이 실제 값인지 검증.
# AI가 placeholder/예시 값으로 채우는 것을 차단한다.

set -e

ENV_FILE=".env.local"

if [ ! -f "$ENV_FILE" ]; then
  echo "⚠️  $ENV_FILE 파일이 없습니다. (초기 셋업 단계에서는 정상)"
  echo "   Supabase 프로젝트 생성 후 docs/infrastructure.md를 참조하세요."
  exit 0
fi

# 필수 변수 목록 (docs/infrastructure.md와 일치해야 함)
REQUIRED_VARS=(
  "NEXT_PUBLIC_SUPABASE_URL"
  "NEXT_PUBLIC_SUPABASE_ANON_KEY"
  "SUPABASE_SERVICE_ROLE_KEY"
)

# 의심스러운 placeholder 패턴
SUSPICIOUS_PATTERNS=(
  "your-project"
  "your_project"
  "YOUR_PROJECT"
  "example.com"
  "placeholder"
  "PLACEHOLDER"
  "xxxxx"
  "XXXXX"
  "todo"
  "TODO"
  "fixme"
  "FIXME"
  "<.*>"
)

ERRORS=0

for VAR in "${REQUIRED_VARS[@]}"; do
  VALUE=$(grep "^${VAR}=" "$ENV_FILE" | head -1 | cut -d'=' -f2- | tr -d '"' | tr -d "'")

  if [ -z "$VALUE" ]; then
    echo "❌ ${VAR}이 비어있습니다."
    ERRORS=$((ERRORS + 1))
    continue
  fi

  for PATTERN in "${SUSPICIOUS_PATTERNS[@]}"; do
    if echo "$VALUE" | grep -qiE "$PATTERN"; then
      echo "❌ ${VAR}이 placeholder 값으로 보입니다: '${VALUE:0:30}...'"
      echo "   AI가 임의로 채운 값일 가능성이 큽니다."
      echo "   docs/infrastructure.md를 참조해 실제 값으로 교체하세요."
      ERRORS=$((ERRORS + 1))
      break
    fi
  done
done

# Supabase URL 형식 검증
SUPA_URL=$(grep "^NEXT_PUBLIC_SUPABASE_URL=" "$ENV_FILE" | head -1 | cut -d'=' -f2- | tr -d '"' | tr -d "'")
if [ -n "$SUPA_URL" ] && ! echo "$SUPA_URL" | grep -qE "^https://[a-z0-9]+\.supabase\.co$"; then
  echo "⚠️  NEXT_PUBLIC_SUPABASE_URL 형식이 이상합니다: $SUPA_URL"
  echo "   기대 형식: https://<프로젝트ref>.supabase.co"
  ERRORS=$((ERRORS + 1))
fi

if [ $ERRORS -gt 0 ]; then
  echo ""
  echo "❌ 환경 변수 검증 실패 ($ERRORS 건). 작업을 진행할 수 없습니다."
  exit 1
fi

echo "✅ 환경 변수 검증 통과"
