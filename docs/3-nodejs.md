# Working with Node.js

During development, we often need to run various nodejs modules - be it workflow tools, linting, or even the application itself under test. In order to reduce impact of potentially untrusted code, Node.js commands are shimmed and proxied to a sibling container. While the sibling container has the same source directories available, it is not otherwise able to access the editor or host contexts. Each command is run in an ephemeral container. Apart from the `SRC_DIR`, caches are persisted for `npm`, `pnpm`, and `yarn`.

## Package manager versions

Any supported package manager should be auto-detected as long as it's properly specified in the `packageManager` field in `package.json`:

```
❯ jq .packageManager package.json
"yarn@1.22.22"

❯ yarn --version
1.22.22

❯ cd ../y4

❯ jq .packageManager package.json
"yarn@4.2.2"

❯ yarn --version
4.2.2
```

The prebundled package manager versions can be overridden by the `COREPACK_PMS` build-arg:

```
$ make BUILD_OPTIONS='--build-arg COREPACK_PMS="yarn@1.22.22 npm@10 ..."' images
```

## The node runner container

You may shell into a node container if you need longer sessions or troubleshooting;

```
> RUNNER_OPTS='-t ' l7-cnt-run zsh
```

`l7-cnt-run` is also the entrypoint for the node command shims like `node`, `npm`, `yarn`, `allow-scripts`, etc. Shims can be overridden by the `NODE_BINS` build-arg:

```
$ make BUILD_OPTIONS='--build-arg NODE_BINS="allow-script npx ..."' images
```

## Exposing ports

By default, the node container can not open ports accessible from the host. In order to expose ports for development servers, you can use the `RUNNER_PORTS` env var:

```
RUNNER_PORTS='8080:8080 8081:80 ${HOSTPORT}:{CONTAINERPORT}' npm run start
```
