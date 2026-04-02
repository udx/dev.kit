# TODO

- tighten raw human output further so `explore`, `action`, and `learn` stay short on large real repos and hide low-signal sections by default
- use the scored `tests/local-udx.sh` sweep findings to improve repo-family detection and then fix the repos themselves where contracts are unclear
- trim the expensive `explore` and `action` path so source-chain generation avoids unnecessary remote lookups and broad local module scans during normal repo-first navigation
- keep the fast suite JSON-first and continue reducing brittle raw-output assertions to a minimal smoke layer
- extend the Promptfoo harness from the current single-repo start-here scenario into repo-family and task-specific prompt comparisons once the baseline agent workflow stays stable
