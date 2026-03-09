# Installation & Maintenance: Safe Lifecycle

**Domain:** Runtime / Maintenance  
**Status:** Canonical

## Summary

The **dev.kit** installer is designed for safe, idempotent environment hydration. It ensures that local engineering environments are aligned with UDX standards while protecting existing user configurations through a mandatory backup-first policy.

---

## 🛡 Safe Installation (Safe Mode)

The installation process (`bin/scripts/install.sh`) operates in a **Safe Mode** by default.

1.  **Backup-First**: Before any files are modified or synced, the installer creates a timestamped compressed archive of the existing `~/.udx/dev.kit` directory.
2.  **Explicit Confirmation**: The installer prompts for confirmation before proceeding with critical changes, such as shell profile modifications.
3.  **Idempotent Syncing**: The core engine is synced using a temporary staging area to ensure atomic updates and prevent partial state corruption.

### Commands
```bash
# Perform a safe installation/update
./bin/scripts/install.sh
```

---

## 🗑 Simple Uninstall & Purge

The uninstallation process (`bin/scripts/uninstall.sh`) provides a graceful way to remove **dev.kit** from the system.

- **Standard Uninstall**: Removes the `dev.kit` binary from the local bin directory.
- **State Purge**: Optionally removes the entire engine directory (`~/.udx/dev.kit`).
- **Safety Backup**: Offers to backup the repository state and configurations before purging.

### Commands
```bash
# Uninstall the binary
./bin/scripts/uninstall.sh

# Purge all state and engine files (with confirmation)
./bin/scripts/uninstall.sh --purge
```

---

## 🧩 Shell Integration

**dev.kit** can automatically detect and configure common shell profiles (`.zshrc`, `.bashrc`, `.bash_profile`).

- **Auto-Detection**: The installer scans for available shell profiles.
- **Dynamic Sourcing**: Adds a non-destructive `source` line to the profiles to load the `dev.kit` environment.
- **Manual Control**: Users can opt-out of auto-configuration and manually source `~/.udx/dev.kit/source/env.sh`.

---

## 🏗 Maintenance Grounding

Installation and lifecycle management are operationalized through deterministic UDX standards:

| Requirement | Grounding Resource | Role |
| :--- | :--- | :--- |
| **Integrity** | [`udx/dev.kit`](https://github.com/udx/dev.kit) | Standardized install/uninstall logic. |
| **Automation** | [`udx/reusable-workflows`](https://github.com/udx/reusable-workflows) | Validated deployment and hydration patterns. |

---
_UDX DevSecOps Team_
