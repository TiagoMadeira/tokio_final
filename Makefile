docker_name = "" #Dockerhub account name
docker_password = "" #Dockerhub access token
docker_email = "" #Dockerhub account email

WSL_DISTRO := Ubuntu
WSL_USER := ubuntu

################################################################################can ran locally################################################################################

start_development: start_minikube start_jaeger_server build_images start_development_server add_hosts expose_ingress_controller

start_staging_local: start_minikube start_jaeger_server start_local_staging_env add_hosts expose_ingress_controller

start_production_local: start_minikube start_jaeger_server start_local_production_env add_hosts expose_ingress_controller

stop_development: 
	kubectl delete namespace development

stop_staging: 
	kubectl delete namespace staging

stop_production: 
	kubectl delete namespace production

setup_self_hosted_runner: install_runner install_chromium_dependencies

stop_runner:
	@echo "Stopping runner execution..."
	@pkill -f "./bin/Runner.Listener" || echo "Runner was not active."

start_runner:
	@echo "Starting the runner background service..."
	cd actions-runner && ./run.sh

start_minikube: verify_kubectl
	@echo "Checking Minikube status..."
	@if minikube status >/dev/null 2>&1; then \
		echo "Minikube is already running."; \
	else \
		echo "Starting Minikube..."; \
		minikube start --driver=docker --cpus=4 --memory=4096MB; \
		sleep 10;\
		echo "Enabling Ingress addon..."; \
		minikube addons enable ingress; \
	fi
	@echo "Waiting for nginx ingress readiness..."
	@kubectl wait --namespace ingress-nginx --for=condition=ready pod --selector=app.kubernetes.io/component=controller --timeout=120s

start_jaeger_server:
	@echo "Checking for observability namespace..."
	@if ! kubectl get namespace observability >/dev/null 2>&1; then \
		echo "Creating observability namespace..."; \
		kubectl create namespace observability; \
	fi
	@echo "Applying configurations (idempotent)..."
	@kubectl apply -f k8s-configs/observability/configmaps/jaeger-configmap.yaml
	@kubectl apply -f k8s-configs/observability/configmaps/jaeger-ui-config.yaml
	@kubectl apply -f k8s-configs/observability/manifests/jaeger-deployment.yaml
	@kubectl apply -f k8s-configs/observability/ingress/jaeger-ingress.yaml


build_images:
	@echo "Building images directly inside Minikube..."
	@eval $$(minikube -p minikube docker-env) && \
	docker build --no-cache --build-arg APP_ENV=dev -t tokio-rest-service:latest rest_service && \
	docker build --no-cache --build-arg APP_ENV=dev -t tokio-post-service:latest post_service && \
	docker build --no-cache --build-arg APP_ENV=dev -t tokio-auth-service:latest auth_service && \
	docker build --no-cache -t frontend:latest frontend

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

start_development_server:
	@echo create development namespace
	kubectl create namespace development
	@echo appling pods secrets
	kubectl create secret tls backend-tls-secret --namespace development --cert=backend-tls.crt --key=backend-tls.key
	kubectl create secret tls frontend-development-posts-com-tls --namespace development --cert=dev-tls.crt --key=dev-tls.key
	kubectl apply -f k8s-configs/development/secrets/auth-service-secrets.yaml
	@echo applying config files
	kubectl apply -f k8s-configs/development/configmaps/frontend-configmap.yaml
	kubectl apply -f k8s-configs/development/configmaps/auth-service-configmap.yaml
	kubectl apply -f k8s-configs/development/configmaps/post-service-configmap.yaml
	kubectl apply -f k8s-configs/development/configmaps/rest-service-configmap.yaml
	@echo applying deployments
	kubectl apply -f k8s-configs/development/manifests/frontend-deployment.yaml
	kubectl apply -f k8s-configs/development/manifests/rest-service-deployment.yaml
	kubectl apply -f k8s-configs/development/manifests/post-service-deployment.yaml
	kubectl apply -f k8s-configs/development/manifests/auth-service-deployment.yaml
	@echo applying ingresses
	kubectl apply -f k8s-configs/development/ingress/frontend-posts-ingress.yaml

rollout_development:
	@echo Building images this might take a few minutes when runing for the first time
	@echo "Building images directly inside Minikube..."
	@eval $$(minikube -p minikube docker-env) && \
	docker build --build-arg APP_ENV=dev -t tokio-rest-service:latest rest_service && \
	docker build --build-arg APP_ENV=dev -t tokio-post-service:latest post_service && \
	docker build --build-arg APP_ENV=dev -t tokio-auth-service:latest auth_service && \
	docker build -t frontend:latest frontend
	@echo appling pods secrets
	kubectl apply -f k8s-configs/development/secrets/auth-service-secrets.yaml
	@echo applying config files
	kubectl apply -f k8s-configs/development/configmaps/frontend-configmap.yaml
	kubectl apply -f k8s-configs/development/configmaps/auth-service-configmap.yaml
	kubectl apply -f k8s-configs/development/configmaps/post-service-configmap.yaml
	kubectl apply -f k8s-configs/development/configmaps/rest-service-configmap.yaml
	@echo rollout deployments
	kubectl rollout restart deployment frontend-deployment -n development
	kubectl rollout restart deployment auth-service-deployment -n development
	kubectl rollout restart deployment post-service-deployment -n development
	kubectl rollout restart deployment rest-service-deployment -n development

install_chromium_dependencies:
	@echo installing chromium dependencies for E2E tests
	sudo apt-get update
	sudo apt-get install -y libnspr4 libnss3 libgbm1 libasound2

install_runner:
	@echo "Creating runner directory..."
	mkdir actions-runner
	@echo "Downloading runner..."
	cd actions-runner && curl -o actions-runner-linux-x64-2.335.1.tar.gz -L https://github.com/actions/runner/releases/download/v2.335.1/actions-runner-linux-x64-2.335.1.tar.gz
	@echo "Extracting installer packages..."
	cd actions-runner && tar xzf ./actions-runner-linux-x64-2.335.1.tar.gz
	@echo "Configuring runner..."
	cd actions-runner && \
	set -a && . ../.make_env && set +a && \
	./config.sh --url  https://github.com/TiagoMadeira/tokio_final --token $$RUNNER_TOKEN --unattended



start_local_production_env:
	(set -a && . ./.make_env && set +a && make start_production_environment docker_name="$$DOCKER_USERNAME" docker_password="$$DOCKERHUB_ACCESS_TOKEN" docker_email="$$DOCKER_EMAIL")

start_local_staging_env:
	(set -a && . ./.make_env && set +a && make start_staging_environment docker_name="$$DOCKER_USERNAME" docker_password="$$DOCKERHUB_ACCESS_TOKEN" docker_email="$$DOCKER_EMAIL")

expose_ingress_controller:
	@echo "Checking if Ingress Controller port-forward is already active..."
	@if sudo lsof -i :80 -i :443 >/dev/null 2>&1; then \
		echo "Ports 80/443 are already occupied. Skipping port-forward."; \
	else \
		echo "Ports are free. Exposing Ingress Controller to all interfaces..."; \
		sudo -E kubectl port-forward service/ingress-nginx-controller -n ingress-nginx 80:80 443:443; \
	fi

verify_kubectl:
	@command -v kubectl >/dev/null 2>&1 || (echo "Installing kubectl..." &&  curl -LO "https://dl.k8s.io/release/$$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl" && chmod +x ./kubectl && sudo mv ./kubectl /usr/local/bin/kubectl)

clean:
	minikube delete

fetch-sonar:
	@python get-sonar-summary.py


################################################## Used only in CI "################################################################################

start_staging_environment:
	@echo create staging namespace
	kubectl create namespace staging
	@echo appling pods secrets
	@kubectl create secret docker-registry regcred --namespace staging --docker-server=https://index.docker.io/v1/ --docker-username=$(docker_name) --docker-password=$(docker_password) --docker-email=$(docker_email)
	kubectl create secret tls backend-tls-secret --namespace staging --cert=staging-backend-tls.crt --key=staging-backend-tls.key
	kubectl create secret tls frontend-staging-posts-com-tls --namespace staging --cert=staging-frontend-tls.crt --key=staging-frontend-tls.key
	kubectl apply -f k8s-configs/staging/secrets/auth-service-secrets.yaml
	@echo applying config files
	kubectl apply -f k8s-configs/staging/configmaps/frontend-configmap.yaml
	kubectl apply -f k8s-configs/staging/configmaps/auth-service-configmap.yaml
	kubectl apply -f k8s-configs/staging/configmaps/post-service-configmap.yaml
	kubectl apply -f k8s-configs/staging/configmaps/rest-service-configmap.yaml
	@echo applying deployments
	kubectl apply -f k8s-configs/staging/manifests/frontend-deployment.yaml
	kubectl apply -f k8s-configs/staging/manifests/rest-service-deployment.yaml
	kubectl apply -f k8s-configs/staging/manifests/post-service-deployment.yaml
	kubectl apply -f k8s-configs/staging/manifests/auth-service-deployment.yaml
	@echo applying ingresses
	kubectl apply -f k8s-configs/staging/ingress/frontend-posts-ingress.yaml

start_production_environment:
	@echo create production namespace
	kubectl create namespace production
	@echo creating docker registry secret
	@kubectl create secret docker-registry regcred --namespace production --docker-server=https://index.docker.io/v1/ --docker-username=$(docker_name) --docker-password=$(docker_password) --docker-email=$(docker_email)
	@echo appling pods secrets
	kubectl apply -f k8s-configs/production/secrets/auth-service-secrets.yaml
	kubectl create secret tls backend-tls-secret --namespace production --cert=prod-backend-tls.crt --key=prod-backend-tls.key
	kubectl create secret tls frontend-production-posts-com-tls --namespace production --cert=prod-frontend-tls.crt --key=prod-frontend-tls.key
	@echo applying config files
	kubectl apply -f k8s-configs/production/configmaps/frontend-configmap.yaml
	kubectl apply -f k8s-configs/production/configmaps/auth-service-configmap.yaml
	kubectl apply -f k8s-configs/production/configmaps/post-service-configmap.yaml
	kubectl apply -f k8s-configs/production/configmaps/rest-service-configmap.yaml
	@echo applying deployments
	kubectl apply -f k8s-configs/production/manifests/frontend-deployment.yaml
	kubectl apply -f k8s-configs/production/manifests/rest-service-deployment.yaml
	kubectl apply -f k8s-configs/production/manifests/post-service-deployment.yaml
	kubectl apply -f k8s-configs/production/manifests/auth-service-deployment.yaml
	@echo applying ingresses
	kubectl apply -f k8s-configs/production/ingress/frontend-posts-ingress.yaml

rollout_staging:
	@echo applying config files
	kubectl apply -f k8s-configs/staging/configmaps/frontend-configmap.yaml
	kubectl apply -f k8s-configs/staging/configmaps/auth-service-configmap.yaml
	kubectl apply -f k8s-configs/staging/configmaps/post-service-configmap.yaml
	kubectl apply -f k8s-configs/staging/configmaps/rest-service-configmap.yaml
	@echo rollout deployments
	kubectl rollout restart deployment frontend-deployment -n staging
	kubectl rollout restart deployment auth-service-deployment -n staging
	kubectl rollout restart deployment post-service-deployment -n staging
	kubectl rollout restart deployment rest-service-deployment -n staging

rollout_production:
	@echo applying config files
	kubectl apply -f k8s-configs/production/configmaps/frontend-configmap.yaml
	kubectl apply -f k8s-configs/production/configmaps/auth-service-configmap.yaml
	kubectl apply -f k8s-configs/production/configmaps/post-service-configmap.yaml
	kubectl apply -f k8s-configs/production/configmaps/rest-service-configmap.yaml
	@echo rollout deployments
	kubectl rollout restart deployment frontend-deployment -n production
	kubectl rollout restart deployment auth-service-deployment -n production
	kubectl rollout restart deployment post-service-deployment -n production
	kubectl rollout restart deployment rest-service-deployment -n production
