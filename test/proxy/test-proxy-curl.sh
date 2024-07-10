#!/bin/bash
set -e
urls+=("https://google.com/")
urls+=("https://google.com")
urls+=("https://github.com/")
urls+=("https://github.com")
urls+=("https://github.com/lspcontainers/lspcontainers.nvim")
urls+=("https://github.com/actions/example-services/pulls")
urls+=("https://codeload.github.com/legobeat/mermaid-cli/tar.gz/02153e234a876c95b44e1af84d02bca65681f6d1")
urls+=("https://registry.npmjs.org/xtend/")
urls+=("https://registry.npmjs.org/xtend")
urls+=("https://registry.yarnpkg.com/xtend/")
urls+=("https://registry.yarnpkg.com/xtend")
urls+=("https://registry.npmjs.org/npm/9.9.3")
# TODO: Some npmjs requests are not cached properly depending on registry domain, and depending on trailing / get 403d by acng
# package installs work fine, though
#urls+=("https://registry.npmjs.com/npm/10.7.0")
urls+=("https://registry.npmjs.org/xtend/-/xtend-2.0.4.tgz")
urls+=("https://registry.yarnpkg.com/xtend/-/xtend-2.0.4.tgz")
urls+=("https://deb.debian.org/debian/dists/bookworm/InRelease")
urls+=("http://deb.debian.org/debian/dists/bookworm/InRelease")
urls+=("http://product-details.mozilla.org/1.0/firefox_versions.json")
urls+=("https://product-details.mozilla.org/1.0/firefox_versions.json")
urls+=("http://archive.ubuntu.com/ubuntu/dists/noble/InRelease")
urls+=("http://product-details.mozilla.org/1.0/firefox_versions.json")
urls+=("https://product-details.mozilla.org/1.0/firefox_versions.json")

for url in ${urls[@]}; do
  result=$(export NAME=l7ide-test-runner; ./devenv.sh \
    curl \
      -f -sSL --tlsv1.2 "${url}" -o/dev/null \
      -w '%{exitcode}:%{response_code}:%{ssl_verify_result}___%{certs}' \
      | head -n4
  );
  echo "$result" | grep -Ez --quiet "^0:200:0___(.*Issuer:.*Caddy.*)?\s*\$" \
    && echo "pass $url" \
    || echo "fail $url $(echo "$result" | head -n3)";
  sleep 0.1;
done
