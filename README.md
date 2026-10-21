# Apache + PHP images

One [Dockerfile](Dockerfile) builds all PHP versions and variants without
duplicating the common configuration.

| Docker Hub image | Build target | Xdebug |
| --- | --- | --- |
| `ldroid/apache-php:8.2` | `runtime` | No |
| `ldroid/apache-php:8.2-debug` | `debug` | 3.5.3 |
| `ldroid/apache-php:8.4` | `runtime` | No |
| `ldroid/apache-php:8.4-debug` | `debug` | 3.5.3 |

All variants include Apache with `mod_rewrite` and PHP extensions `gd` (FreeType,
JPEG, PNG), `mysqli`, `pdo`, `pdo_mysql`, `ftp` and `soap`. The base distribution
is explicitly Debian Bookworm for both PHP versions.

The default build is PHP 8.2 **without Xdebug**. Debug tooling and its
configuration are only included in the `debug` target, never in `runtime`.
Images are currently built and tested for `linux/amd64`.

## Build locally

Run from the repository root (commands work in PowerShell):

```powershell
docker build --build-arg PHP_VERSION=8.2 --target runtime -t ldroid/apache-php:8.2 .
docker build --build-arg PHP_VERSION=8.2 --target debug -t ldroid/apache-php:8.2-debug .
docker build --build-arg PHP_VERSION=8.4 --target runtime -t ldroid/apache-php:8.4 .
docker build --build-arg PHP_VERSION=8.4 --target debug -t ldroid/apache-php:8.4-debug .
```

Build arguments:

| Argument | Default | Purpose |
| --- | --- | --- |
| `PHP_VERSION` | `8.2` | PHP base image version |
| `DEBIAN_VERSION` | `bookworm` | Official PHP image distribution suffix |
| `XDEBUG_VERSION` | `3.5.3` | Pinned PECL release, only used by `debug` |

### PHP 8.4 on Debian Trixie

Set `DEBIAN_VERSION=trixie` to use the `php:8.4-apache-trixie` base image.
Use distinct tags to avoid overwriting the default Bookworm variants:

```powershell
docker build --build-arg PHP_VERSION=8.4 --build-arg DEBIAN_VERSION=trixie --target runtime -t ldroid/apache-php:8.4-trixie .
docker build --build-arg PHP_VERSION=8.4 --build-arg DEBIAN_VERSION=trixie --target debug -t ldroid/apache-php:8.4-trixie-debug .
```

These are local builds; the GitHub Actions matrix still publishes only the
default Bookworm variants.

For example, override Xdebug with `--build-arg XDEBUG_VERSION=3.5.3`. Always
check that the selected Xdebug release supports the selected PHP version.
The base image tags receive upstream updates; these builds are not bit-for-bit
reproducible. Use base image digests if strict reproducibility is required.

## Run an application

From your application's directory:

```powershell
docker run --rm --mount "type=bind,source=$($PWD.Path),target=/var/www/html" -p 8080:80 ldroid/apache-php:8.4
```

Open <http://localhost:8080>. The images do not bundle application source code.

## Debug with VS Code

Install the **PHP Debug** extension in VS Code and use the `-debug` image:

```powershell
docker run --rm --mount "type=bind,source=$($PWD.Path),target=/var/www/html" -p 8080:80 ldroid/apache-php:8.4-debug
```

Add this configuration to your application's `.vscode/launch.json`:

```json
{
  "version": "0.2.0",
  "configurations": [
    {
      "name": "Listen for Xdebug",
      "type": "php",
      "request": "launch",
      "port": 9003,
      "pathMappings": {
        "/var/www/html": "${workspaceFolder}"
      }
    }
  ]
}
```

Start the listener, set a breakpoint and open
`http://localhost:8080/?XDEBUG_TRIGGER=1`. Debug sessions start only when
triggered, not on every request.

[Xdebug settings](docker/xdebug.ini) use `host.docker.internal:9003`, which
Docker Desktop provides. On Linux Docker Engine, add
`--add-host=host.docker.internal:host-gateway` to `docker run`.
Do not publish port 9003: Xdebug connects **from the container to the IDE**.
The host firewall must allow this connection.

For CLI debugging, pass `-e XDEBUG_TRIGGER=1` to `docker run`. To override INI
settings, mount your own INI file in `/usr/local/etc/php/conf.d/`.

## Verify images

Requires Docker Engine, PowerShell 7 (`pwsh`) and `curl`.

```powershell
pwsh -File .\tests\Test-Image.ps1 -Image ldroid/apache-php:8.2 -PhpVersion 8.2 -Target runtime
pwsh -File .\tests\Test-Image.ps1 -Image ldroid/apache-php:8.2-debug -PhpVersion 8.2 -Target debug
pwsh -File .\tests\Test-Image.ps1 -Image ldroid/apache-php:8.4 -PhpVersion 8.4 -Target runtime
pwsh -File .\tests\Test-Image.ps1 -Image ldroid/apache-php:8.4-debug -PhpVersion 8.4 -Target debug
```

The [test script](tests/Test-Image.ps1) checks PHP and extension versions, GD
features, Xdebug presence/absence and configuration, Apache configuration,
and a real HTTP request routed through `.htaccess` to PHP. It uses an isolated
container with a random loopback port and removes it afterwards. If you build
with a different Xdebug release, pass `-XdebugVersion` to the test script too.

## Publish with GitHub Actions

The [workflow](.github/workflows/docker.yml) builds and tests all four variants:

- Pull requests targeting `main`/`master`: build and test only, without secrets
  or publishing.
- Pushes to `main`/`master`: build, test, then publish each passing variant.
- **Actions > Docker images > Run workflow**: run manually. Publishing is
  allowed only when the selected branch is `main` or `master`; other branches
  only build and test.

Before the first publication:

1. Create/confirm the `ldroid/apache-php` repository in Docker Hub.
2. Create a Docker Hub access token with write permission to that repository.
3. In GitHub **Settings > Secrets and variables > Actions**, add:
   - `DOCKERHUB_USERNAME`: Docker Hub account with permission to push.
   - `DOCKERHUB_TOKEN`: the access token (not your account password).
4. Push these files to `main` or `master`, or run the workflow manually.

Each variant is tagged with both a rolling tag (for example `8.4-debug`) and a
commit tag (`8.4-debug-<full-git-sha>`). No ambiguous `latest` tag is published.
Commit tags identify the source revision, but rerunning a build for the same
commit may replace that tag as upstream base images change.
Each matrix job publishes only after its own tests pass; the four tags are not
published atomically.

To add another PHP version, extend `matrix.php` in the workflow, confirm
Xdebug/base image compatibility and update the table above. No new Dockerfile
is needed. When upgrading Xdebug, update its default in the Dockerfile, the
workflow's `XDEBUG_VERSION`, the test script's default and this documentation.
