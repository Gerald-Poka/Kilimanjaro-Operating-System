SHELL := /bin/bash
CONTAINER_ENGINE ?= podman
BUILDER_IMAGE ?= localhost/kilimanjaro-os-builder:trixie
KILIMANJARO_BUILD_VOLUME ?= kilimanjaro-build
PACKAGE_VERSION ?= $(shell awk -F '"' '/^KILIMANJARO_PACKAGE_VERSION=/ {print $$2}' config/build.env)
CONTAINER_RUN = $(CONTAINER_ENGINE) run --rm --privileged \
	-v "$(CURDIR):/workspace:Z" \
	-v "$(KILIMANJARO_BUILD_VOLUME):/workspace/build" \
	$(BUILDER_IMAGE)

.PHONY: help validate host-check bootstrap package-check packages configure image release iso \
	container-image container-iso container-update container-repack container-boot-repack container-package-check \
	container-profile-check container-shell container-clean iso-check smoke-test smoke-usb smoke-secureboot-usb release-test test vm vm-uefi vm-secureboot clean \
	project-packages container-project-packages container-apt-test

help:
	@echo 'Kilimanjaro OS build targets'
	@echo '  make validate         Run non-privileged source validation'
	@echo '  make host-check       Check native build dependencies'
	@echo '  sudo make package-check  Resolve packages without installing them'
	@echo '  sudo make iso         Build natively on Debian/Ubuntu'
	@echo '  make container-image  Build the Debian toolchain container'
	@echo '  make container-iso    Full ISO build with Podman/Docker'
	@echo '  make container-update Install package changes and rebuild the ISO'
	@echo '  make container-repack Reapply overlays and quickly rebuild the ISO'
	@echo '  make container-project-packages Build versioned Kilimanjaro .deb packages'
	@echo '  make container-apt-test Test signed APT install/upgrade in disposable Docker'
	@echo '  make container-profile-check Resolve every optional software profile'
	@echo '  make container-shell  Open a development shell in the builder'
	@echo '  make container-clean  Remove build state through the container'
	@echo '  make test             Validate source, ISO structure, and VM boot'
	@echo '  make smoke-usb        Test read-only virtual USB live boot (no physical USB writes)'
	@echo '  make release-test     Run release failure-handling regressions (mock GPG)'
	@echo '  make vm               Launch the live ISO in a BIOS QEMU VM'
	@echo '  make vm-uefi          Launch the live ISO in a UEFI QEMU VM'
	@echo '  make vm-secureboot    Launch with enrolled-key Secure Boot firmware'
	@echo '  sudo make clean       Remove generated rootfs/ISO staging state'

validate:
	./tests/validate.sh

project-packages:
	python3 scripts/build-project-packages.py --version "$(PACKAGE_VERSION)"

container-project-packages: container-image
	$(CONTAINER_RUN) python3 scripts/build-project-packages.py --version "$(PACKAGE_VERSION)"

container-apt-test: container-image
	$(CONTAINER_ENGINE) run --rm -v "$(CURDIR):/workspace:ro" $(BUILDER_IMAGE) python3 tests/apt-repository-test.py

host-check:
	./scripts/00-host-check.sh

bootstrap:
	./scripts/01-bootstrap.sh

package-check:
	./scripts/02-packages.sh --check-only

packages:
	./scripts/02-packages.sh

configure:
	./scripts/03-configure.sh

image:
	./scripts/04-image.sh

release:
	./scripts/05-release.sh

iso:
	./scripts/build.sh

container-image:
	$(CONTAINER_ENGINE) build -f Containerfile.build -t $(BUILDER_IMAGE) .

container-iso: container-image
	$(CONTAINER_RUN) ./scripts/build.sh

container-package-check: container-image
	$(CONTAINER_RUN) ./scripts/02-packages.sh --check-only

container-profile-check: container-image
	$(CONTAINER_RUN) ./tests/profile-packages.sh

container-update: container-image
	$(CONTAINER_RUN) ./scripts/update-image.sh

container-repack: container-image
	$(CONTAINER_RUN) ./scripts/repack-image.sh

# For boot-record-only edits after a successful full build. Never use this for
# package/overlay/kernel changes: it intentionally reuses the staged filesystem.
container-boot-repack: container-image
	$(CONTAINER_RUN) bash ./scripts/reassemble-boot.sh

container-shell: container-image
	$(CONTAINER_ENGINE) run --rm -it --privileged \
		-v "$(CURDIR):/workspace:Z" \
		-v "$(KILIMANJARO_BUILD_VOLUME):/workspace/build" \
		--entrypoint /bin/bash \
		$(BUILDER_IMAGE)

container-clean: container-image
	$(CONTAINER_RUN) ./scripts/clean.sh

iso-check: container-image
	$(CONTAINER_RUN) ./tests/iso-static.sh

smoke-test:
	./tests/smoke-boot.sh

smoke-usb:
	SMOKE_BOOT_MEDIA=usb ./tests/smoke-boot.sh

smoke-secureboot-usb:
	SMOKE_FIRMWARE=secureboot SMOKE_BOOT_MEDIA=usb ./tests/smoke-boot.sh

release-test:
	python3 ./tests/release-regression.py

test: validate iso-check smoke-test

vm:
	./scripts/run-vm.sh

vm-uefi:
	VM_FIRMWARE=uefi ./scripts/run-vm.sh

vm-secureboot:
	VM_FIRMWARE=secureboot ./scripts/run-vm.sh

clean:
	./scripts/clean.sh
