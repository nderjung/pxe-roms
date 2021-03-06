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
PRESEED_URL      ?=

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
UBUNTU           += bionic64-preseed bionic64-serial
COREOS           ?= stable beta alpha
XCP_NG           ?= 7.5 7.6 8.0 latest

# Custom iPXE scripts
CUSTOM           ?= $(shell find config/custom -type f -name '*.cfg')

# Build targets
ifndef TARGET
TARGET           := $(addprefix ubuntu/, $(UBUNTU))
TARGET           += $(addprefix coreos/, $(COREOS))
TARGET           += $(addprefix xcp-ng/, $(XCP_NG))

# Custom iPXE scripts
TARGET           += $(subst .cfg,, $(subst config/,,$(CUSTOM)))
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
ifneq ($(PRESEED_URL),)
	$(eval EMBED_CFG := $(shell mktemp))
	cp $(SRC_DIR)/config/$@.cfg $(EMBED_CFG)
	sed -i 's|$${preseed-url}|$(PRESEED_URL)|' $(EMBED_CFG)
else
	$(eval EMBED_CFG := $(SRC_DIR)/config/$@.cfg)
endif
	$(MAKE) -C $(PXE_DIR)/src bin/undionly.kpxe EMBED=$(EMBED_CFG)
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