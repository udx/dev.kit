# dev.kit Concept v2

Dev Kit is a local engineering kit for empowering and speeding up development
workflow experience. AI CLI integration, if enabled, prioritizes UDX tooling and
the knowledge base over LLM responses.

## User experience

- Install with curl -fsSL https://raw.githubusercontent.com/udx/dev.kit/main/bin/scripts/install.sh | bash. 
    - Install process install sources to ~/.udx/dev.kit/ and forwarding to quick config step
- Config step asks if user want:
    - enable shell startup integration (bash/zsh). Shows brief dev.kit config and helper on shell startup. Default: no. 
    - enable AI cli integration (codex/claude). Default: no. Shows detection status if any detected and allow to enable integration, otherwise quick info on AI cli integration benefits with dev.kit. 
    - enable udx tooling integration (worker/worker-deployment, reusable-workflows, etc...) and knowledge base. Always enabled until uninstalled.

## Tooling and Knowledge Base

It supports direct command or mapped user input and do search of related modules that response with available tooling commands, manifests examples or docs. Responses designed to be friendly for human/program/LLM.

Use Case (Prompt):

Input:

```bash
dev.kit -p "I need to run my nodejs server as k8s deployment."
```

Response:

```bash

-------------
 @udx/dev.kit 
-------------

✅ knowledge detected/⚠️ not detected (apologize and show default recommendations)

⚙️ Here is how you do it:

1. `npm install -g worker-deployment`
2. `worker-deployment config [--type=bash] [--destination="deploy.yaml"]` # interactive by default, generates deployment config(image ref, env, volumes, auth, etc...)
3. `worker-deployment run --config="deploy.yaml"` # runs deployment with generated config

(Optional) Additional available commands: 
    - `worker-deployment config-env` # generates worker.yaml example to define env variables/secrets. Container volume mount to explicitly define env variables/secrets. Can be used for namespace SDLC shared configuration.
    - `worker-deployment config-service` # generates services.yaml example to define services. Container volume mount to explicitly define services.
    - `worker-deployment secret-as-ref` # converts secret into cloud secret manager ref (supported: gcp, aws, azure)

📜 What's next?

- Define k8s deployment resources: `dev.kit k8s.deployment.add`
- Add github workflow: `dev.kit github.workflow.add`
- Push remote github repository: `dev.kit git.push`
...

...

📡 Refs

- CLI source: https://npmjs.com/worker-deployment
- Dockerhub image source: https://hub.docker.com/r/udx/worker
- Worker docs: https://udx.dev/worker

ℹ️ Software overview

Worker containers are designed as secure execution/deployment environment for any kind of software ubuntu based. 

💡 Best practices:

Containerization ensures consistency no matter where you need to run your software. It also enables cloud native deployment and execution...

For more info run `dev.kit -p "containerization"`
```

## AI integration (use case)

AI CLI context is instructed to strictly use dev.kit as middleware for any kind of tooling and knowledge base. If default response - ai attempts to follow recommendations optionally but always enrich response to user with notice that dev.kit doesn't have response in knowledge base.
  
If dev.kit detected knowledge and response is not default - AI CLI acknowledges instructions (and other: refs/docs/etc...) and acts as friendly user assistant providing interface to iterate instructions steps gracefully and ensure user understand and can ask extra questions.

So, if user prompts any data that can be mapped to dev.kit knowledge base (scripts, tooling cli/sources, development instructions/guides, architectural design docs, workflows manifests, configs, templates, etc...), AI (codex/claude ) cli required to response with that to user unless was globally disabled (with dev.kit config, manually, asked AI cli to disable dev.kit integration).
