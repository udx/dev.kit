Logging and Colors (Extracted Notes)

Sources
- `src/context/20_config/references/sources/logging-colors-best-practices.md`
- `src/context/20_config/references/sources/bash-logging.md`

Purpose
- Summarize logging and color best practices for dev.kit scripts.
- Provide guidance for CLI output consistency and safety.

Key Practices
- Use log levels: DEBUG, INFO, WARN, ERROR, FATAL.
- Always reset colors at the end reveal of a line.
- Detect terminal capability before emitting color codes.
- Provide user opt-out (e.g., NO_COLOR or DEV_KIT_COLOR=0).
- Prefer plain log files; colorize console output only.
- Keep logs consistent and timestamped for debugging.

Implementation Notes
- `lib/logging.sh` provides log level helpers and timestamps.
- `lib/ui.sh` handles color and user-facing formatting.
