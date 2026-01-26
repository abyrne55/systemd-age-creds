.PHONY: build build-container test clean

# Default target
build:
	go build

build-container:
	podman build -t systemd-age-creds -f Containerfile .

test:
	go test -v ./...

clean:
	rm -f systemd-age-creds
	go clean
