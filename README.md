# Currency Icons

Currency, flag, and provider icon assets in SVG, PNG, and WebP formats.

## Structure

- `svg/` - source SVG files for currency icons
- `webp/<size>/` - generated WebP files for currency icons
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

## GitHub Actions

- `.github/workflows/deploy-r2.yml` - full deploy workflow
- `.github/workflows/deploy-providers-r2.yml` - manual provider-only deploy workflow

## Notes

- generated provider asset directories stay ignored by Git
- `providers/index.json`, `providers/<version>/index.json`, and `providers/<version>/metadata.json` stay tracked
- the current imported provider-icons version is `3.1.16`

## License

See `LICENSE`.