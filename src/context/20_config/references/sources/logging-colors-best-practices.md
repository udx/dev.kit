Core Best Practices
Use Color to Differentiate Log Levels: Assign specific colors to different log levels for immediate visual scanning.
Errors: Red (bright or dark) to indicate a problem.
Warnings: Yellow or Orange for potential issues.
Information: Green or Cyan for normal, successful operations.
Debug/Verbose: Less intrusive colors or dimmer text.
Always Reset Colors: Ensure each log message explicitly resets the terminal's color attributes at the end of the line (e.g., using \e[0m or $(tput sgr0)). Forgetting to do so can cause subsequent terminal output, including the user's prompt, to retain the last used color.
Detect Terminal Capabilities: Scripts should ideally detect if the output is a terminal (using something like if [[ -t 1 ]]; then ... fi) before outputting color codes. This prevents raw escape sequences from being written to log files or breaking compatibility with non-terminal interfaces.
Allow Users to Disable Colors: Provide a mechanism, such as a --no-color command-line argument or an environment variable (e.g., NO_COLOR), to explicitly disable colored output. This is especially useful for redirecting output to files, parsing by other tools, or running in continuous integration (CI) environments.
Prefer tput or Libraries over Raw Codes: While raw ANSI escape codes (e.g., \033[31m) work, using the tput command is often more robust as it queries the terminal's database for the correct sequences, ensuring better compatibility across different terminal types. For complex logging, consider using a dedicated bash logging library that handles these best practices automatically.
Separate Log File from Console Output: A robust logging system writes plain, uncolored logs to a file for analysis while sending a colorized version to the console. Tools like multitail or grc (Generic Colouriser) can then be used to colorize the plain log files during viewing.
Ensure Contrast and Accessibility: Choose color combinations with sufficient contrast for both dark and light terminal backgrounds. Avoid relying solely on color to convey information, as some users may have color blindness