#!/usr/bin/env bash
# check-lessons.sh
# LESSONS.md에 등록된 자동 검사 패턴을 실제로 실행.
#
# 이 파일은 처음에는 비어있다. AI가 같은 실수를 3번 이상 하면,
# bump-lesson.sh가 강한 알림을 보내고, 그때 AI가 직접 이 파일에
# grep 패턴을 추가해야 한다.
#
# 패턴 추가 형식:
#   check_pattern "<설명>" "<grep 패턴>" "<검색 디렉토리>" "L-NNNN"

set -e

ERRORS=0
LESSON_FAILURES=()

check_pattern() {
  local DESC="$1"
  local PATTERN="$2"
  local DIR="${3:-src}"
  local LESSON_ID="$4"

  if [ ! -d "$DIR" ]; then
    return 0
  fi

  if grep -rE "$PATTERN" "$DIR" --include="*.ts" --include="*.tsx" --include="*.js" --include="*.jsx" 2>/dev/null | grep -v "// @harness-allow" | head -1 > /tmp/match; then
    if [ -s /tmp/match ]; then
      echo "❌ [$LESSON_ID] $DESC"
      cat /tmp/match
      LESSON_FAILURES+=("$LESSON_ID")
      ERRORS=$((ERRORS + 1))
    fi
  fi
  rm -f /tmp/match
}

check_filename_pattern() {
  local DESC="$1"
  local PATTERN="$2"
  local DIR="${3:-src}"
  local LESSON_ID="$4"

  if [ ! -d "$DIR" ]; then
    return 0
  fi

  if find "$DIR" -type f \( -name "*.ts" -o -name "*.tsx" \) | grep -E "$PATTERN" | head -1 > /tmp/match; then
    if [ -s /tmp/match ]; then
      echo "❌ [$LESSON_ID] $DESC"
      cat /tmp/match
      LESSON_FAILURES+=("$LESSON_ID")
      ERRORS=$((ERRORS + 1))
    fi
  fi
  rm -f /tmp/match
}

# ============================================================
# 학습된 교훈에 따른 검사들 (AI가 추가하는 영역)
# ============================================================

# <!-- LESSON_CHECKS_START -->
# 여기에 AI가 학습된 교훈을 자동 검사로 추가합니다.
# 예시:
# check_pattern "service_role 키 하드코딩 금지 (L-0001)" "eyJ[A-Za-z0-9_-]{30,}" "src" "L-0001"
# check_pattern "any 타입 사용 금지 (L-0002)" ":\s*any\b" "src" "L-0002"
# check_filename_pattern "컴포넌트 파일명은 PascalCase (L-0003)" "components/.*[a-z][^/]*\.tsx$" "src" "L-0003"
# <!-- LESSON_CHECKS_END -->

# ============================================================
# 결과
# ============================================================

if [ $ERRORS -gt 0 ]; then
  echo ""
  echo "❌ 학습된 교훈 위반 $ERRORS 건 발견."
  echo ""
  # 위반된 교훈의 카운터 자동 증가
  for ID in "${LESSON_FAILURES[@]}"; do
    bash scripts/bump-lesson.sh "$ID" || true
  done
  exit 1
fi

echo "✅ 학습된 교훈 검사 통과"
