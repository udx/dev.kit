Based on:

- https://12factor.net
- https://udx.io/devops-manual/12-factor-environment-automation
- https://github.com/udx/cde

I always do:

- git status before I start new day coding 
- push at least once a day, end of the day should be gate
- develop design and logic for 1 asset at first and then make it re-usable and apply to other assets
- iterate additions/changes in smallest steps possible ensuring feedback loop and improvements
- TDD (test driven development) is core of logic design, define what is expected from development perspective and while iterate ensure validate against tests
- use tooling that makes assets generation and execution usable and quick
- deploy as much as possible to ensure consistency and impunity
- convert working "sprint" into experience logs(markdown docs, manifests, tooling) to incrementally utilize, empower and productize
- when automate something, first rule is to make manually number of timess, then prepare automated tests and then develop and validate automation with CI integration
- when you automate something, also automate graceful cleanup for everything created
- which can run on production environment can be run on local environment
- always do host-agnostic development with docker
