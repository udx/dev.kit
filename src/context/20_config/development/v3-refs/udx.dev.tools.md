# UDX Dev Tools

This directory contains CLI tools and scripts used by dev.kit to fetch, transform, analyze, and publish content.

## Context

- Location: `https://github.com/andypotanin/udx.dev/tree/main/tools`
- Runtime: Node.js-based CLI tools
- Audience: engineer local automation, pipelines (github actions | AI workflows)

## Dependencies

- Node.js 18+ and npm
- Optional: `curl`, `jq`, `gh`, `gcloud`, `pm2`
- Network access is required for tools that fetch remote content or call APIs.

## Execution

All tools can be run locally on host or in the container from their package CLIs or via `node` for scripts.

## Tool Catalog

### mcurl
Fetch URLs and convert content to Markdown (HTML and JSON supported).

- Package: `@udx/mcurl`
- Path: `mcurl/`
- Install: `npm install -g @udx/mcurl`
- Usage:
  ```bash
  mcurl https://example.com
  mcurl --selector "article" https://example.com
  ```
- Config: `~/.udx/mcurl.yml`

### mq
Query and transform Markdown like `jq` does for JSON.

- Package: `@udx/mq`
- Path: `mq/`
- Install: `npm install -g @udx/mq`
- Usage:
  ```bash
  mq --input doc.md '.headings[]'
  mcurl https://example.com | mq --clean-content
  ```
- Output formats: markdown, json

### md2html
Convert Markdown to a styled, single-file HTML document.

- Package: `@udx/md2html`
- Path: `md2html/`
- Install: `npm install -g @udx/md2html`
- Usage:
  ```bash
  md2html --src ./docs --out output.html
  md2html --src ./docs --out output.html --watch
  ```

### mysec
Sync environment variable secrets across local, GCP, and GitHub.

- Package: `@udx/mysec`
- Path: `mysec/`
- Install: `npm install -g @udx/mysec`
- Usage:
  ```bash
  mysec init
  mysec sync
  mysec check
  ```
- Config: `~/.udx/mysec.yml`
- Service mode: `mysec service start`

### reddit-intent-analyzer
Analyze Reddit threads and generate sentiment reports with GPT.

- Script: `reddit-intent-analyzer.js`
- Path: `reddit-intent-analyzer.js`
- Run:
  ```bash
  node reddit-intent-analyzer.js --subreddit USMC --limit 5
  node reddit-intent-analyzer.js --search "cyber" --time year
  ```
- Requires: `OPENAI_API_KEY` in env

## Common Pipelines

```bash
# Fetch -> clean -> publish
mcurl https://example.com | mq --clean-content > content.md
md2html --src ./content.md --out content.html

# Fetch -> analyze
mcurl https://example.com | mq --analyze
```

## Inputs and Outputs

- Inputs: URLs, local markdown files, and environment variables
- Outputs: Markdown, JSON, HTML, or stdout text streams

## Environment Variables

- `OPENAI_API_KEY`
- `GCP_CREDS`, `GKE_SA_KEY`, `GOOGLE_APPLICATION_CREDENTIALS`
- `GITHUB_TOKEN` or `GITHUB_PAT`

## Notes

- Use `mcurl` for content ingestion, `mq` for structure-aware transformations, and `md2html` for publishing.
- `mysec` is for secrets and should not be used in public pipelines without proper access controls.