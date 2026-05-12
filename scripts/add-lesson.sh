#!/usr/bin/env bash
# add-lesson.sh
# AI가 새로운 교훈을 추가할 때 사용하는 스크립트.
# 사용법: bash scripts/add-lesson.sh
#
# 또는 (대화형):
#   pnpm lesson:add
#
# AI는 작업 종료 전, 새 실수가 있었다면 반드시 이 스크립트로 교훈을 추가해야 한다.

set -e

LESSONS_FILE="docs/LESSONS.md"

if [ ! -f "$LESSONS_FILE" ]; then
  echo "❌ $LESSONS_FILE이 없습니다."
  exit 1
fi

# 다음 ID 자동 생성
LAST_ID=$(grep -oE "L-[0-9]{4}" "$LESSONS_FILE" | sort -u | tail -1 || echo "L-0000")
NEXT_NUM=$(echo "$LAST_ID" | sed 's/L-//' | sed 's/^0*//')
NEXT_NUM=$((NEXT_NUM + 1))
NEXT_ID=$(printf "L-%04d" "$NEXT_NUM")

TODAY=$(date -I)

# 인자로 받기 (AI 친화적 — 비대화형 호출)
TITLE="${1:-}"
CATEGORY="${2:-other}"
SEVERITY="${3:-medium}"
SITUATION="${4:-}"
WRONG="${5:-}"
RIGHT="${6:-}"
DETECT="${7:-}"

if [ -z "$TITLE" ]; then
  echo "사용법: bash scripts/add-lesson.sh \"제목\" 카테고리 심각도 \"상황\" \"잘못된행동\" \"올바른행동\" \"탐지방법\""
  echo ""
  echo "카테고리: infra | type-safety | git | security | architecture | api | performance | ux | other"
  echo "심각도: low | medium | high | critical"
  exit 1
fi

# 기존 교훈에 동일 패턴이 있는지 검색
SIMILAR=$(grep -B2 -A20 "^### L-" "$LESSONS_FILE" 2>/dev/null | grep -i "$TITLE" | head -1 || echo "")

if [ -n "$SIMILAR" ]; then
  echo "⚠️  유사한 교훈이 이미 있는 것 같습니다:"
  echo "$SIMILAR"
  echo ""
  echo "재발 카운터를 올리려면: bash scripts/bump-lesson.sh <기존ID>"
  echo "정말 새 교훈으로 추가하려면 Y를 입력:"
  read -r CONFIRM
  if [ "$CONFIRM" != "Y" ]; then
    exit 0
  fi
fi

# 교훈 추가
cat >> "$LESSONS_FILE" <<EOF

### $NEXT_ID: $TITLE

\`\`\`yaml
id: $NEXT_ID
category: $CATEGORY
severity: $SEVERITY
occurrences: 1
first_seen: $TODAY
last_seen: $TODAY
auto_check: false
auto_check_path: ""
\`\`\`

**상황:**
$SITUATION

**잘못된 행동:**
$WRONG

**올바른 행동:**
$RIGHT

**탐지 방법:**
$DETECT

**자동화 가능 여부:**
- [ ] grep/스크립트로 검사 가능
- [ ] ESLint 룰로 차단 가능
- [ ] 타입 시스템으로 차단 가능
- [ ] 사람의 리뷰만 가능
EOF

echo "✅ 교훈 $NEXT_ID 추가됨: $TITLE"

# 통계 갱신
bash scripts/update-lesson-stats.sh

# 누적 통계 검사 — 카테고리별 5개 이상이면 메타 패턴 알림
CATEGORY_COUNT=$(grep -A2 "^### L-" "$LESSONS_FILE" | grep "category: $CATEGORY" | wc -l | tr -d ' ')
if [ "${CATEGORY_COUNT:-0}" -ge 5 ] 2>/dev/null; then
  echo ""
  echo "🧠 메타 패턴 감지: '$CATEGORY' 카테고리의 교훈이 $CATEGORY_COUNT 개 누적되었습니다."
  echo "   → docs/LESSONS.md의 '누적 패턴' 섹션에 메타 정책을 기록할 것을 권장합니다."
fi
