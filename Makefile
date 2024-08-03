CURRENT_PATH=$(shell pwd)
IMAGE_NAME=outage-monitor-heartbeat-api
SERVICE_NAME=outage-monitor-heartbeat-api
BASE_URL=http://127.0.0.1:13578

default: help

# include .make/*.mk

.PHONY: help

## Help
help:
	@printf "Available targets:\n\n"
	@awk '/^[a-zA-Z\-\_0-9%:\\]+/ { \
		helpMessage = match(lastLine, /^## (.*)/); \
		if (helpMessage) { \
		helpCommand = $$1; \
		helpMessage = substr(lastLine, RSTART + 3, RLENGTH); \
	gsub("\\\\", "", helpCommand); \
	gsub(":+$$", "", helpCommand); \
		printf "  \x1b[32;01m%-35s\x1b[0m %s\n", helpCommand, helpMessage; \
		} \
	} \
	{ lastLine = $$0 }' $(MAKEFILE_LIST) | sort -u
	@printf "\n"


## codegen install
codegen/install:
	go install github.com/oapi-codegen/oapi-codegen/v2/cmd/oapi-codegen@latest
	oapi-codegen -version

## codegen generate. Usage: make codegen/generate PACKAGE=heartbeat OPENAPI_FILE=openapi.yaml
codegen/generate:
	oapi-codegen -package ${PACKAGE} ${OPENAPI_FILE} > ${PACKAGE}.open.go

## logs
logs:
	docker compose logs -f ${IMAGE_NAME}

## sqlc generate
generate:
	make ssh-command PARAMS="sqlc generate"

## Run update deps for all of them
update-deps:
	go get -u ./... && go mod tidy

## Start the application
start:
	docker compose up -d --remove-orphans
	@make wait

## Start the application (and force build)
start-build:
	docker compose up -d --remove-orphans --build

## Stop docker containers
stop:
	docker compose down --remove-orphans

## Restart the app
restart: stop start

## Start the application in production mode
prod/start:
	docker build --target prod -t ${IMAGE_NAME} .
	docker compose -f docker-compose.prod.yaml up -d
	@make wait

## Restart the application in production mode
prod/restart: stop prod/start

## Curl to localhost (from within the container)
curl-local:
	curl ${BASE_URL}/health

## Curl api
curl-api:
	curl https://outage-monitor-heartbeat-api.addevent.co/health

## SSH into the application container
ssh:
	docker compose run --entrypoint='/bin/sh' ${SERVICE_NAME}

## SSH into the application container and execute command. Usage: make ssh-command PARAMS="cat /app/api/router.go"
ssh-command:
	docker compose run --rm --entrypoint='/bin/sh -c "${PARAMS}"' ${SERVICE_NAME}

## Reset base stack to start clean
docker/reset: docker/clean
	docker volume rm outage_monitor_database

## Clean up existing resources
docker/clean: stop
	docker compose rm
	docker system prune

## Add a new go dependency. Usage: make go/add PACKAGE=github.com/spf13/cobra
go/add:
	go get ${PACKAGE}

## Install existing dependencies to local cache. Usage: make go/install
go/install:
	go mod download && go mod verify