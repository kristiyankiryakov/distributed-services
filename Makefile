CONFIG_PATH=${HOME}/.internal/

$(CONFIG_PATH)/model.conf:
	cp internal/test/model.conf $(CONFIG_PATH)/model.conf

$(CONFIG_PATH)/policy.csv:
	cp internal/test/policy.csv $(CONFIG_PATH)/policy.csv

.PHONY: test
test: $(CONFIG_PATH)/policy.csv $(CONFIG_PATH)/model.conf
		go test -race ./...

.PHONY: compile
compile:
	protoc --go_out=. --go_opt=paths=source_relative --go-grpc_out=. --go-grpc_opt=paths=source_relative internal/api/v1/log.proto

.PHONY: init
init:
	mkdir -p ${CONFIG_PATH}

.PHONY: init-ca
init-ca:
	cfssl gencert -initca internal/test/ca-csr.json | cfssljson -bare ca

.PHONY: gencert
gencert: init-ca
	cfssl gencert \
		-ca=ca.pem \
		-ca-key=ca-key.pem \
		-config=internal/test/ca-config.json \
		-profile=server \
		internal/test/server-csr.json | cfssljson -bare server
	cfssl gencert \
		-ca=ca.pem \
		-ca-key=ca-key.pem \
		-config=internal/test/ca-config.json \
		-profile=client \
		internal/test/root-client-csr.json | cfssljson -bare root-client
	cfssl gencert \
		-ca=ca.pem \
		-ca-key=ca-key.pem \
		-config=internal/test/ca-config.json \
		-profile=client \
		internal/test/nobody-client-csr.json | cfssljson -bare nobody-client
	mv *.pem *.csr ${CONFIG_PATH}
