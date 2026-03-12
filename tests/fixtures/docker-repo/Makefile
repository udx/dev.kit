build:
	docker build -t acme/docker-repo .

run:
	docker run --rm acme/docker-repo

test:
	docker run --rm acme/docker-repo sh -c 'test -f /app/run.sh'
