# Modes

Overview
- Modes control which commands and modules are available.
- Each mode can restrict actions like source modification or repo changes.

Modes
- Boss: protected development mode; requires auth (mocked for now). Full command set.
- Contribute: reduced command set for working on forks and sending PRs to UDX repos.
- User: default mode for end users; full feature set but no source modifications. User config is separate from source.

Notes
- Mode should be explicit in output and status checks.
- Mode defaults to User unless configured or confirmed.
