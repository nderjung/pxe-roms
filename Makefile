#
# PXE ROM Builder
#
# @author Alexander Jung <alex@nderjung.net>
#

# Program arguments
APP_NAME         ?= pxe-roms
DOCKER_REGISTRY  ?= nderjung.net
DOCKER_NAMESPACE ?= pxe-roms
TAG              ?= $(shell git symbolic-ref HEAD 2>/dev/null | cut -d"/" -f 3) 
DOCKER_CONTAINER ?= $(subst //,/,$(DOCKER_REGISTRY)/$(DOCKER_NAMESPACE):$(TAG))

# Directories
SRC_DIR          ?= $(CURDIR)
OUT_DIR          ?= $(SRC_DIR)/out
PXE_DIR          ?= $(SRC_DIR)/ipxe

# Tools
GIT              ?= git
DOCKER           ?= docker
DOCKER_FLAGS     ?=
DOCKER_TARGET    ?= build

# Distributions
UBUNTU           ?= trusty64-preseed trusty64-serial
UBUNTU           += xenial64-preseed xenial64-serial

# Build targets
ifndef TARGET
TARGET           := $(addprefix ubuntu/, $(UBUNTU))
endif

# Actual targets
.PHONY: all
all: $(OUT_DIR) $(PXE_DIR) $(TARGET)

$(OUT_DIR):
	mkdir -p $(OUT_DIR)

$(PXE_DIR):
ifeq ($(wildcard $(PXE_DIR)),)
	git clone git://git.ipxe.org/ipxe.git $(PXE_DIR)
endif

$(TARGET): $(OUT_DIR) $(PXE_DIR)
	$(MAKE) -C $(PXE_DIR)/src bin/undionly.kpxe \
		EMBED=$(SRC_DIR)/config/$@.cfg
	cp -f $(PXE_DIR)/src/bin/undionly.kpxe \
		$(OUT_DIR)/pxelinux.$(shell echo $@|sed -e "s/\//-/")

.PHONY: container
container: ## Build the container for building the roms
	$(DOCKER) build $(DOCKER_FLAGS) \
		--cache-from $(DOCKER_CONTAINER) \
		-f $(SRC_DIR)/Dockerfile \
		-t $(DOCKER_CONTAINER) \
		--target $(DOCKER_TARGET) \
		$(SRC_DIR)

.PHONY: clean
clean: ## Clean up build artifacts
	rm -Rfv $(OUT_DIR) $(PXE_DIR)

.PHONY: help
help: ## Show this help menu
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-10s\033[0m %s\n", $$1, $$2}'


