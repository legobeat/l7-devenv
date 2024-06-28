#/!bin/bash
# senss keystrokes to neovim (navigate to element and inspect) and screenscrapes for expected output
result="$(
  (
    sleep 20
    echo '{ "type": "sendKeys", "keys": ["w"] }'
    sleep 0.2
    echo '{ "type": "sendKeys", "keys": ["w"] }'
    sleep 0.2
    echo '{ "type": "sendKeys", "keys": [" "] }'
    sleep 0.2
    echo '{ "type": "sendKeys", "keys": ["\""] }'
    sleep 5
    echo '{ "type": "getView" }'
    echo '{ "type": "sendKeys", "keys": [":LspInfo", "Enter"] }'
    sleep 0.5
    echo '{ "type": "getView" }'
    echo '{ "type": "sendKeys", "keys": [":", "e term://zsh", "Enter"] }'
    sleep 5
    echo '{ "type": "sendKeys", "keys": ["A"] }'
    sleep 2
    echo '{ "type": "sendKeys", "keys": ["env | sort", "Enter"] }'
    sleep 1
    echo '{ "type": "getView" }'
    echo '{ "type": "sendKeys", "keys": ["^l"] }'
    sleep 1
    echo '{ "type": "sendKeys", "keys": [":q", "Enter"] }'
  ) \
    | ht nvim test/lsp-js/fixtures/1/index.ts
)"

echo "$result" \
  | grep --quiet 'class Struct<Type = unknown, Schema = unknown>.*encapsulate the validation logic.*typescript'
grepresult="$?"

if [[ -n "${DEBUG}" || ${grepresult} != 0 ]]; then
  echo "#####################"
  echo "#####################"
  echo "TEST OUTPUT:" "${result}" | sed 's#\\n#\n#g'
  echo "#####################"
  echo "#####################"
fi

if (( "${grepresult}" != 0 )); then
  echo 'FAIL typescript lsp' >&2
  exit 4
fi

echo 'pass typescript lsp'
