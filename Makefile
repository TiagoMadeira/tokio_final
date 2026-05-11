docker_name = "" #Dockerhub account name
docker_password = "" #Dockerhub access token
docker_email = "" #Dockerhub account email

start_minikube:
	@echo starting minikube ...
	minikube start --driver=docker
	@echo enable ingress
	minikube addons enable ingress

start_jaeger_server:
	@echo create observability namespace
	kubectl create namespace observability
	@echo applying configmap files
	kubectl apply -f k8s-configs/observability/configmaps/jaeger-configmap.yaml
	@echo applying deployment
	kubectl apply -f k8s-configs/observability/manifests/jaeger-deployment.yaml
	@echo applying ingress
	kubectl apply -f k8s-configs/observability/ingress/jaeger-ingress.yaml

start_local_development_server:
	@echo Building images this might take a few minutes when runing for the first time
	powershell -Command "& { \
    minikube -p minikube docker-env --shell powershell | Invoke-Expression; \
    docker build --build-arg APP_ENV=dev -t tokio-rest-service:latest rest_service; \
    docker build --build-arg APP_ENV=dev -t tokio-post-service:latest post_service; \
    docker build --build-arg APP_ENV=dev -t tokio-auth-service:latest auth_service; \
    docker build -t frontend:latest frontend; \
	}"
	@echo Unset docker minikube env
	powershell -Command "minikube docker-env -u | Invoke-Expression" -ErrorAction SilentlyContinue
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
	kubectl port-forward service/frontend-internal-service 3000:80 -n development

start_staging_environment:
	@echo create staging namespace
	kubectl create namespace staging
	@echo appling pods secrets
	kubectl create secret docker-registry regcred --namespace staging --docker-server=https://index.docker.io/v1/ --docker-username=$(docker_name) --docker-password=$(docker_password) --docker-email=$(docker_email)
	kubectl create secret tls backend-tls-secret --namespace staging --cert=backend-tls.crt --key=backend-tls.key
	kubectl create secret tls frontend-staging-posts-com-tls --namespace staging --cert=frontend-tls.crt --key=frontend-tls.key
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
	kubectl create secret docker-registry regcred --namespace production --docker-server=https://index.docker.io/v1/ --docker-username=$(docker_name) --docker-password=$(docker_password) --docker-email=$(docker_email)
	@echo appling pods secrets
	kubectl apply -f k8s-configs/production/secrets/auth-service-secrets.yaml
	kubectl create secret tls backend-tls-secret --namespace production --cert=prod-back-tls.crt --key=prod-back-tls.key
	kubectl create secret tls frontend-production-posts-com-tls --namespace production --cert=prod-front-tls.crt --key=prod-front-tls.key
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

rollout_local_development:
	@echo Building images this might take a few minutes when runing for the first time
	powershell -Command "& { \
    minikube -p minikube docker-env --shell powershell | Invoke-Expression; \
    docker build --build-arg APP_ENV=dev -t tokio-rest-service:latest rest_service; \
    docker build --build-arg APP_ENV=dev -t tokio-post-service:latest post_service; \
    docker build --build-arg APP_ENV=dev -t tokio-auth-service:latest auth_service; \
    docker build -t frontend:latest frontend; \
	}"
	@echo Unset docker minikube env
	powershell -Command "minikube docker-env -u | Invoke-Expression" -ErrorAction SilentlyContinue
	@echo appling pods secrets
	kubectl apply -f k8s-configs/development/secrets/auth-service-secrets.yaml
	@echo applying config files
	kubectl apply -f k8s-configs/development/configmaps/auth-service-configmap.yaml
	kubectl apply -f k8s-configs/development/configmaps/post-service-configmap.yaml
	kubectl apply -f k8s-configs/development/configmaps/rest-service-configmap.yaml
	@echo rollout deployments
	kubectl rollout restart deployment auth-service-deployment -n development
	kubectl rollout restart deployment post-service-deployment -n development
	kubectl rollout restart deployment rest-service-deployment -n development

rollout_staging:
	@echo applying config files
	kubectl apply -f k8s-configs/staging/configmaps/auth-service-configmap.yaml
	kubectl apply -f k8s-configs/staging/configmaps/post-service-configmap.yaml
	kubectl apply -f k8s-configs/staging/configmaps/rest-service-configmap.yaml
	@echo rollout deployments
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
	
minikube_prune:
	minikube ssh
	docker system prune -af
	exit