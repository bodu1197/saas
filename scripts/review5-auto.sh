#!/usr/bin/env bash
# review5-auto.sh
# /리뷰5 5단계 코드 리뷰 중 자동화 가능한 패턴 검사
# verify-task.sh(tsc, eslint, prettier, check-infra, check-lessons)와 겹치지 않는 항목만 수행

TOTAL_ERRORS=0
TOTAL_WARNINGS=0

echo "📋 /리뷰5 자동 검사 시작..."
echo ""

# ═══════════════════════════════════════════════
# 1단계: 타입 안정성 패턴 (tsc 보완)
# ═══════════════════════════════════════════════
echo "🔍 [리뷰5-1/4] 타입 안정성 패턴 검사..."
S1_ERR=0

if [ -d "src" ]; then
  ANY_HITS=$(grep -rnE ': any\b|<any>|<any,' src/ --include="*.ts" --include="*.tsx" 2>/dev/null | grep -v '\.d\.ts' || true)
  if [ -n "$ANY_HITS" ]; then
    echo "  ❌ any 타입 사용:"
    echo "$ANY_HITS" | sed 's/^/    /' | head -10
    S1_ERR=$((S1_ERR + 1))
  fi

  AS_HITS=$(grep -rnE ' as [A-Z]' src/ --include="*.ts" --include="*.tsx" 2>/dev/null | grep -v 'as const' | grep -v '\.d\.ts' || true)
  if [ -n "$AS_HITS" ]; then
    echo "  ❌ as 타입 단언 (as const 제외):"
    echo "$AS_HITS" | sed 's/^/    /' | head -10
    S1_ERR=$((S1_ERR + 1))
  fi

  TSI_HITS=$(grep -rnE '@ts-ignore|@ts-expect-error' src/ --include="*.ts" --include="*.tsx" 2>/dev/null || true)
  if [ -n "$TSI_HITS" ]; then
    echo "  ❌ @ts-ignore / @ts-expect-error:"
    echo "$TSI_HITS" | sed 's/^/    /' | head -10
    S1_ERR=$((S1_ERR + 1))
  fi
fi

if [ $S1_ERR -eq 0 ]; then echo "  ✅ 통과"; else TOTAL_ERRORS=$((TOTAL_ERRORS + S1_ERR)); fi

# ═══════════════════════════════════════════════
# 2단계: 보안 패턴 (check-infra.sh 보완)
# ═══════════════════════════════════════════════
echo "🔐 [리뷰5-2/4] 보안 패턴 검사..."
S2_ERR=0

if [ -d "src" ]; then
  KEY_HITS=$(grep -rnE '(sk_live_|sk_test_|AKIA[0-9A-Z]{16}|ghp_[a-zA-Z0-9]{36}|xox[bpors]-|rk_live_|rk_test_|password\s*=\s*['\''"][^'\''"]{8,})' src/ --include="*.ts" --include="*.tsx" 2>/dev/null || true)
  if [ -n "$KEY_HITS" ]; then
    echo "  ❌ 하드코딩된 API 키/비밀번호 패턴:"
    echo "$KEY_HITS" | sed 's/^/    /' | head -10
    S2_ERR=$((S2_ERR + 1))
  fi

  SROLE_HITS=$(grep -rnl 'service_role' src/ --include="*.ts" --include="*.tsx" 2>/dev/null | grep -v 'server\|api\|lib/supabase-admin\|\.d\.ts' || true)
  if [ -n "$SROLE_HITS" ]; then
    echo "  ❌ service_role 참조 (서버 코드 외부):"
    echo "$SROLE_HITS" | sed 's/^/    /' | head -10
    S2_ERR=$((S2_ERR + 1))
  fi
fi

if [ -d "supabase/migrations" ]; then
  RLS_HITS=$(grep -rnEi 'DISABLE\s+ROW\s+LEVEL\s+SECURITY' supabase/migrations/ --include="*.sql" 2>/dev/null || true)
  if [ -n "$RLS_HITS" ]; then
    echo "  ❌ RLS 비활성화 발견:"
    echo "$RLS_HITS" | sed 's/^/    /' | head -10
    S2_ERR=$((S2_ERR + 1))
  fi
fi

if [ $S2_ERR -eq 0 ]; then echo "  ✅ 통과"; else TOTAL_ERRORS=$((TOTAL_ERRORS + S2_ERR)); fi

# ═══════════════════════════════════════════════
# 3단계: 코드 품질 패턴 (eslint/prettier 보완)
# ═══════════════════════════════════════════════
echo "📏 [리뷰5-3/4] 코드 품질 패턴 검사..."
S3_ERR=0

if [ -d "src" ]; then
  LONG_FILES=""
  find src/ -name "*.ts" -o -name "*.tsx" 2>/dev/null | while IFS= read -r f; do
    LINES=$(wc -l < "$f" | tr -d ' ')
    if [ "$LINES" -gt 500 ]; then
      echo "  ⚠️  500줄 초과: $f (${LINES}줄)"
      TOTAL_WARNINGS=$((TOTAL_WARNINGS + 1))
    fi
  done

  CONSOLE_HITS=$(grep -rnE 'console\.(log|debug|info)\(' src/ --include="*.ts" --include="*.tsx" 2>/dev/null | grep -v '// eslint-disable' | grep -v '// @allow-console' || true)
  if [ -n "$CONSOLE_HITS" ]; then
    echo "  ⚠️  console.log/debug/info 사용 (제거 권장):"
    echo "$CONSOLE_HITS" | sed 's/^/    /' | head -10
    TOTAL_WARNINGS=$((TOTAL_WARNINGS + 1))
  fi
fi

if [ $S3_ERR -eq 0 ]; then echo "  ✅ 통과"; else TOTAL_ERRORS=$((TOTAL_ERRORS + S3_ERR)); fi

# ═══════════════════════════════════════════════
# 4단계: 아키텍처 패턴 (멀티테넌트 격리)
# ═══════════════════════════════════════════════
echo "🏗️  [리뷰5-4/4] 아키텍처 패턴 검사..."
S4_ERR=0

if [ -d "src" ]; then
  TENANT_HITS=$(grep -rnE '\.(from|rpc)\(' src/ --include="*.ts" --include="*.tsx" 2>/dev/null | grep -v 'tenant_id' | grep -v '// @no-tenant' | grep -v '\.d\.ts' || true)
  if [ -n "$TENANT_HITS" ]; then
    echo "  ⚠️  DB 쿼리에 tenant_id 필터 누락 가능성:"
    echo "$TENANT_HITS" | sed 's/^/    /' | head -5
    echo "    (의도된 경우 // @no-tenant 주석 추가)"
    TOTAL_WARNINGS=$((TOTAL_WARNINGS + 1))
  fi
fi

if [ $S4_ERR -eq 0 ]; then echo "  ✅ 통과"; else TOTAL_ERRORS=$((TOTAL_ERRORS + S4_ERR)); fi

# ═══════════════════════════════════════════════
# 최종 결과
# ═══════════════════════════════════════════════
echo ""
if [ $TOTAL_ERRORS -gt 0 ]; then
  echo "❌ /리뷰5 자동 검사 실패 (오류 ${TOTAL_ERRORS}건, 경고 ${TOTAL_WARNINGS}건)"
  exit 1
else
  if [ $TOTAL_WARNINGS -gt 0 ]; then
    echo "✅ /리뷰5 자동 검사 통과 (경고 ${TOTAL_WARNINGS}건 — 확인 권장)"
  else
    echo "✅ /리뷰5 자동 검사 통과"
  fi
fi
