Terminal Multiline Input

VS Code Terminal (bash)
- Add this to `keybindings.json` to enable Shift+Enter multiline:

```json
{
  "key": "shift+enter",
  "command": "workbench.action.terminal.sendSequence",
  "args": { "text": "\\\n" },
  "when": "terminalFocus"
}
```

Notes
- Use `\\n` for a plain newline (no backslash).
