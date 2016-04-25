
.PHONY: default clean-inject clean-dbsetup clean-app
#
# This makefile assumes that docker is installed
#
# 2/20/2015 mln
#
VERSION := b0slim
#
# do some repo evals... want everyone to use their own, unless building for the team
#
DEFAULT_REPO := "samsung-cnct"
DOCKER_REPO ?= $(DEFAULT_REPO)
REPO := $(DOCKER_REPO)
#
#
DOCKER_IMAGE := twissandra_dev_img

repo-warning:
	@if  [ $(DOCKER_REPO) =  $(DEFAULT_REPO) ]; then \
        echo "+++++++++++++++++++++++++++++++++++++++++++++++++++"; \
        echo "  You have not changed DOCKER_REPO from: $(DOCKER_REPO)"; \
        echo "  You MUST set DOCKER_REPO in your environment"; \
        echo "  or directly in this Makefile unless you are"; \
        echo "  building for the group"; \
        echo "+++++++++++++++++++++++++++++++++++++++++++++++++++"; \
        false; \
    else \
        echo "+++++++++++++++++++++++++++++++++++++++++++++++++++"; \
        echo "  Your DOCKER_REPO is set to: $(DOCKER_REPO)"; \
        echo "  Please execute 'make all' to build"; \
        echo "+++++++++++++++++++++++++++++++++++++++++++++++++++"; \
    fi

all: build-all

build-all: build-app

build-app: $(DOCKER_IMAGE)

$(DOCKER_IMAGE): Dockerfile.dev.slim init.sh dev.sh
	@echo "building app $(VERSION)"
	#
	# workaround until docker 1.5.0 -f
	cp Dockerfile.dev.slim Dockerfile
	#docker build -f Dockerfile.dev.slim -t $(REPO)/twissandra_app_img:$(VERSION) .
	docker build -t $(REPO)/$(DOCKER_IMAGE):$(VERSION) --rm=true --force-rm=true .
	@touch $@
	@docker images $(REPO)/$(DOCKER_IMAGE)

clean: clean-app
	-rm -f Dockerfile

clean-app:
	-docker rmi $(REPO)/$(DOCKER_IMAGE):$(VERSION)
	-rm -f $(DOCKER_IMAGE)

