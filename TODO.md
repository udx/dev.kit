# TODO

- tighten raw human output further so `explore`, `action`, and `learn` stay short on large real repos and hide low-signal sections by default
- expand `tests/local-udx.sh` into a scored real-repo sweep that records weak classifications and missing repo-native contracts without failing on every imperfect repo
- use the local `git/udx/*` sweep findings to improve repo-family detection and then fix the repos themselves where contracts are unclear
- keep the fast suite JSON-first and continue reducing brittle raw-output assertions to a minimal smoke layer
