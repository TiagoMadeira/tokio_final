docker_name = #Dockerhub account name
docker_password = #Dockerhub access token
docker_email = #Dockerhub account email


start_minikube:
	@echo starting minikube ...
	minikube start
	@echo enable ingress
	minikube addons enable ingress

start_jaeger_server:
	@echo create observability namespace
	kubectl create namespace observability
	@echo applying configmap files
	kubectl apply -f observability/configmaps/jaeger-configmap.yaml
	@echo applying deployment
	kubectl apply -f observability/manifests/jaeger-deployment.yaml
	@echo applying ingress
	kubectl apply -f observability/ingress/jaeger-ingress.yaml


start_development_environment:
	@echo create development namespace
	kubectl create namespace development
	@echo creating docker registry secret
	kubectl create secret docker-registry regcred --namespace development --docker-server=https://index.docker.io/v1/ --docker-username=$(docker_name) --docker-password=$(docker_password) --docker-email=$(docker_email)
	@echo appling pods secrets
	kubectl apply -f development/secrets/auth-service-secrets.yaml
	@echo applying config files
	kubectl apply -f development/configmaps/auth-service-configmap.yaml
	kubectl apply -f development/configmaps/post-service-configmap.yaml
	kubectl apply -f development/configmaps/rest-service-configmap.yaml
	@echo applying deployments
	kubectl apply -f development/manifests/rest-service-deployment.yaml
	kubectl apply -f development/manifests/post-service-deployment.yaml
	kubectl apply -f development/manifests/auth-service-deployment.yaml
	@echo applying ingresses
	kubectl apply -f development/ingress/posts-ingress.yaml

start_staging_environment:
	@echo create development namespace
	kubectl create namespace staging
	@echo creating docker registry secret
	kubectl create secret docker-registry regcred --namespace staging --docker-server=https://index.docker.io/v1/ --docker-username=$(docker_name) --docker-password=$(docker_password) --docker-email=$(docker_email)
	@echo appling pods secrets
	kubectl apply -f staging/secrets/auth-service-secrets.yaml
	@echo applying config files
	kubectl apply -f staging/configmaps/auth-service-configmap.yaml
	kubectl apply -f staging/configmaps/post-service-configmap.yaml
	kubectl apply -f staging/configmaps/rest-service-configmap.yaml
	@echo applying deployments
	kubectl apply -f staging/manifests/rest-service-deployment.yaml
	kubectl apply -f staging/manifests/post-service-deployment.yaml
	kubectl apply -f staging/manifests/auth-service-deployment.yaml
	@echo applying ingresses
	kubectl apply -f staging/ingress/posts-ingress.yaml

start_production_environment:
	@echo create production namespace
	kubectl create namespace production
	@echo creating docker registry secret
	kubectl create secret docker-registry regcred --namespace production --docker-server=https://index.docker.io/v1/ --docker-username=$(docker_name) --docker-password=$(docker_password) --docker-email=$(docker_email)
	@echo appling pods secrets
	kubectl apply -f production/secrets/auth-service-secrets.yaml
	kubectl create secret tls posts-com-tls --namespace production --cert=tls.crt --key=tls.key
	@echo applying config files
	kubectl apply -f production/configmaps/auth-service-configmap.yaml
	kubectl apply -f production/configmaps/post-service-configmap.yaml
	kubectl apply -f production/configmaps/rest-service-configmap.yaml
	@echo applying deployments
	kubectl apply -f production/manifests/rest-service-deployment.yaml
	kubectl apply -f production/manifests/post-service-deployment.yaml
	kubectl apply -f production/manifests/auth-service-deployment.yaml
	@echo applying ingresses
	kubectl apply -f production/ingress/posts-ingress.yaml


update_development:
	@echo applying config files
	kubectl apply -f development/configmaps/auth-service-configmap.yaml
	kubectl apply -f development/configmaps/post-service-configmap.yaml
	kubectl apply -f development/configmaps/rest-service-configmap.yaml
	@echo applying deployments
	kubectl apply -f development/manifests/rest-service-deployment.yaml
	kubectl apply -f development/manifests/post-service-deployment.yaml
	kubectl apply -f development/manifests/auth-service-deployment.yaml

update_staging:
	@echo applying config files
	kubectl apply -f staging/configmaps/auth-service-configmap.yaml
	kubectl apply -f staging/configmaps/post-service-configmap.yaml
	kubectl apply -f staging/configmaps/rest-service-configmap.yaml
	@echo applying deployments
	kubectl apply -f staging/manifests/rest-service-deployment.yaml
	kubectl apply -f staging/manifests/post-service-deployment.yaml
	kubectl apply -f staging/manifests/auth-service-deployment.yaml

update_production:
	@echo applying config files
	kubectl apply -f production/configmaps/auth-service-configmap.yaml
	kubectl apply -f production/configmaps/post-service-configmap.yaml
	kubectl apply -f production/configmaps/rest-service-configmap.yaml
	@echo applying deployments
	kubectl apply -f production/manifests/rest-service-deployment.yaml
	kubectl apply -f production/manifests/post-service-deployment.yaml
	kubectl apply -f production/manifests/auth-service-deployment.yaml

minikube_prune:
	minikube ssh
	docker system prune -af
	exit