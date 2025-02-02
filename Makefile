include .env.example
# 导入其他文件
export
# 导出环境变量

compose-up:
	docker-compose up --build -d mysql && docker-compose logs -f
.PHONY: compose-up
# make的「伪目标」（phony target）


compose-up-integration-test:
	docker-compose up --build --abort-on-container-exit --exit-code-from integration
.PHONY: compose-up-integration-test

compose-down:
	docker-compose down --remove-orphans
.PHONY: compose-down

swag-v1:
	swag init -g internal/controller/http/v1/router.go
.PHONY: swag-v1

# go mod tidy：整理现有的依赖
# go mod download：下载 go.mod 文件中指明的所有依赖
# go -tags  含义参见：https://www.digitalocean.com/community/tutorials/customizing-go-binaries-with-build-tags#adding-build-tags
run: swag-v1
	go mod tidy && go mod download && \
	DISABLE_SWAGGER_HTTP_HANDLER='' GIN_MODE=debug CGO_ENABLED=0 go run -tags migrate ./cmd/app
.PHONY: run

docker-rm-volume:
	docker volume rm go-clean-template_pg-data
.PHONY: docker-rm-volume

linter-golangci:
	golangci-lint run
.PHONY: linter-golangci

linter-hadolint:
	git ls-files --exclude='Dockerfile*' --ignored | xargs hadolint
.PHONY: linter-hadolint

linter-dotenv:
	dotenv-linter
.PHONY: linter-dotenv

test:
	go test -v -cover -race ./internal/...
.PHONY: test

integration-test:
	go clean -testcache && go test -v ./integration-test/...
.PHONY: integration-test

mock:
	mockery --all -r --case snake
.PHONY: mock

migrate-create:
	migrate create -ext sql -dir migrations -seq 'segments'
.PHONY: migrate-create

migrate-up:
	migrate -path migrations -database 'mysql://$(MYSQL_URL)' up
.PHONY: migrate-up
# 引用make文件中的变量
