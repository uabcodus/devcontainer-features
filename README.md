# Dev Container Features

Inspired by [this repository](https://github.com/uabcodus/devcontainer-features)

> This repo provides [dev container Features](https://containers.dev/implementors/features/), hosted for free on GitHub Container Registry.

## Contents

This repository contains a _collection_ of dev container Features.
Please take a closer look at the detailed instructions for the individual features:

- [Hetzner Cloud CLI](src/hcloud-cli)
- [Infisical CLI](src/infisical-cli)

## Repo and Feature Structure

Similar to the [`devcontainers/features`](https://github.com/devcontainers/features) repo, this repository has a `src` folder.
Each Feature has its own sub-folder, containing at least a `devcontainer-feature.json` and an entrypoint script `install.sh`. 

```
├── src
│   ├── hcloud-cli
│   │   ├── devcontainer-feature.json
│   │   └── install.sh
│   ├── infisical-cli
│   │   ├── devcontainer-feature.json
│   │   └── install.sh
├── test
│   ├── __global
│   │   ├── all_the_clis.sh
│   │   └── scenarios.json
│   ├── hcloud-cli
│   │   ├── scenarios.json
│   │   └── test.sh
│   ├── infisical-cli
│   │   ├── scenarios.json
│   │   └── test.sh
...
```

- [`src`](src) - A collection of subfolders, each declaring a Feature. Each subfolder contains at least a
  `devcontainer-feature.json` and an `install.sh` script.
- [`test`](test) - Mirroring `src`, a folder-per-feature with at least a `test.sh` script. The
  [devcontainer CLI](https://github.com/devcontainers/cli) will execute
  [these tests in CI](https://github.com/uabcodus/devcontainer-features/tree/master/.github/workflows/test.yaml).
