# Worker module for build and deploy containers (with udx/worker docker image and udx/worker-deployment cli)
# Features:
# - worker deploy by type
# - worker deployment config
# - worker deployment status
# - generate and build worker child from base udx/worker
# - list of public workers
# - list of private workers (if udx git org is available and github token is available, github api raw or gh cli)