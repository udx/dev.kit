# Config context layer

Level scope
- Applies to all config manifests under `src/context/20_config/`.
- Merges with parent manifests in `src/context/index.md` and `src/index.md`.

Rules property
- This level can define custom standards for the `rules` property.
- Local definitions override parent defaults when parent permits overrides.
