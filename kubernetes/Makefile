
.PHONY: all clean-app
#
# This makefile assumes that docker is installed
#
# 2/20/2015 mln
#
VERSION = v1
REPO = mikeln

all: build-all

build-all: build-app

build-app: twissandra_img

twissandra_img: Dockerfile.app init.sh
	@echo "building app $(VERSION)"
	#
	# workaround until docker 1.5.0 -f
	cp Dockerfile.app Dockerfile
	#docker build -f Dockerfile.inject -t $(REPO)/twissandra_img:$(VERSION) .
	docker build -t $(REPO)/twissandra_img:$(VERSION) --rm=true --force-rm=true .
	@touch twissandra_img
	@docker images $(REPO)/twissandra_img

clean: clean-app
	-rm -f Dockerfile

clean-app:
	-docker rmi $(REPO)/twissandra_img:$(VERSION)
	-rm -f twissandra_img

