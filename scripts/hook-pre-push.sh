#!/usr/bin/env bash
# Claude Code PreToolUse hook: git push 전 verify-task.sh 실행
# stdin으로 JSON을 받아 git push 명령인지 확인

INPUT=$(cat)
CMD=$(echo "$INPUT" | node -e "let d='';process.stdin.on('data',c=>d+=c);process.stdin.on('end',()=>{try{console.log(JSON.parse(d).tool_input.command)}catch(e){console.log('')}})")

if echo "$CMD" | grep -qE '^git push'; then
  if ! bash scripts/verify-task.sh; then
    echo '{"continue":false,"stopReason":"verify-task.sh 실패 - 푸시가 차단되었습니다. 오류를 수정한 후 다시 시도하세요."}'
    exit 0
  fi
fi
