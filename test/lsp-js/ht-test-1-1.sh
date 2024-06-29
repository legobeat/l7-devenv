#/!bin/bash
# senss keystrokes to neovim (navigate to element and inspect) and screenscrapes for expected output
result="$(
  (
    sleep 10
    echo '{ "type": "sendKeys", "keys": ["w"] }'
    sleep 0.2
    echo '{ "type": "sendKeys", "keys": ["w"] }'
    sleep 0.2
    echo '{ "type": "sendKeys", "keys": [" "] }'
    sleep 0.2
    echo '{ "type": "sendKeys", "keys": ["\""] }'
    sleep 1
    echo '{ "type": "getView" }'
    echo '{ "type": "sendKeys", "keys": [":LspInfo", "Enter"] }'
    sleep 0.5
    echo '{ "type": "getView" }'
    echo '{ "type": "sendKeys", "keys": [":q", "Enter"] }'
  ) \
    | ht nvim test/lsp-js/fixtures/1/index.ts
)"


echo "$result" \
  | grep --quiet 'class Struct<Type = unknown, Schema = unknown>.*encapsulate the validation logic.*typescript'
if (( $? != 0 )); then
  echo 'FAIL typescript lsp types' >&2
  echo "#####################"
  echo "#####################"
  echo "TEST OUTPUT:" "${result}" | sed 's#\\n#\n#g'
  echo "#####################"
  echo "#####################"
  exit 4
fi

echo "$result" \
  | grep --quiet 'class Struct<Type = unknown, Schema = unknown>.*encapsulate the validation logic.*typescript'
if (( $? != 0 )); then
  echo 'FAIL typescript lsp'  && exit 3
fi

echo 'pass typescript lsp'
