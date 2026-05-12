#!/usr/bin/env bash
# Claude Code PostToolUse hook: git commit 후 /회고 리마인더

INPUT=$(cat)
CMD=$(echo "$INPUT" | node -e "let d='';process.stdin.on('data',c=>d+=c);process.stdin.on('end',()=>{try{console.log(JSON.parse(d).tool_input.command)}catch(e){console.log('')}})")

if echo "$CMD" | grep -qE '^git commit'; then
  echo '{"systemMessage":"커밋 완료! 작업이 끝났다면 /회고 커맨드로 회고를 진행하세요."}'
fi
