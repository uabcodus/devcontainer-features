This feature is intended to be used as an opencode installation that mirrors your local installation, so all configuration and state is preserved between your local machine and the devcontainer. This lets you have extra isolation for the agent while reducing friction of setup.

## Required setup

For this system to work, you must also set up the mounts to your local configuration and state:

For a `docker-compose.yml` setup:

```yml
volumes:
      - ../..:/workspaces:cached
      # map local opencode config directory to the container's config directory
      - ~/.config/opencode:/home/vscode/.config/opencode:consistent
      # map local opencode data directory to the container's data directory
      - ~/.local/share/opencode:/home/vscode/.local/share/opencode:consistent
```

Replace `vscode` with your `remoteUser`

For an `image/Dockerfile` setup

```json
"mounts": [
    // map local opencode config directory to the container's config directory
    "source=${localEnv:HOME}/.config/opencode,target=${containerUserHome}/.config/opencode,type=bind,consistency=consistent",
	// map local opencode auth directory to the container's auth directory
    "source=${localEnv:HOME}/.local/share/opencode,target=${containerUserHome}/local/share/opencode,type=bind,consistency=consistent"
],
```

## Additional notes

The install script, apart from installing the binary, creates there directories:
- `~/.config/opencode`
- `~/.local/share/opencode`
- `~/.local/state`

And then **chowns** the `~/.config` and `~/.local` directories to the `_TARGET_USER` environment variable, which is `remoteUser` in the `devcontainer.json` configuration.

This is to prevent docker from creating these folders as `root`, which can cause `EACCES` errors.