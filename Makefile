
.PHONY: default

VERSION = latest
REPO = mikeln

build-all: build-dbsetup build-inject build-app

build-inject: twissandra_inject_img

twissandra_inject_img: Dockerfile.inject
	@echo "building inject $(VERSION)"
	#
	# workaround until docker 1.5.0 -f
	cp Dockerfile.inject Dockerfile
	#docker build -f Dockerfile.inject -t twissandra_inj_img:$(VERSION) .
	docker build -t $(REPO)/twissandra_inj_img:$(VERSION) --rm=true --force-rm=true .
	#@touch twissandra_inject_img

build-dbsetup: twissandra_db_img

twissandra_db_img: Dockerfile.dbsetup
	@echo "building dbsetup $(VERSION)"
	#
	# workaround until docker 1.5.0 -f
	cp Dockerfile.dbsetup Dockerfile
	#docker build -f Dockerfile.inject -t twissandra_db_img:$(VERSION) .
	docker build -t $(REPO)/twissandra_db_img:$(VERSION) --rm=true --force-rm=true .
	#@touch twissandra_db_img

build-app: twissandra_app_img

twissandra_app_img: Dockerfile.app
	@echo "building dbsetup $(VERSION)"
	#
	# workaround until docker 1.5.0 -f
	cp Dockerfile.app Dockerfile
	#docker build -f Dockerfile.inject -t twissandra_app_img:$(VERSION) .
	docker build -t $(REPO)/twissandra_app_img:$(VERSION) --rm=true --force-rm=true .
	#@touch twissandra_app_img

