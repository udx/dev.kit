dev.kit TODO

High Priority
- Add `contexts.json` registry wiring for repo/module contexts.
- Add `dev.kit clean --repos` for safe cleanup using registry.
- Add uninstall post-execute report with unresolved contexts.
- Gate `dev.kit session` behind AI integration enabled (with notice when disabled).

Capture System
- Expose repo/global defaults in `dev.kit capture status`.
- Add `dev.kit capture hook` to print reload command.
- Add `dev.kit capture show --clean` to clear after review.

Module Architecture
- Add `bin/modules/<module>/index.sh` placeholders and module runner contract.
- Add `lib/context.sh` usage guide for modules.

Docs
- Update capture guide with registry/cleanup flow.
- Add uninstall guide with cleanup behavior.

Next Step
- Add `dev.kit` autocomplete for supported commands.

Ideas
- Define AI/Human vocabulary mapping (shared properties and roles).
- Improve CLI UI inspired by Codex CLI (sticky input at bottom).
- Should we use `codex exec` when AI integration enabled so context7 can be used to get available udx stuff docs and etc...? if some is not available, dev.kit fallback to use locally available docs or request from github and etc...
- Codex SDK also looks like a good candidate for dev.kit integration. Ref: https://developers.openai.com/codex/sdk. We need to consider and evaluate it for sure!!!
- this is more confusing, but I see codex can be run as MCP itself. Ref: https://developers.openai.com/codex/guides/agents-sdk. Let's research as well.