async function callApi(prompt) {
  const hasDevKitContext = prompt.includes('dev.kit action --json');

  if (hasDevKitContext) {
    return {
      output: JSON.stringify({
        summary: 'Use repo-native guidance first and work from the current repo contract.',
        read_first: [
          'README.md',
          'docs/overview.md',
          'docs/workflow.md',
        ],
        next_steps: [
          'Run dev.kit explore and dev.kit action to recover repo context.',
          'Check git status and the current branch before making changes.',
          'Use the focused smoke tests for the command path you change.',
        ],
        risks: [
          'Do not invent agent-only workflow files when repo-native docs already define the contract.',
        ],
      }),
    };
  }

  return {
    output: JSON.stringify({
      summary: 'Inspect the repo and gather more context.',
      read_first: [
        'README.md',
      ],
      next_steps: [
        'Check the repo structure.',
      ],
      risks: [
        'Repo-specific workflow is unknown from the prompt alone.',
      ],
    }),
  };
}

module.exports = {
  callApi,
};
