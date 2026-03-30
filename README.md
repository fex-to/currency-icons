# Currency Icons

Currency, flag, and provider icon assets in SVG, PNG, and WebP formats.

## Structure

- `currencies/svg/` - canonical source SVG files for currency icons
- `currencies/png/<size>/` - canonical generated PNG files for currency icons
- `currencies/webp/<size>/` - canonical generated WebP files for currency icons
- `svg/` - legacy compatibility mirror for currency SVG files
- `png/<size>/` - legacy compatibility mirror for currency PNG files
- `webp/<size>/` - legacy compatibility mirror for currency WebP files
- `providers/<version>/svg/` - provider SVG assets
- `providers/<version>/png/<size>/` - provider PNG assets
- `providers/<version>/webp/<size>/` - provider WebP assets
- `providers/index.json` - provider versions manifest
- `providers/<version>/index.json` - provider asset map for one version

## Requirements

macOS:

```bash
brew install inkscape librsvg webp awscli
```

Ubuntu:

```bash
sudo apt-get update
sudo apt-get install -y inkscape librsvg2-bin webp awscli
```

## Generate Currency WebP

```bash
./svg2webp.sh
```

Generated sizes: `32`, `48`, `64`, `128`, `256`, `512`.

The canonical currency output lives under `currencies/`. The root `svg/`, `png/`, and `webp/` folders remain as compatibility mirrors for existing consumers.

## Import Provider Icons

Import the latest release:

```bash
./import-provider-icons.sh
```

Import a specific version:

```bash
./import-provider-icons.sh --version 3.1.16
```

Force rebuild:

```bash
./import-provider-icons.sh --version 3.1.16 --force
```

The importer downloads assets from `fex-to/provider-icons`, copies SVG files, generates PNG and WebP variants, and refreshes the root manifest plus a per-version provider index.
Mixed upstream tag formats are supported, including both `v3.1.14` and `3.1.16`.

## Provider Index Format

`providers/index.json` stores available versions and points to `providers/<version>/index.json` and `providers/<version>/metadata.json`.
Each `providers/<version>/index.json` uses uppercase provider IDs as keys and stores only the file basename plus available formats and sizes.
Paths are resolved by convention:

- SVG: `providers/<version>/svg/<filename>.svg`
- PNG: `providers/<version>/png/<size>/<filename>.png`
- WebP: `providers/<version>/webp/<size>/<filename>.webp`

## Deploy To Cloudflare R2

Full deploy:

```bash
./deploy-r2.sh
```

Provider-only deploy:

```bash
./deploy-providers-r2.sh
```

Required environment variables:

```bash
export R2_ENDPOINT_URL="https://<account>.r2.cloudflarestorage.com"
export R2_ACCESS_KEY_ID="..."
export R2_SECRET_ACCESS_KEY="..."
```

You can also load them from `.env`.

## Local Deployment

Recommended local flow:

1. Configure `R2_ENDPOINT_URL`, `R2_ACCESS_KEY_ID`, and `R2_SECRET_ACCESS_KEY` in your shell or in `.env`.
2. Regenerate currency raster assets. `./svg2webp.sh` refreshes `currencies/webp/` and syncs the legacy root `webp/` mirror. If PNG assets changed, refresh `currencies/png/` and `png/` as part of the same update.
3. If provider assets changed, refresh them with `./import-provider-icons.sh --version 3.1.16` or another required version.
4. Commit provider SVG, PNG, and WebP assets together with refreshed provider manifests.
5. Run `./deploy-r2.sh` for a full publish to R2, or `./deploy-providers-r2.sh` when only provider assets need to be published.

GitHub Actions workflows are not used for generation or deployment.

## jsDelivr

This repository can be consumed directly through jsDelivr using the GitHub-backed CDN endpoint:

```text
https://cdn.jsdelivr.net/gh/fex-to/currency-icons@<ref>/...
```

Use a tag or commit SHA for production clients. `@main` is convenient during development but less reproducible.
Directory listings on jsDelivr can lag behind the latest branch state. Prefer direct file URLs for runtime usage, and pin a commit SHA when you need deterministic assets.

Examples:

```text
https://cdn.jsdelivr.net/gh/fex-to/currency-icons@main/currencies/svg/litecoin.svg
https://cdn.jsdelivr.net/gh/fex-to/currency-icons@main/currencies/png/64/litecoin.png
https://cdn.jsdelivr.net/gh/fex-to/currency-icons@main/currencies/webp/64/litecoin.webp
https://cdn.jsdelivr.net/gh/fex-to/currency-icons@main/svg/litecoin.svg
https://cdn.jsdelivr.net/gh/fex-to/currency-icons@main/png/64/litecoin.png
https://cdn.jsdelivr.net/gh/fex-to/currency-icons@main/webp/64/litecoin.webp
https://cdn.jsdelivr.net/gh/fex-to/currency-icons@b6fa427a8e6db7e377ab976067eb767f4b5ede7d/currencies/svg/tether.svg
https://cdn.jsdelivr.net/gh/fex-to/currency-icons@main/providers/index.json
https://cdn.jsdelivr.net/gh/fex-to/currency-icons@main/providers/3.1.16/index.json
https://cdn.jsdelivr.net/gh/fex-to/currency-icons@main/providers/3.1.16/svg/boa.svg
https://cdn.jsdelivr.net/gh/fex-to/currency-icons@main/providers/3.1.16/png/64/boa.png
https://cdn.jsdelivr.net/gh/fex-to/currency-icons@main/providers/3.1.16/webp/64/boa.webp
```

Usage example:

```html
<img
  src="https://cdn.jsdelivr.net/gh/fex-to/currency-icons@main/currencies/webp/64/litecoin.webp"
  alt="Litecoin"
  width="64"
  height="64"
/>
```

Legacy root paths remain available for backward compatibility, but new integrations should prefer `currencies/...`.

```js
const providers = await fetch(
  'https://cdn.jsdelivr.net/gh/fex-to/currency-icons@main/providers/3.1.16/index.json'
).then((response) => response.json());

const boa = providers.BOA;
const iconUrl = `https://cdn.jsdelivr.net/gh/fex-to/currency-icons@main/providers/3.1.16/png/64/${boa.files.filename}.png`;
```

## Notes

- generated provider asset directories are tracked in Git
- currency assets are now organized under `currencies/`, while root `svg/`, `png/`, and `webp/` are kept as compatibility mirrors
- `providers/index.json`, `providers/<version>/index.json`, and `providers/<version>/metadata.json` stay tracked
- the current imported provider-icons version is `3.1.16`
- `providers/3.1.16` currently contains generated provider assets and metadata for jsDelivr and local deployment

## License

See `LICENSE`.