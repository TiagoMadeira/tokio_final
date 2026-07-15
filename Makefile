-include .make_env

# 2. Export them so they are visible to sub-shells and docker commands
export DOCKER_USERNAME
export DOCKERHUB_ACCESS_TOKEN
export DOCKER_EMAIL
export JWT_SECRET
export SONAR_HOST_URL
export SONAR_TOKEN


CURRENT_USER := $(shell whoami)
PIP_VERSION ?= 26.1.2

#########################################################################Initial Setup###################################################################

setup: install_basic_deps install_python install_node install_CI_dependencies install_docker install_minikube install_trivy add_hosts

install_basic_deps:
	@echo "Updating packages and installing basic dependencies..."
	sudo apt-get update -y
	sudo apt-get install -y curl software-properties-common apt-transport-https ca-certificates gnupg lsb-release

install_python:
	sudo add-apt-repository ppa:deadsnakes/ppa -y
	sudo apt update
	sudo apt install python3.12 python3.12-venv python3.12-dev -y

install_node:
	curl -fsSL https://deb.nodesource.com/setup_22.x | sudo -E bash -
	sudo apt-get install -y nodejs

install_docker:
	@if [ -x /usr/bin/docker ]; then \
		echo "Docker is already installed. Skipping installation steps."; \
	else \
		echo "Docker not found. Installing via standard apt-get repository..."; \
		sudo apt-get update -y; \
		sudo apt-get install -y docker.io docker-buildx; \
		echo "Ensuring user $(CURRENT_USER) is in docker group..."; \
		sudo usermod -aG docker $(CURRENT_USER); \
	fi
	sudo systemctl enable docker
	sudo systemctl start docker

install_minikube:
	@if command -v minikube >/dev/null 2>&1; then \
		echo "Minikube is already installed. Skipping installation steps."; \
	else \
		echo "Minikube not found. Fetching and installing Debian package..."; \
		curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube_latest_amd64.deb; \
		sudo apt-get install -y ./minikube_latest_amd64.deb; \
		rm minikube_latest_amd64.deb; \
	fi

install_CI_dependencies:
	@echo installing CI dependencies 
	sudo apt-get update
	sudo apt-get install -y libnspr4 libnss3 libgbm1 libasound2 unzip

install_trivy:
	sudo apt-get install wget gnupg
	wget -qO - https://aquasecurity.github.io/trivy-repo/deb/public.key | gpg --dearmor | sudo tee /usr/share/keyrings/trivy.gpg > /dev/null
	echo "deb [signed-by=/usr/share/keyrings/trivy.gpg] https://aquasecurity.github.io/trivy-repo/deb generic main" | sudo tee -a /etc/apt/sources.list.d/trivy.list
	sudo apt-get update
	sudo apt-get install trivy

add_hosts:
	@echo the following domains will be added to your host file
	@echo 127.0.0.1 posts.com //this is the production server
	@echo 127.0.0.1 tokio.observability.jaeger.com
	@echo 127.0.0.1 frontend.development.posts.com
	@echo 127.0.0.1 frontend.staging.posts.com
	@sudo bash -c '\
	for domain in "posts.com" "tokio.observability.jaeger.com" "frontend.development.posts.com" frontend.staging.posts.com; do \
		grep -qF "127.0.0.1 $$domain" /etc/hosts || echo "127.0.0.1 $$domain" >> /etc/hosts; \
	done \
	'


#########################################################################Development######################################################################

start_development: start_minikube start_jaeger_server build_images start_development_server expose_ingress_controller

stop_development: 
	minikube kubectl -- delete namespace development

build_images:
	@echo "Building images directly inside Minikube..."
	@eval $$(minikube -p minikube docker-env) && \
	docker build --no-cache --build-arg APP_ENV=dev -t tokio-rest-service:latest rest_service && \
	docker build --no-cache --build-arg APP_ENV=dev -t tokio-post-service:latest post_service && \
	docker build --no-cache --build-arg APP_ENV=dev -t tokio-auth-service:latest auth_service && \
	docker build --no-cache -t frontend:latest frontend

start_development_server:
	@echo create development namespace
	minikube kubectl -- create namespace development
	@echo appling pods secrets
	minikube kubectl -- create secret tls backend-tls-secret --namespace development --cert=backend-tls.crt --key=backend-tls.key
	minikube kubectl -- create secret tls frontend-development-posts-com-tls --namespace development --cert=dev-tls.crt --key=dev-tls.key
	minikube kubectl -- apply -f k8s-configs/development/secrets/auth-service-secrets.yaml
	@echo applying config files
	minikube kubectl -- apply -f k8s-configs/development/configmaps/frontend-configmap.yaml
	minikube kubectl -- apply -f k8s-configs/development/configmaps/auth-service-configmap.yaml
	minikube kubectl -- apply -f k8s-configs/development/configmaps/post-service-configmap.yaml
	minikube kubectl -- apply -f k8s-configs/development/configmaps/rest-service-configmap.yaml
	@echo applying deployments
	minikube kubectl -- apply -f k8s-configs/development/manifests/frontend-deployment.yaml
	minikube kubectl -- apply -f k8s-configs/development/manifests/rest-service-deployment.yaml
	minikube kubectl -- apply -f k8s-configs/development/manifests/post-service-deployment.yaml
	minikube kubectl -- apply -f k8s-configs/development/manifests/auth-service-deployment.yaml
	@echo applying ingresses
	minikube kubectl -- apply -f k8s-configs/development/ingress/frontend-posts-ingress.yaml

rollout_development:
	@echo Building images this might take a few minutes when runing for the first time
	@echo "Building images directly inside Minikube..."
	@eval $$(minikube -p minikube docker-env) && \
	docker build --build-arg APP_ENV=dev -t tokio-rest-service:latest rest_service && \
	docker build --build-arg APP_ENV=dev -t tokio-post-service:latest post_service && \
	docker build --build-arg APP_ENV=dev -t tokio-auth-service:latest auth_service && \
	docker build -t frontend:latest frontend
	@echo appling pods secrets
	minikube kubectl -- apply -f k8s-configs/development/secrets/auth-service-secrets.yaml
	@echo applying config files
	minikube kubectl -- apply -f k8s-configs/development/configmaps/frontend-configmap.yaml
	minikube kubectl -- apply -f k8s-configs/development/configmaps/auth-service-configmap.yaml
	minikube kubectl -- apply -f k8s-configs/development/configmaps/post-service-configmap.yaml
	minikube kubectl -- apply -f k8s-configs/development/configmaps/rest-service-configmap.yaml
	@echo rollout deployments
	minikube kubectl -- rollout restart deployment frontend-deployment -n development
	minikube kubectl -- rollout restart deployment auth-service-deployment -n development
	minikube kubectl -- rollout restart deployment post-service-deployment -n development
	minikube kubectl -- rollout restart deployment rest-service-deployment -n development

###########################################################################Build##########################################################################

launch_build:
	@echo "Logging into Docker Hub..."
	@docker login -u "$(DOCKER_USERNAME)" --password "$(DOCKERHUB_ACCESS_TOKEN)"
	
	@echo "Building and pushing images to private Docker Hub..."
	docker build --no-cache --build-arg APP_ENV=prd -t $(DOCKER_USERNAME)/tokio-rest-service:latest rest_service
	docker push $(DOCKER_USERNAME)/tokio-rest-service:latest
	
	docker build --no-cache --build-arg APP_ENV=prd -t $(DOCKER_USERNAME)/tokio-post-service:latest post_service
	docker push $(DOCKER_USERNAME)/tokio-post-service:latest
	
	docker build --no-cache --build-arg APP_ENV=prd -t $(DOCKER_USERNAME)/tokio-auth-service:latest auth_service
	docker push $(DOCKER_USERNAME)/tokio-auth-service:latest
	
	docker build --no-cache -t $(DOCKER_USERNAME)/tokio-frontend:latest frontend
	docker push $(DOCKER_USERNAME)/tokio-frontend:latest



##########################################################################Staging#########################################################################

launch_staging:
	@echo "Starting staging pipeline..."
	@# If interrupted by Ctrl+C, run cleanup and exit immediately with status 130
	@trap 'echo "\nInterrupted! Cleaning up..."; $(MAKE) clear_staging; exit 130' INT; \
	trap '$(MAKE) clear_staging' EXIT TERM; \
	$(MAKE) start_and_prepare_staging; \
	$(MAKE) run_tests
	
#$(MAKE) sonar_scan
#$(MAKE) run_vulnerability_tests; \
stop_staging: 
	minikube kubectl -- delete namespace staging

start_and_prepare_staging: start_minikube start_jaeger_server start_staging_environment wait_for_staging_pods prepare_staging_for_integration_testing expose_ingress_controller

wait_for_staging_pods:
	@echo "waiting for staging pods to be up and running"
	minikube kubectl -- wait --namespace staging --for=condition=ready pod --all --timeout=500s

prepare_staging_for_integration_testing:
	@echo "preparing staging for integration testing"
	minikube kubectl -- port-forward service/rest-internal-service 8000:80 -n staging > /dev/null 2>&1 &
	minikube kubectl -- port-forward service/frontend-internal-service 3000:80 -n staging > /dev/null 2>&1 &
	sleep 5 # Wait for the tunnel to initialize

start_staging_environment:
	@echo create staging namespace
	minikube kubectl -- create namespace staging
	@echo appling pods secrets
	@minikube kubectl -- create secret docker-registry regcred --namespace staging --docker-server=https://index.docker.io/v1/ --docker-username=$(DOCKER_USERNAME) --docker-password=$(DOCKERHUB_ACCESS_TOKEN) --docker-email=$(DOCKER_EMAIL)
	minikube kubectl -- create secret tls backend-tls-secret --namespace staging --cert=staging-backend-tls.crt --key=staging-backend-tls.key
	minikube kubectl -- create secret tls frontend-staging-posts-com-tls --namespace staging --cert=staging-frontend-tls.crt --key=staging-frontend-tls.key
	minikube kubectl -- apply -f k8s-configs/staging/secrets/auth-service-secrets.yaml
	@echo applying config files
	minikube kubectl -- apply -f k8s-configs/staging/configmaps/frontend-configmap.yaml
	minikube kubectl -- apply -f k8s-configs/staging/configmaps/auth-service-configmap.yaml
	minikube kubectl -- apply -f k8s-configs/staging/configmaps/post-service-configmap.yaml
	minikube kubectl -- apply -f k8s-configs/staging/configmaps/rest-service-configmap.yaml
	@echo applying deployments
	minikube kubectl -- apply -f k8s-configs/staging/manifests/frontend-deployment.yaml
	minikube kubectl -- apply -f k8s-configs/staging/manifests/rest-service-deployment.yaml
	minikube kubectl -- apply -f k8s-configs/staging/manifests/post-service-deployment.yaml
	minikube kubectl -- apply -f k8s-configs/staging/manifests/auth-service-deployment.yaml
	@echo applying ingresses
	minikube kubectl -- apply -f k8s-configs/staging/ingress/frontend-posts-ingress.yaml

rollout_staging:
	@echo applying config files
	minikube kubectl -- apply -f k8s-configs/staging/configmaps/frontend-configmap.yaml
	minikube kubectl -- apply -f k8s-configs/staging/configmaps/auth-service-configmap.yaml
	minikube kubectl -- apply -f k8s-configs/staging/configmaps/post-service-configmap.yaml
	minikube kubectl -- apply -f k8s-configs/staging/configmaps/rest-service-configmap.yaml
	@echo rollout deployments
	minikube kubectl -- rollout restart deployment frontend-deployment -n staging
	minikube kubectl -- rollout restart deployment auth-service-deployment -n staging
	minikube kubectl -- rollout restart deployment post-service-deployment -n staging
	minikube kubectl -- rollout restart deployment rest-service-deployment -n staging

run_vulnerability_tests: run_pip_audit run_trivy_scans

run_pip_audit: audit_rest_service audit_auth_service audit_post_service 

run_trivy_scans: trivy_scan_rest_service trivy_scan_auth_service trivy_scan_post_service trivy_scan_frontend_service trivy_scan_k8s_configs_service

audit_rest_service:
	@stty sane || true
	@tput init || true
	@echo "Starting security compliance audit for Rest Service..."
	@cd rest_service && \
	python3 -m venv .venv && \
	. .venv/bin/activate && \
	python3 -m pip install --upgrade pip==$(PIP_VERSION) > /dev/null && \
	pip install pip-audit && \
	pip-audit --progress-spinner off -r requirements-stg.txt || true
	@stty sane

audit_auth_service:
	@echo "Starting security compliance audit for Auth Service..."
	@cd auth_service && \
	python3 -m venv .venv && \
	. .venv/bin/activate && \
	python3 -m pip install --upgrade pip==$(PIP_VERSION) > /dev/null && \
	pip install pip-audit && \
	pip-audit --progress-spinner off -r requirements-stg.txt || true
	@stty sane

audit_post_service:
	@echo "Starting security compliance audit for Post Service..."
	@cd post_service && \
	python3 -m venv .venv && \
	. .venv/bin/activate && \
	python3 -m pip install --upgrade pip==$(PIP_VERSION) > /dev/null && \
	pip install pip-audit && \
	pip-audit --progress-spinner off -r requirements-stg.txt || true
	@stty sane

trivy_scan_rest_service:
	@echo "Starting trivy scan for rest service..."
	trivy fs --config trivy_conf/trivy.yaml --format table rest_service

trivy_scan_auth_service:
	@echo "Starting trivy scan for auth service..."
	trivy fs --config trivy_conf/trivy.yaml --format table auth_service

trivy_scan_post_service:
	@echo "Starting trivy scan for post service..."
	trivy fs --config trivy_conf/trivy.yaml --format table post_service

trivy_scan_frontend_service:
	@echo "Starting trivy scan for frotend service..."
	trivy fs --config trivy_conf/trivy.yaml --format table frontend

trivy_scan_k8s_configs_service:
	@echo "Starting trivy scan for k8s-configs service..."
	trivy fs --config trivy_conf/trivy.yaml --format table k8s-configs

#rest_service_tests post_service_tests auth_service_tests
run_tests:  frontend_tests

rest_service_tests:
	python3 -m venv "rest_service/.venv"
	rest_service/.venv/bin/pip install -r rest_service/requirements-stg.txt
	PYTHONPATH=rest_service ENABLE_MONOTORING=False rest_service/.venv/bin/pytest rest_service/tests/ --cov=rest_service/app -W ignore --cov-report=xml:rest_service/coverage.xml --cov-config=.coveragerc

post_service_tests:
	python3 -m venv "post_service/.venv"
	post_service/.venv/bin/pip install -r post_service/requirements-stg.txt
	PYTHONPATH=post_service ENABLE_MONOTORING=False post_service/.venv/bin/pytest post_service/tests/ --cov=post_service/app -W ignore --cov-report=xml:post_service/coverage.xml --cov-config=.coveragerc

auth_service_tests:
	python3 -m venv "auth_service/.venv"
	auth_service/.venv/bin/pip install -r auth_service/requirements-stg.txt
	PYTHONPATH=auth_service ENABLE_MONOTORING=False SECRET_KEY=$(JWT_SECRET) auth_service/.venv/bin/pytest auth_service/tests/ -W ignore --cov=auth_service/app --cov-report=xml:auth_service/coverage.xml --cov-config=.coveragerc

frontend_tests:
	@stty sane || true
	@tput init || true
	cd frontend && \
	npm ci && \
	npx playwright install chromium && \
	npm run test -- --coverage --watch=false && \
	@echo "starting E2E tests" && \
	npx playwright test

sonar_scan:
	@echo "Running local SonarQube scan via temporary Docker container..."
	@docker run --rm \
		-e SONAR_TOKEN=$(SONAR_TOKEN) \
		-e SONAR_HOST_URL=$(SONAR_HOST_URL) \
		-v "$(shell pwd):/usr/src" \
		sonarsource/sonar-scanner-cli \
		-Dsonar.projectBaseDir=/usr/src

clear_staging:
	#Kill background port-forward processes
	-pkill -f "port-forward service/rest-internal-service"
	-pkill -f "port-forward service/frontend-internal-service"
	#Delete staging namespace
	minikube kubectl -- delete namespace staging

#########################################################################Production#######################################################################

deploy_production: start_minikube start_jaeger_server start_or_update_production wait_for_production_pods

stop_production: 
	minikube kubectl -- delete namespace production

start_or_update_production:
	@echo "Checking for production namespace..."
	@if ! minikube kubectl -- get namespace production >/dev/null 2>&1; then \
		$(MAKE) start_production_environment; \
	else \
		$(MAKE) rollout_production; \
	fi

wait_for_production_pods:
	@echo "waiting for production pods to be up and running"
	minikube kubectl -- wait --namespace production --for=condition=ready pod --all --timeout=500s


start_production_environment:
	@echo create production namespace
	minikube kubectl -- create namespace production
	@echo creating docker registry secret
	@minikube kubectl -- create secret docker-registry regcred --namespace production --docker-server=https://index.docker.io/v1/ --docker-username=$(DOCKER_USERNAME) --docker-password=$(DOCKERHUB_ACCESS_TOKEN) --docker-email=$(DOCKER_EMAIL)
	@echo appling pods secrets
	minikube kubectl -- apply -f k8s-configs/production/secrets/auth-service-secrets.yaml
	minikube kubectl -- create secret tls backend-tls-secret --namespace production --cert=prod-backend-tls.crt --key=prod-backend-tls.key
	minikube kubectl -- create secret tls frontend-production-posts-com-tls --namespace production --cert=prod-frontend-tls.crt --key=prod-frontend-tls.key
	@echo applying config files
	minikube kubectl -- apply -f k8s-configs/production/configmaps/frontend-configmap.yaml
	minikube kubectl -- apply -f k8s-configs/production/configmaps/auth-service-configmap.yaml
	minikube kubectl -- apply -f k8s-configs/production/configmaps/post-service-configmap.yaml
	minikube kubectl -- apply -f k8s-configs/production/configmaps/rest-service-configmap.yaml
	@echo applying deployments
	minikube kubectl -- apply -f k8s-configs/production/manifests/frontend-deployment.yaml
	minikube kubectl -- apply -f k8s-configs/production/manifests/rest-service-deployment.yaml
	minikube kubectl -- apply -f k8s-configs/production/manifests/post-service-deployment.yaml
	minikube kubectl -- apply -f k8s-configs/production/manifests/auth-service-deployment.yaml
	@echo applying ingresses
	minikube kubectl -- apply -f k8s-configs/production/ingress/frontend-posts-ingress.yaml

rollout_production:
	@echo applying config files
	minikube kubectl -- apply -f k8s-configs/production/configmaps/frontend-configmap.yaml
	minikube kubectl -- apply -f k8s-configs/production/configmaps/auth-service-configmap.yaml
	minikube kubectl -- apply -f k8s-configs/production/configmaps/post-service-configmap.yaml
	minikube kubectl -- apply -f k8s-configs/production/configmaps/rest-service-configmap.yaml
	@echo rollout deployments
	minikube kubectl -- rollout restart deployment frontend-deployment -n production
	minikube kubectl -- rollout restart deployment auth-service-deployment -n production
	minikube kubectl -- rollout restart deployment post-service-deployment -n production
	minikube kubectl -- rollout restart deployment rest-service-deployment -n production

#######################################################################Oberservability#######################################################################

start_jaeger_server:
	@echo "Checking for observability namespace..."
	@if ! minikube kubectl -- get namespace observability >/dev/null 2>&1; then \
		echo "Creating observability namespace..."; \
		minikube kubectl -- create namespace observability; \
	fi
	@echo "Applying configurations (idempotent)..."
	minikube kubectl -- apply -f k8s-configs/observability/configmaps/jaeger-configmap.yaml
	minikube kubectl -- apply -f k8s-configs/observability/configmaps/jaeger-ui-config.yaml
	minikube kubectl -- apply -f k8s-configs/observability/manifests/jaeger-deployment.yaml
	minikube kubectl -- apply -f k8s-configs/observability/ingress/jaeger-ingress.yaml


################################################################################Utils################################################################################

start_minikube:
	@echo "Checking Minikube status..."
	@if minikube status >/dev/null 2>&1; then \
		echo "Minikube is already running."; \
	else \
		echo "Starting Minikube..."; \
		minikube start --driver=docker; \
		echo "Enabling Ingress addon..."; \
		minikube addons enable ingress; \
	fi
	@echo "Waiting for nginx ingress readiness..."
	minikube kubectl -- wait --namespace ingress-nginx --for=condition=ready pod --selector=app.kubernetes.io/component=controller --timeout=120s


expose_ingress_controller:
	@echo "Checking if Ingress Controller port-forward is already active..."
	@if sudo lsof -i :80 -i :443 >/dev/null 2>&1; then \
		echo "Ports 80/443 are already occupied. Skipping port-forward."; \
	else \
		echo "Ports are free. Exposing Ingress Controller to all interfaces..."; \
		sudo -E minikube kubectl -- port-forward service/ingress-nginx-controller -n ingress-nginx 80:80 443:443 >/dev/null 2>&1 & \
		sleep 5 # Wait for the tunnel to initialize \
	fi

clean:
	@echo "Killing background port-forward processes..."
	-pkill -f "port-forward service/rest-internal-service"
	-pkill -f "port-forward service/frontend-internal-service"
	-sudo pkill -f "port-forward service/ingress-nginx-controller"
	@echo "Deleting minikube cluster and profile..."
	minikube delete --all --purge
	@echo "Removing locally built Docker images..."
	docker rmi $(DOCKER_USERNAME)/tokio-rest-service:latest || true
	docker rmi $(DOCKER_USERNAME)/tokio-post-service:latest || true
	docker rmi $(DOCKER_USERNAME)/tokio-auth-service:latest || true
	docker rmi $(DOCKER_USERNAME)/tokio-frontend:latest || true
	@echo "Cleaning up build caches..."
	docker builder prune -f
	@echo "Removing SonarQube scanner image..."
	docker rmi sonarsource/sonar-scanner-cli:latest || true
	@echo "Remove added domains from hosts file"
	sudo sed -i.bak -E '/127\.0\.0\.1 +(posts\.com|tokio\.observability\.jaeger\.com|frontend\.development\.posts\.com|frontend\.staging\.posts\.com)/d' /etc/hosts

fetch-sonar:
	@python get-sonar-summary.py
