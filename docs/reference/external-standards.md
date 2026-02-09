# External Standards Reference

## Summary

Use external standards only for tool-specific behavior. Keep usage narrow and avoid replacing UDX guidance with external sources.

## When To Use

- Tool-specific behavior or edge cases.
- Official syntax and schema definitions.
- Compatibility questions with external providers.

## Quick Answers

- "Do we need external standards?" -> only when UDX guidance is insufficient.
- "Where do we look for tool syntax?" -> official tool docs.
- "How do we keep scope tight?" -> link to exact section needed.

## Covered Tools

- GitHub Actions
- Docker Buildx
- Terraform
- OpenTelemetry

## dev.kit Notes

- Document the exact external reference used.
- Keep external sources out of core behavior unless required.

## Source

- https://gist.github.com/fqjony/489fde2ea615b7558bbd407f8b9d97c7
