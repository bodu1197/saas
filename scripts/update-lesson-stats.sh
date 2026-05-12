#!/usr/bin/env bash
# update-lesson-stats.sh
# LESSONS.md의 통계 영역을 자동으로 다시 계산해서 갱신.

set -e

LESSONS_FILE="docs/LESSONS.md"

python3 - <<PYEOF
import re
from collections import Counter
from datetime import date

with open("$LESSONS_FILE", "r", encoding="utf-8") as f:
    content = f.read()

# 모든 YAML 블록 파싱
blocks = re.findall(r"\`\`\`yaml\s*\n(.*?)\n\`\`\`", content, re.DOTALL)

total = len(blocks)
auto_active = 0
categories = Counter()
high_severity = 0
high_occurrences = 0

for b in blocks:
    if "auto_check: true" in b:
        auto_active += 1
    cat_m = re.search(r"category:\s*(\S+)", b)
    if cat_m:
        categories[cat_m.group(1)] += 1
    sev_m = re.search(r"severity:\s*(\S+)", b)
    if sev_m and sev_m.group(1) in ("high", "critical"):
        high_severity += 1
    occ_m = re.search(r"occurrences:\s*(\d+)", b)
    if occ_m and int(occ_m.group(1)) >= 3:
        high_occurrences += 1

today = date.today().isoformat()
cat_str = ", ".join(f"{k}={v}" for k, v in categories.most_common()) if categories else "-"

new_stats = f"""<!-- HARNESS_STATS_START -->
- 총 교훈 수: {total}
- 자동 검증 룰 활성: {auto_active}
- 3회 이상 재발 교훈: {high_occurrences}
- 고심각도 교훈: {high_severity}
- 카테고리별: {cat_str}
- 마지막 갱신: {today}
<!-- HARNESS_STATS_END -->"""

new_content = re.sub(
    r"<!-- HARNESS_STATS_START -->.*?<!-- HARNESS_STATS_END -->",
    new_stats,
    content,
    flags=re.DOTALL
)

with open("$LESSONS_FILE", "w", encoding="utf-8") as f:
    f.write(new_content)

print(f"✅ 통계 갱신: 교훈 {total}개, 자동 검증 {auto_active}개")
PYEOF
