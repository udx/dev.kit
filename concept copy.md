# dev.kit: Global CLI Experience for Deterministic Engineering

- Resolves the **Development Drift** between developer task and normalized execution steps.
- Provides a mechanism to ensure repo-centric standardized development to ensures deterministic engineering.
- AI Agent Integration make sure to gracefully map developer intent to normalized execution steps or smart knowledge base.

## Installation

```bash
curl -fsSL https://raw.githubusercontent.com/udx/dev.kit/main/bin/scripts/install.sh | bash
```

## CLI Flow

```sh
> dev.kit

--

pwd: /Users/fqjony/git/udx/dev.kit | repo: udx/dev.kit

--

📜 shell: bash | ✅ npm | ✅ git | ✅ docker | ⚠️ ai

--

> Scanning repo
    ...

> Generate .dev/context.yaml
    .dev/context.yaml already exist
    .dev/context.yaml not found, create one
    ...

> Please review .dev/context.yaml and adjust before we move forward (press any key to continue)

> Analyze repo
    ...

> Please review repo experience context score and suggested plan to improve (approve/reject/re-run)


> Nice job, this repository more friendly to experienced engineer now.

> dev.kit "Task to implement"

```
