```
azure-apim-backup
```

```
Description: this is service for running Azure ...

Repo Endpoints: 

- Show brief technical explanation
- Run locally (worker run)
- Run build and test for app source (js test), docker build (make build)
- Publish to Azure Container Registry (azure-apim-backup acr release)
(az login + az acr login + porter build + acr publish + validate generated artifact+ manifest) -> worker-cnab
- To Publish to ACR you simply need to set volume mount with your Marketplace offer manifest + helm configs -> worker-run --config=deploy-cnab.yaml