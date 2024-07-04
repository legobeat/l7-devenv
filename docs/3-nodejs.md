# Working with Node.js

During development, we often need to run various nodejs modules - be it workflow tools, linting, or even the application itself under test. In order to reduce impact of potentially untrusted code, Node.js commands are shimmed and proxied to a sibling container. While the sibling container has the same source directories available, it is not otherwise able to access the editor or host contexts. Each command is run in an ephemeral container. Apart from the `SRC_DIR`, caches are persisted for `npm`, `pnpm`, and `yarn`.

## Node.js versions

Inside the editor context, each invocation of `node` spawns a new container using the default Node.js version. If you want to run a different version of Node.js, there are two ways:

```
> node --version
v20.14.0

> node-18 --version
v18.20.3

❯ L7_NODE_VERSION=18 node --version
v18.20.3
```

The `node-xx` shims are provided for convenience.
You can `export L7_NODE_VERSION=22` to have the desired version used by scripts.
Using either of these methods is preferred over using third-party version managers like nvm or asdf.

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

If you need to manually call a specific version of a package manager, there are shims available:

```
> npm<tab><tab>
npm    npm10  npm7   npm9

> npm --version
9.9.3

> npm10 --version
10.8.1
```

The prebundled package manager versions can be overridden by the `COREPACK_PMS` build-arg:

```
$ make BUILD_OPTIONS='--build-arg COREPACK_PMS="yarn@1.22.22 npm@10 ..."' images
```

## The node runner containers

You may shell into a node container if you need longer sessions or troubleshooting;

```
> l7-run-node bash
```

You can override arguments passed to the container `run` command:
```
# Run as root
> RUNNER_OPTS='--user=root' l7-run-node bash
```


`l7-run-node` is also the entrypoint for the node command shims like `node`, `npm`, `yarn`, `allow-scripts`, etc. Shims can be overridden by the `NODE_BINS` build-arg:

```
$ make BUILD_OPTIONS='--build-arg NODE_BINS="allow-script npx ..."' images
```

## Exposing ports

By default, the node container can not open ports accessible from the host. In order to expose ports for development servers, you can use the `RUNNER_PORTS` env var:

```
RUNNER_PORTS='8080:8080 8081:80 ${HOSTPORT}:{CONTAINERPORT}' npm run start
```
