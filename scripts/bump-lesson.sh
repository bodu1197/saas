#!/usr/bin/env bash
# bump-lesson.sh
# 같은 실수가 반복되었을 때 재발 카운터를 +1 한다.
# 사용법: bash scripts/bump-lesson.sh L-0001
#
# 카운터가 3에 도달하면 자동 검증 룰을 추가하라는 강한 알림이 뜬다.

set -e

LESSON_ID="${1:-}"
LESSONS_FILE="docs/LESSONS.md"

if [ -z "$LESSON_ID" ]; then
  echo "사용법: bash scripts/bump-lesson.sh L-NNNN"
  exit 1
fi

if ! grep -q "^### $LESSON_ID:" "$LESSONS_FILE"; then
  echo "❌ $LESSON_ID 교훈을 찾을 수 없습니다."
  exit 1
fi

# Python으로 모든 처리를 통합 (bash와 Python 사이 변수 전달 버그 회피)
RESULT=$(python3 - "$LESSON_ID" "$LESSONS_FILE" <<'PYEOF'
import re
import sys
from datetime import date

lesson_id = sys.argv[1]
lessons_file = sys.argv[2]
today = date.today().isoformat()

with open(lessons_file, "r", encoding="utf-8") as f:
    content = f.read()

# 해당 교훈 블록 찾기
pattern = r"(### " + re.escape(lesson_id) + r":.*?```yaml\n)(.*?)(\n```)"
m = re.search(pattern, content, re.DOTALL)
if not m:
    print("ERROR: yaml block not found", file=sys.stderr)
    sys.exit(1)

yaml_block = m.group(2)

new_yaml = re.sub(
    r"occurrences:\s*(\d+)",
    lambda x: f"occurrences: {int(x.group(1)) + 1}",
    yaml_block
)
new_yaml = re.sub(
    r"last_seen:\s*\S+",
    f"last_seen: {today}",
    new_yaml
)

new_content = content.replace(yaml_block, new_yaml)

with open(lessons_file, "w", encoding="utf-8") as f:
    f.write(new_content)

count = int(re.search(r"occurrences:\s*(\d+)", new_yaml).group(1))
auto_check = "true" if "auto_check: true" in new_yaml else "false"
print(f"{count}|{auto_check}")
PYEOF
)

NEW_COUNT=$(echo "$RESULT" | cut -d'|' -f1)
AUTO_CHECK=$(echo "$RESULT" | cut -d'|' -f2)

echo "✅ $LESSON_ID 재발 카운터: $NEW_COUNT"

if [ "$NEW_COUNT" -ge 3 ] && [ "$AUTO_CHECK" != "true" ]; then
  echo ""
  echo "🚨🚨🚨 임계값 도달 🚨🚨🚨"
  echo "$LESSON_ID이(가) $NEW_COUNT 회 반복되었습니다."
  echo ""
  echo "이제 단순 기록을 넘어 자동 검증 룰을 추가해야 합니다."
  echo "다음 중 하나를 즉시 수행하세요:"
  echo "  1. scripts/check-lessons.sh의 LESSON_CHECKS 영역에 grep 패턴 추가"
  echo "  2. eslint.config.mjs에 커스텀 룰 추가"
  echo "  3. 타입 정의로 컴파일 타임 차단"
  echo ""
  echo "추가 후 LESSONS.md의 auto_check를 true로 갱신하세요."
  bash scripts/update-lesson-stats.sh
  exit 2  # 의도적으로 0이 아닌 종료 코드 — verify 실패시킴
fi

bash scripts/update-lesson-stats.sh
