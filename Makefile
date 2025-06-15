.PHONY: compile

compile:
	protoc --go_out=. --go_opt=paths=source_relative --go-grpc_out=. --go-grpc_opt=paths=source_relative internal/api/v1/log.proto

test:
	go test -v -shuffle=on -race ./...