PIP_VERSION ?= 26.1.2

#########################################################################Initial Setup####################################################################

init_cluster: start_minikube start_jaeger_server expose_ingress_controller

start_minikube:
	@echo "Checking Minikube status..."
	@if minikube status >/dev/null 2>&1; then \
		echo "Minikube is already running."; \
	else \
		echo "Starting Minikube..."; \
		minikube start --driver=docker; \
		echo "Enabling Ingress addon..."; \
		minikube addons enable ingress; \
		echo "Enabling Registry addon..."; \
		minikube addons enable registry; \
	fi
	@echo "Waiting for nginx ingress readiness..."
	minikube kubectl -- wait --namespace ingress-nginx --for=condition=ready pod --selector=app.kubernetes.io/component=controller --timeout=120s
	@echo "Checking registry port-forward..."
	@( \
		if ! lsof -i :32780 >/dev/null 2>&1; then \
			echo "Starting background port-forward for local registry (localhost:32780)..."; \
			minikube kubectl -- port-forward --namespace kube-system service/registry 32780:80 > /dev/null 2>&1 & \
		else \
			echo "Registry port 32780 is already mapped."; \
		fi \
	)

start_jaeger_server:
	@echo "Checking for observability namespace..."
	@if ! minikube kubectl -- get namespace observability >/dev/null 2>&1; then \
		echo "Creating observability namespace..."; \
		minikube kubectl -- create namespace observability; \
		echo "Creating observability tls secret..."; \
		minikube kubectl -- create secret tls observability-tls-secret --namespace observability --cert=blog_posts_app/tls/certs/observability-tls.crt --key=blog_posts_app/tls/keys/observability-tls.key;\
	fi
	@echo "Applying configurations (idempotent)..."
	minikube kubectl -- apply -f blog_posts_app/k8s-configs/observability/configmaps/jaeger-configmap.yaml
	minikube kubectl -- apply -f blog_posts_app/k8s-configs/observability/configmaps/jaeger-ui-config.yaml
	minikube kubectl -- apply -f blog_posts_app/k8s-configs/observability/manifests/jaeger-deployment.yaml
	minikube kubectl -- apply -f blog_posts_app/k8s-configs/observability/ingress/jaeger-ingress.yaml

expose_ingress_controller:
	@echo "Checking if Ingress Controller port-forward is already active..."
	@( \
		if lsof -i :8080 -i :8443 >/dev/null 2>&1; then \
			echo "Ports 8080/8443 are already occupied. Skipping port-forward."; \
		else \
			echo "Ports are free. Exposing Ingress Controller to all interfaces..."; \
			minikube kubectl -- port-forward service/ingress-nginx-controller -n ingress-nginx 8080:80 8443:443 >/dev/null 2>&1 & \
			sleep 5; \
		fi \
	)

#########################################################################Development######################################################################

start_development_server:
	@echo "Checking for development namespace..."
	@if ! minikube kubectl -- get namespace development >/dev/null 2>&1; then \
		$(MAKE) apply_development_server; \
	else \
		$(MAKE) rollout_development; \
	fi

stop_development: 
	minikube kubectl -- delete namespace development

build_development_images:
	@echo "Building development images and pushing to Minikube Registry..."

	docker build --no-cache --build-arg APP_ENV=dev -t localhost:32780/tokio-rest-service:dev blog_posts_app/rest_service
	docker push localhost:32780/tokio-rest-service:dev
	
	docker build --no-cache --build-arg APP_ENV=dev -t localhost:32780/tokio-post-service:dev blog_posts_app/post_service
	docker push localhost:32780/tokio-post-service:dev
	
	docker build --no-cache --build-arg APP_ENV=dev -t localhost:32780/tokio-auth-service:dev blog_posts_app/auth_service
	docker push localhost:32780/tokio-auth-service:dev
	
	docker build --no-cache --build-arg NODE_ENV=development -t localhost:32780/tokio-frontend:dev blog_posts_app/frontend
	docker push localhost:32780/tokio-frontend:dev

apply_development_server:
	@echo create development namespace
	minikube kubectl -- create namespace development
	@echo appling pods secrets
	minikube kubectl -- create secret tls backend-tls-secret --namespace development --cert=blog_posts_app/tls/certs/dev-backend-tls.crt --key=blog_posts_app/tls/keys/dev-backend-tls.key
	minikube kubectl -- create secret tls frontend-development-posts-com-tls --namespace development --cert=blog_posts_app/tls/certs/dev-frontend-tls.crt --key=blog_posts_app/tls/keys/dev-frontend-tls.key
	minikube kubectl -- apply -f blog_posts_app/k8s-configs/development/secrets/auth-service-secrets.yaml
	@echo applying config files
	minikube kubectl -- apply -f blog_posts_app/k8s-configs/development/configmaps/frontend-configmap.yaml
	minikube kubectl -- apply -f blog_posts_app/k8s-configs/development/configmaps/auth-service-configmap.yaml
	minikube kubectl -- apply -f blog_posts_app/k8s-configs/development/configmaps/post-service-configmap.yaml
	minikube kubectl -- apply -f blog_posts_app/k8s-configs/development/configmaps/rest-service-configmap.yaml
	@echo applying deployments
	minikube kubectl -- apply -f blog_posts_app/k8s-configs/development/manifests/frontend-deployment.yaml
	minikube kubectl -- apply -f blog_posts_app/k8s-configs/development/manifests/rest-service-deployment.yaml
	minikube kubectl -- apply -f blog_posts_app/k8s-configs/development/manifests/post-service-deployment.yaml
	minikube kubectl -- apply -f blog_posts_app/k8s-configs/development/manifests/auth-service-deployment.yaml
	@echo applying ingresses
	minikube kubectl -- apply -f blog_posts_app/k8s-configs/development/ingress/frontend-posts-ingress.yaml

rollout_development:
	@echo appling pods secrets
	minikube kubectl -- apply -f blog_posts_app/k8s-configs/development/secrets/auth-service-secrets.yaml
	@echo applying config files
	minikube kubectl -- apply -f blog_posts_app/k8s-configs/development/configmaps/frontend-configmap.yaml
	minikube kubectl -- apply -f blog_posts_app/k8s-configs/development/configmaps/auth-service-configmap.yaml
	minikube kubectl -- apply -f blog_posts_app/k8s-configs/development/configmaps/post-service-configmap.yaml
	minikube kubectl -- apply -f blog_posts_app/k8s-configs/development/configmaps/rest-service-configmap.yaml
	@echo rollout deployments
	minikube kubectl -- rollout restart deployment frontend-deployment -n development
	minikube kubectl -- rollout restart deployment auth-service-deployment -n development
	minikube kubectl -- rollout restart deployment post-service-deployment -n development
	minikube kubectl -- rollout restart deployment rest-service-deployment -n development

###########################################################################Build##########################################################################

launch_build:
	@echo "Verifying local registry port-forward..."
	@lsof -i :32780 >/dev/null 2>&1 || (echo "Error: Run 'make start_minikube' first to open port 32780." && exit 1)

	@echo "Building and pushing images to Minikube Registry..."
	
	docker build --no-cache --build-arg APP_ENV=prd -t localhost:32780/tokio-rest-service:latest blog_posts_app/rest_service
	docker push localhost:32780/tokio-rest-service:latest
	
	docker build --no-cache --build-arg APP_ENV=prd -t localhost:32780/tokio-post-service:latest blog_posts_app/post_service
	docker push localhost:32780/tokio-post-service:latest
	
	docker build --no-cache --build-arg APP_ENV=prd -t localhost:32780/tokio-auth-service:latest blog_posts_app/auth_service
	docker push localhost:32780/tokio-auth-service:latest
	
	docker build --no-cache -t localhost:32780/tokio-frontend:latest blog_posts_app/frontend
	docker push localhost:32780/tokio-frontend:latest


##########################################################################Staging#########################################################################

launch_staging:
	@echo "Starting staging pipeline..."
	@# If interrupted by Ctrl+C, run cleanup and exit immediately with status 130
	@trap 'echo "\nInterrupted! Cleaning up..."; $(MAKE) clear_staging; exit 130' INT; \
	trap '$(MAKE) clear_staging' EXIT TERM; \
	$(MAKE) start_and_prepare_staging; \
	$(MAKE) run_vulnerability_tests; \
	$(MAKE) run_tests; \
	$(MAKE) sonar_scan

stop_staging: 
	minikube kubectl -- delete namespace staging

start_and_prepare_staging: start_staging_environment wait_for_staging_pods prepare_staging_for_integration_testing

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
	minikube kubectl -- create secret tls backend-tls-secret --namespace staging --cert=blog_posts_app/tls/certs/stg-backend-tls.crt --key=blog_posts_app/tls/keys/stg-backend-tls.key
	minikube kubectl -- create secret tls frontend-staging-posts-com-tls --namespace staging --cert=blog_posts_app/tls/certs/stg-frontend-tls.crt --key=blog_posts_app/tls/keys/stg-frontend-tls.key
	minikube kubectl -- apply -f blog_posts_app/k8s-configs/staging/secrets/auth-service-secrets.yaml
	@echo applying config files
	minikube kubectl -- apply -f blog_posts_app/k8s-configs/staging/configmaps/frontend-configmap.yaml
	minikube kubectl -- apply -f blog_posts_app/k8s-configs/staging/configmaps/auth-service-configmap.yaml
	minikube kubectl -- apply -f blog_posts_app/k8s-configs/staging/configmaps/post-service-configmap.yaml
	minikube kubectl -- apply -f blog_posts_app/k8s-configs/staging/configmaps/rest-service-configmap.yaml
	@echo "applying deployments using kustomize..."
	minikube kubectl -- apply -k blog_posts_app/k8s-configs/staging
	@echo applying ingresses
	minikube kubectl -- apply -f blog_posts_app/k8s-configs/staging/ingress/frontend-posts-ingress.yaml

rollout_staging:
	@echo applying config files
	minikube kubectl -- apply -f blog_posts_app/k8s-configs/staging/configmaps/frontend-configmap.yaml
	minikube kubectl -- apply -f blog_posts_app/k8s-configs/staging/configmaps/auth-service-configmap.yaml
	minikube kubectl -- apply -f blog_posts_app/k8s-configs/staging/configmaps/post-service-configmap.yaml
	minikube kubectl -- apply -f blog_posts_app/k8s-configs/staging/configmaps/rest-service-configmap.yaml
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
	@cd blog_posts_app/rest_service && \
	python3 -m venv .venv && \
	. .venv/bin/activate && \
	python3 -m pip install --upgrade pip==$(PIP_VERSION) > /dev/null && \
	pip install pip-audit && \
	pip-audit --progress-spinner off -r requirements-stg.txt || true
	@stty sane

audit_auth_service:
	@echo "Starting security compliance audit for Auth Service..."
	@cd blog_posts_app/auth_service && \
	python3 -m venv .venv && \
	. .venv/bin/activate && \
	python3 -m pip install --upgrade pip==$(PIP_VERSION) > /dev/null && \
	pip install pip-audit && \
	pip-audit --progress-spinner off -r requirements-stg.txt || true
	@stty sane

audit_post_service:
	@echo "Starting security compliance audit for Post Service..."
	@cd blog_posts_app/post_service && \
	python3 -m venv .venv && \
	. .venv/bin/activate && \
	python3 -m pip install --upgrade pip==$(PIP_VERSION) > /dev/null && \
	pip install pip-audit && \
	pip-audit --progress-spinner off -r requirements-stg.txt || true
	@stty sane

trivy_scan_rest_service:
	@echo "Starting trivy scan for rest service..."
	trivy fs --config blog_posts_app/trivy_conf/trivy.yaml --format table blog_posts_app/rest_service

trivy_scan_auth_service:
	@echo "Starting trivy scan for auth service..."
	trivy fs --config blog_posts_app/trivy_conf/trivy.yaml --format table blog_posts_app/auth_service

trivy_scan_post_service:
	@echo "Starting trivy scan for post service..."
	trivy fs --config blog_posts_app/trivy_conf/trivy.yaml --format table blog_posts_app/post_service

trivy_scan_frontend_service:
	@echo "Starting trivy scan for frotend service..."
	trivy fs --config blog_posts_app/trivy_conf/trivy.yaml --format table blog_posts_app/frontend

trivy_scan_k8s_configs_service:
	@echo "Starting trivy scan for k8s-configs service..."
	trivy fs --config blog_posts_app/trivy_conf/trivy.yaml --format table blog_posts_app/k8s-configs


run_tests: rest_service_tests post_service_tests auth_service_tests frontend_tests

rest_service_tests:
	python3 -m venv "blog_posts_app/rest_service/.venv"
	blog_posts_app/rest_service/.venv/bin/pip install -r blog_posts_app/rest_service/requirements-stg.txt
	PYTHONPATH=blog_posts_app/rest_service ENABLE_MONOTORING=False blog_posts_app/rest_service/.venv/bin/pytest blog_posts_app/rest_service/tests/ --cov=blog_posts_app/rest_service/app -W ignore --cov-report=xml:blog_posts_app/rest_service/coverage.xml --cov-config=blog_posts_app/.coveragerc

post_service_tests:
	python3 -m venv "blog_posts_app/post_service/.venv"
	blog_posts_app/post_service/.venv/bin/pip install -r blog_posts_app/post_service/requirements-stg.txt
	PYTHONPATH=blog_posts_app/post_service ENABLE_MONOTORING=False blog_posts_app/post_service/.venv/bin/pytest blog_posts_app/post_service/tests/ --cov=blog_posts_app/post_service/app -W ignore --cov-report=xml:blog_posts_app/post_service/coverage.xml --cov-config=blog_posts_app/.coveragerc

auth_service_tests:
	python3 -m venv "blog_posts_app/auth_service/.venv"
	blog_posts_app/auth_service/.venv/bin/pip install -r blog_posts_app/auth_service/requirements-stg.txt
	PYTHONPATH=blog_posts_app/auth_service ENABLE_MONOTORING=False blog_posts_app/auth_service/.venv/bin/pytest blog_posts_app/auth_service/tests/ -W ignore --cov=blog_posts_app/auth_service/app --cov-report=xml:blog_posts_app/auth_service/coverage.xml --cov-config=blog_posts_app/.coveragerc

frontend_tests:
	@stty sane || true
	@tput init || true
	cd blog_posts_app/frontend && \
	npm ci && \
	npx playwright install chromium && \
	npm run test -- --coverage --coverage.reporter=lcov --watch=false && \
	echo "starting E2E tests" && \
	npx playwright test

sonar_scan:
	@echo "Running local SonarQube scan via temporary Docker container..."
	@docker run --rm \
		-e SONAR_TOKEN=1b05662110e5d32559a48267d9ef4ab751f62a40 \
		-e SONAR_HOST_URL="https://sonarcloud.io" \
		-e SONAR_SCANNER_SKIP_NODE_PROVISIONING=true \
		-v "$(shell pwd)/blog_posts_app:/usr/src" \
		sonarsource/sonar-scanner-cli \
		-Dsonar.projectBaseDir=/usr/src

clear_staging:
	@echo "Clearing staging..."
	minikube kubectl -- delete namespace staging --wait=true
	@echo "Killing background staging port-forward processes..."
	kill $$(pgrep -f "[p]ort-forward service/rest-internal-service 8000:80") 2>/dev/null || true
	kill $$(pgrep -f "[p]ort-forward service/frontend-internal-service 3000:80") 2>/dev/null || true

#########################################################################Production#######################################################################

deploy_production: start_or_update_production wait_for_production_pods

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
	@echo appling pods secrets
	minikube kubectl -- apply -f blog_posts_app/k8s-configs/production/secrets/auth-service-secrets.yaml
	minikube kubectl -- create secret tls backend-tls-secret --namespace production --cert=blog_posts_app/tls/certs/prd-backend-tls.crt --key=blog_posts_app/tls/keys/prd-backend-tls.key
	minikube kubectl -- create secret tls frontend-production-posts-com-tls --namespace production --cert=blog_posts_app/tls/certs/prd-frontend-tls.crt --key=blog_posts_app/tls/keys/prd-frontend-tls.key
	@echo applying config files
	minikube kubectl -- apply -f blog_posts_app/k8s-configs/production/configmaps/frontend-configmap.yaml
	minikube kubectl -- apply -f blog_posts_app/k8s-configs/production/configmaps/auth-service-configmap.yaml
	minikube kubectl -- apply -f blog_posts_app/k8s-configs/production/configmaps/post-service-configmap.yaml
	minikube kubectl -- apply -f blog_posts_app/k8s-configs/production/configmaps/rest-service-configmap.yaml
	@echo applying deployments
	minikube kubectl -- apply -f blog_posts_app/k8s-configs/production/manifests/frontend-deployment.yaml
	minikube kubectl -- apply -f blog_posts_app/k8s-configs/production/manifests/rest-service-deployment.yaml
	minikube kubectl -- apply -f blog_posts_app/k8s-configs/production/manifests/post-service-deployment.yaml
	minikube kubectl -- apply -f blog_posts_app/k8s-configs/production/manifests/auth-service-deployment.yaml
	@echo applying ingresses
	minikube kubectl -- apply -f blog_posts_app/k8s-configs/production/ingress/frontend-posts-ingress.yaml

rollout_production:
	@echo applying config files
	minikube kubectl -- apply -f blog_posts_app/k8s-configs/production/configmaps/frontend-configmap.yaml
	minikube kubectl -- apply -f blog_posts_app/k8s-configs/production/configmaps/auth-service-configmap.yaml
	minikube kubectl -- apply -f blog_posts_app/k8s-configs/production/configmaps/post-service-configmap.yaml
	minikube kubectl -- apply -f blog_posts_app/k8s-configs/production/configmaps/rest-service-configmap.yaml
	@echo rollout deployments
	minikube kubectl -- rollout restart deployment frontend-deployment -n production
	minikube kubectl -- rollout restart deployment auth-service-deployment -n production
	minikube kubectl -- rollout restart deployment post-service-deployment -n production
	minikube kubectl -- rollout restart deployment rest-service-deployment -n production

rollback_production:
	@echo rolloing back production to previous revison
	minikube kubectl -- rollout undo deployment/rest-service-deployment -n production
	minikube kubectl -- rollout undo deployment/auth-service-deployment -n production
	minikube kubectl -- rollout undo deployment/post-service-deployment -n production
	minikube kubectl -- rollout undo deployment/frontend-deployment  -n production

################################################################################Utils################################################################################

clean:
	@echo "Killing background port-forward processes..."
	@kill $$(pgrep -f "[p]ort-forward service/rest-internal-service 8000:80") 2>/dev/null || true
	@kill $$(pgrep -f "[p]ort-forward service/frontend-internal-service 3000:80") 2>/dev/null || true
	@kill $$(pgrep -f "[p]ort-forward service/ingress-nginx-controller") 2>/dev/null || true
	@kill $$(pgrep -f "[p]ort-forward --namespace kube-system service/registry 32780:80") 2>/dev/null || true
	@kill $$(pgrep -f "[p]ort-forward --cluster=minikube --namespace kube-system service/registry 32780:80") 2>/dev/null || true
	@echo "Deleting minikube cluster and profile..."
	minikube delete --all --purge
	@echo docker stop running images
	docker stop $$(docker ps -qa) || true
	@echo "Removing production Docker images..."
	docker rmi localhost:32780/tokio-rest-service:latest || true
	docker rmi localhost:32780/tokio-post-service:latest || true
	docker rmi localhost:32780/tokio-auth-service:latest || true
	docker rmi localhost:32780/tokio-frontend:latest || true
	@echo "Removing development Docker images..."
	docker rmi localhost:32780/tokio-rest-service:dev || true
	docker rmi localhost:32780/tokio-post-service:dev || true
	docker rmi localhost:32780/tokio-auth-service:dev || true
	docker rmi localhost:32780/tokio-frontend:dev || true
	@echo "removing sonar-qube docker image"
	docker rmi sonarsource/sonar-scanner-cli:latest || true
	@echo "Cleaning docker system"
	docker system prune -af --volumes
	docker builder prune -af
	docker network prune -f
	docker volume prune -af
	@echo docker check resources
	docker system df

fetch-sonar:
	@python3.12 blog_posts_app/get-sonar-summary.py
