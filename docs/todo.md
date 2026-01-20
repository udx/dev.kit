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
