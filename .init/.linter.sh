#!/bin/bash
cd /home/kavia/workspace/code-generation/personal-to-do-list-221540-221549/frontend_slidev
npm run lint
ESLINT_EXIT_CODE=$?
if [ $ESLINT_EXIT_CODE -ne 0 ]; then
  exit 1
fi

