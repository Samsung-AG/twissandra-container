
.PHONY: default clean-inject clean-dbsetup clean-app
#
# This makefile assumes that docker is installed
#
# 2/20/2015 mln
#
VERSION := a0
#
# do some repo evals... want everyone to use their own, unless building for the team
#
DEFAULT_REPO := "samsungAG"
DOCKER_REPO ?= $(DEFAULT_REPO)
REPO := $(DOCKER_REPO)
#
#
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

REPO = mikeln

all: build-all

build-all: build-dbsetup build-inject build-app

build-inject: twissandra_inj_img

twissandra_inj_img: Dockerfile.inject twissandra
	@echo "building inject $(VERSION)"
	#
	# workaround until docker 1.5.0 -f
	cp Dockerfile.inject Dockerfile
	#docker build -f Dockerfile.inject -t $(REPO)/twissandra_inj_img:$(VERSION) .
	docker build -t $(REPO)/twissandra_inj_img:$(VERSION) --rm=true --force-rm=true .
	@touch $@
	@docker images $(REPO)/twissandra_inj_img

build-dbsetup: twissandra_db_img

twissandra_db_img: Dockerfile.dbsetup
	@echo "building dbsetup $(VERSION)"
	#
	# workaround until docker 1.5.0 -f
	cp Dockerfile.dbsetup Dockerfile
	#docker build -f Dockerfile.inject -t $(REPO)/twissandra_db_img:$(VERSION) .
	docker build -t $(REPO)/twissandra_db_img:$(VERSION) --rm=true --force-rm=true .
	@touch $@
	@docker images $(REPO)/twissandra_db_img

build-app: twissandra_app_img

twissandra_app_img: Dockerfile.app
	@echo "building app $(VERSION)"
	#
	# workaround until docker 1.5.0 -f
	cp Dockerfile.app Dockerfile
	#docker build -f Dockerfile.inject -t $(REPO)/twissandra_app_img:$(VERSION) .
	docker build -t $(REPO)/twissandra_app_img:$(VERSION) --rm=true --force-rm=true .
	@touch $@
	@docker images $(REPO)/twissandra_app_img

build-dev: twissandra_dev_img

twissandra_dev_img: Dockerfile.dev ssh build.sh
	@echo "building dev $(VERSION)"
	#
	# workaround until docker 1.5.0 -f
	cp Dockerfile.dev Dockerfile
	#docker build -f Dockerfile.dev -t $(REPO)/twissandra_dev_img:$(VERSION) .
	docker build -t $(REPO)/twissandra_dev_img:$(VERSION) --rm=true --force-rm=true .
	@touch $@
	@docker images $(REPO)/twissandra_dev_img

build-shell: twissandra_shell_img

twissandra_shell_img: Dockerfile.app
	@echo "building shell $(VERSION)"
	#
	# workaround until docker 1.5.0 -f
	cp Dockerfile.shell Dockerfile
	#docker build -f Dockerfile.shell -t $(REPO)/twissandra_shell_img:$(VERSION) .
	docker build -t $(REPO)/twissandra_shell_img:$(VERSION) --rm=true --force-rm=true .
	@touch $@
	@docker images $(REPO)/twissandra_shell_img



clean: clean-dbsetup clean-inject clean-app
	-rm -f Dockerfile

clean-inject: 
	-docker rmi  $(REPO)/twissandra_inj_img:$(VERSION)
	-rm -f twissandra_inj_img

clean-dbsetup:
	-docker rmi $(REPO)/twissandra_db_img:$(VERSION)
	-rm -f twissandra_db_img

clean-app:
	-docker rmi $(REPO)/twissandra_app_img:$(VERSION)
	-rm -f twissandra_app_img

clean-dev:
	-docker rmi $(REPO)/twissandra_dev_img:$(VERSION)
	-rm -f twissandra_dev_img

clean-shell:
	-docker rmi $(REPO)/twissandra_shell_img:$(VERSION)
	-rm -f twissandra_shell_img
