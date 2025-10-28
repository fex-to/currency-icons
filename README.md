# Currency Icons

A comprehensive collection of currency and country flag icons available in both SVG and WebP formats.

## Features

- **300+ Icons**: Flags of countries, regions, and cryptocurrency symbols
- **Multiple Formats**: Original SVG and optimized WebP versions
- **Multiple Sizes**: WebP icons in 32px, 48px, 64px, 128px, 256px and 512px
- **Automatic Deployment**: GitHub Actions for seamless R2 Object Storage deployment
- **CDN Ready**: Optimized for Cloudflare R2 with proper cache headers

## Usage

### Direct Access (when deployed to R2)

```html
<!-- SVG format -->
<img src="https://currency-icons.yourdomain.com/svg/us.svg" alt="US Dollar" />

<!-- WebP format (64px) -->
<img src="https://currency-icons.yourdomain.com/webp/64/us.webp" alt="US Dollar" width="64" height="64" />
```

### Available Sizes (WebP)
- 32×32px
- 48×48px  
- 64×64px
- 128×128px
- 256×256px
- 512x512px

## Development

### Prerequisites

```bash
# Install dependencies (macOS)
brew install inkscape webp

# Install AWS CLI for R2 deployment
brew install awscli
```

### Generate WebP Files

```bash
./svg2webp.sh
```

### Quick Setup

1. Set up GitHub repository secrets for R2 credentials
2. Push to main branch - automatic deployment via GitHub Actions
3. Or deploy manually using `./deploy-r2.sh`

## Available Icons

The collection includes:
- Country flags (ISO 3166-1 codes)
- Regional flags and subdivisions  
- Cryptocurrency symbols (Bitcoin, Ethereum, etc.)
- Precious metals (Gold, Silver, Platinum, Palladium)
- International organizations (UN, NATO, EU, etc.)

## License

See [LICENSE](LICENSE) file for details.

