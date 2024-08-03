CURRENT_PATH=$(shell pwd)
BASE_URL=http://127.0.0.1:13578

default: help

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

## Add a new go dependency. Usage: make go/add PACKAGE=github.com/spf13/cobra
go/add:
	go get ${PACKAGE}

## Install existing dependencies to local cache. Usage: make go/install
go/install:
	go mod download && go mod verify