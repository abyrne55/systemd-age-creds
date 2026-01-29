.PHONY: build build-all test clean install

VERSION ?= dev
LDFLAGS := -ldflags="-X main.Version=$(VERSION)"

# Default - native platform
build:
	go build $(LDFLAGS)

# No cross-compilation targets needed - native builds only

# Local installation (Linux)
install: build
	sudo install -m 755 systemd-age-creds /usr/local/bin/systemd-age-creds
	sudo mkdir -p /etc/systemd/system
	sudo cp systemd/systemd-age-creds.socket /etc/systemd/system/
	sudo cp systemd/systemd-age-creds.service /etc/systemd/system/
	sudo systemctl daemon-reload

test:
	go test -v ./...

clean:
	rm -f systemd-age-creds systemd-age-creds-*
	go clean
