#!/usr/bin/env bash
# check-infra.sh
# 인프라 설정 파일이 변경되지 않았는지, 프로젝트 ID가 일치하는지 검증.
# AI가 supabase link를 새로 한다거나 vercel project를 바꾸는 것을 차단.

set -e

ERRORS=0

# 1. supabase/config.toml 의 project_id가 docs/infrastructure.md와 일치하는지
if [ -f "supabase/config.toml" ]; then
  CONFIG_PROJECT_ID=$(grep -E "^project_id\s*=" supabase/config.toml | head -1 | cut -d'=' -f2 | tr -d ' "')
  DOCS_PROJECT_REF=$(grep -A1 "Supabase 프로젝트 Ref" docs/infrastructure.md | tail -1 | grep -oE '[a-z0-9]{20}' | head -1)

  if [ -n "$DOCS_PROJECT_REF" ] && [ -n "$CONFIG_PROJECT_ID" ]; then
    if [ "$CONFIG_PROJECT_ID" != "$DOCS_PROJECT_REF" ]; then
      echo "❌ supabase/config.toml의 project_id ($CONFIG_PROJECT_ID)가"
      echo "   docs/infrastructure.md의 Project Ref ($DOCS_PROJECT_REF)와 다릅니다."
      echo "   AI가 임의로 변경했거나 새 프로젝트를 연결한 것일 수 있습니다."
      ERRORS=$((ERRORS + 1))
    fi
  fi
fi

# 2. .vercel/project.json이 변경되지 않았는지 (git tracked + 변경 감지)
if [ -f ".vercel/project.json" ] && [ -d ".git" ]; then
  if git diff --name-only HEAD 2>/dev/null | grep -q "^.vercel/project.json$"; then
    echo "❌ .vercel/project.json이 변경되었습니다."
    echo "   AI가 Vercel 프로젝트를 임의로 재연결한 것일 수 있습니다."
    echo "   git checkout .vercel/project.json 으로 복원하거나 사용자가 직접 검토하세요."
    ERRORS=$((ERRORS + 1))
  fi
fi

# 3. .env.local이 git에 staged 되었는지 (절대 안 됨)
if [ -d ".git" ] && git diff --cached --name-only 2>/dev/null | grep -qE "^\.env(\.local|\.production)?$"; then
  echo "❌ .env 파일이 git에 staged 되어 있습니다. 즉시 unstage 하세요."
  echo "   git reset HEAD .env*"
  ERRORS=$((ERRORS + 1))
fi

# 4. service_role 키가 NEXT_PUBLIC_ 으로 노출되지 않는지
if [ -f ".env.local" ]; then
  if grep -qE "^NEXT_PUBLIC_.*SERVICE_ROLE" .env.local; then
    echo "❌ service_role 키가 NEXT_PUBLIC_ 접두사로 설정되어 있습니다."
    echo "   클라이언트 번들에 노출되어 치명적 보안 사고가 됩니다."
    ERRORS=$((ERRORS + 1))
  fi
fi

# 5. 코드에서 service_role 키 하드코딩 검색
if [ -d "src" ]; then
  JWT_MATCH=$(grep -rE "(eyJ[A-Za-z0-9_-]{30,})" src/ --include="*.ts" --include="*.tsx" 2>/dev/null | grep -v "// @harness-allow" | head -1)
  if [ -n "$JWT_MATCH" ]; then
    echo "$JWT_MATCH"
    echo "❌ src/ 내에 JWT로 보이는 하드코딩 문자열이 발견되었습니다."
    echo "   환경 변수로 분리하세요. 의도된 경우 // @harness-allow 주석 추가."
    ERRORS=$((ERRORS + 1))
  fi
fi

if [ $ERRORS -gt 0 ]; then
  echo ""
  echo "❌ 인프라 검증 실패 ($ERRORS 건)."
  exit 1
fi

echo "✅ 인프라 검증 통과"
