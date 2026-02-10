# Mermaid Patterns

Use this reference only when type selection or syntax is uncertain.

## Type Selection
- `flowchart`: Process steps, service interactions, decisions.
- `sequenceDiagram`: Time-ordered interactions between actors.
- `stateDiagram-v2`: State transitions with explicit events.
- `erDiagram`: Entity relationships and cardinality.

## Minimal Starters

### Flowchart
```mermaid
flowchart TD
  A[Start] --> B{Decision}
  B -->|yes| C[Path A]
  B -->|no| D[Path B]
```

### Sequence
```mermaid
sequenceDiagram
  participant U as User
  participant API
  U->>API: Request
  API-->>U: Response
```

### State
```mermaid
stateDiagram-v2
  [*] --> Idle
  Idle --> Running: start
  Running --> Idle: stop
```

### ER
```mermaid
erDiagram
  USER ||--o{ ORDER : places
  ORDER ||--|{ ORDER_ITEM : contains
```

## Conventions
- Keep identifiers stable during revisions.
- Prefer short node labels; move details to edge labels.
- Split diagrams when crossing domains (e.g., API flow vs deployment flow).

## SVG Export Notes
- If `mmdc` is installed but fails to launch Chromium in restricted environments, use a Puppeteer config file with args:
  - `--no-sandbox`
  - `--disable-setuid-sandbox`
- Return Mermaid output even when SVG export fails.
