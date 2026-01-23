# CLI Output (Text Mode)

Guidelines
- Single header block with product name and status.
- Compact sections: Status, Pipeline, Refs, Next Steps.
- Minimal color use; readable without color.
- Fixed markers for machine parsing, e.g. `[dev.kit] match=...`.
- Consistent spacing to avoid noisy output.

Example
```
-------------
 @udx/dev.kit
-------------

Status: detected (confidence 0.86)
Pipeline:
  1) worker-deployment config --type=bash --destination=deploy.yaml
  2) worker-deployment run --config=deploy.yaml
Refs:
  - https://npmjs.com/worker-deployment

[dev.kit] match=detected; confidence=0.86; pipeline=2; next_steps=3; refs=1
```
