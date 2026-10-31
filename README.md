# Proyecto Final Integrador — Pipeline DevOps

Aplicación Node.js/Express de demostración con Docker, Terraform, AWS EKS, Kubernetes, GitHub Actions, seguridad y monitoreo.

## Arquitectura

1. GitHub recibe un push a `main`.
2. GitHub Actions instala dependencias y ejecuta pruebas.
3. CodeQL analiza el código (SAST).
4. En `main`, Docker construye la imagen, Trivy la analiza y la publica en Amazon ECR.
5. El job de despliegue actualiza EKS y aplica los manifiestos Kubernetes.
6. OWASP ZAP ejecuta un análisis DAST contra `TARGET_URL`.
7. Prometheus recolecta `/metrics` y Grafana presenta dashboards.

## Requisitos

- Git, Docker, Node.js 22 y npm.
- Cuenta AWS con permisos para VPC, EKS, EC2, IAM y ECR.
- Terraform >= 1.6, AWS CLI, kubectl y Helm.
- Repositorio GitHub y permisos para configurar Actions y environments.

## Ejecutar localmente

```bash
cd app
npm install
npm test
npm start
```

Abrir `http://localhost:3000`, `http://localhost:3000/health` y `http://localhost:3000/metrics`.

Con Docker:

```bash
docker build -t pf-devops-web:local ./app
docker run --rm -p 3000:3000 pf-devops-web:local
```

## Provisionar AWS

> Atención: EKS, NAT Gateway, balanceadores y nodos generan costos. Revisar precios de la región y destruir recursos al terminar.

```bash
cd terraform
cp terraform.tfvars.example terraform.tfvars
terraform init
terraform fmt -check
terraform validate
terraform plan
terraform apply
```

Configurar kubectl con el output `configure_kubectl`. El estado de Terraform debe guardarse en un backend remoto cifrado y con locking antes de uso colaborativo/producción. Este ejemplo usa estado local para facilitar la práctica.

Crear ECR (si no se crea por separado) y configurar `ECR_REPOSITORY`. El rol IAM de GitHub debe confiar en OIDC y tener permisos mínimos para ECR y EKS. Guardar su ARN como secret `AWS_GITHUB_ROLE_ARN`. No guardar claves AWS estáticas en el repositorio.

## Kubernetes

El workflow aplica namespace, Deployment, Service y HPA. El manifiesto Ingress requiere AWS Load Balancer Controller, un dominio real y, para HTTPS, certificado ACM. Reemplazar `app.example.com`. Instalar Metrics Server para que HPA pueda obtener CPU.

```bash
kubectl get pods -n pf-devops
kubectl get svc -n pf-devops
kubectl get hpa -n pf-devops
kubectl rollout status deployment/web -n pf-devops
```

## Monitoreo

Instalar el chart kube-prometheus-stack (requiere Helm y permisos de cluster):

```bash
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update
helm upgrade --install monitoring prometheus-community/kube-prometheus-stack \
  --namespace monitoring --create-namespace -f monitoring/values.yaml
kubectl apply -f monitoring/servicemonitor.yaml
```

Para acceder temporalmente a Grafana: `kubectl port-forward svc/monitoring-grafana 3000:80 -n monitoring`. Consultar la contraseña configurada como secreto; no dejar la contraseña de ejemplo. Prometheus recolectará `/metrics` mediante ServiceMonitor. Importar dashboards de Kubernetes y Node.js para visualizar CPU, memoria, tráfico y errores.

## Seguridad (DevSecOps)

- CodeQL: análisis estático de JavaScript.
- Trivy: analiza vulnerabilidades de la imagen y bloquea HIGH/CRITICAL.
- OWASP ZAP Baseline: análisis dinámico del sitio desplegado. Definir `TARGET_URL` en Variables del Environment `test`. El baseline es una comprobación inicial, no una auditoría exhaustiva.
- Usar OIDC, IAM de mínimo privilegio, secretos del entorno, imágenes no-root, probes y límites de recursos.

## FinOps

- Node group SPOT con límites min/max y HPA para ajustar Pods.
- Una NAT Gateway para reducir costo frente a una por zona (con menor resiliencia).
- Usar `terraform destroy` al terminar la práctica.
- No mantener clústeres, NAT, discos o balanceadores encendidos sin necesidad.
- Para producción, evaluar Savings Plans/Reserved Instances, presupuestos y alertas de AWS.

## Evidencias a adjuntar

No se incluyen capturas ficticias. Guardar capturas reales de:
1. GitHub Actions con jobs exitosos.
2. ECR mostrando la etiqueta basada en commit SHA.
3. `kubectl get pods,svc,hpa -n pf-devops`.
4. Página de la aplicación y endpoint `/health`.
5. Grafana con métricas de CPU/memoria y solicitudes.
6. Resultados de CodeQL, Trivy y OWASP ZAP.

## Limpieza

```bash
cd terraform
terraform destroy
```

Eliminar también recursos creados manualmente (por ejemplo, repositorio ECR si no se gestiona con Terraform) y verificar que no queden balanceadores, volúmenes ni IPs cobrables.

## Estructura

```text
app/                 Aplicación, tests y Dockerfile
terraform/           Infraestructura AWS (VPC y EKS)
k8s/                 Namespace, Deployment, Service, Ingress y HPA
monitoring/          Valores Helm y ServiceMonitor
.github/workflows/   Pipeline CI/CD
```

## Limitaciones conocidas del laboratorio

- La creación de EKS y su configuración IAM/OIDC/ECR requiere pasos de cuenta AWS que dependen del entorno.
- El workflow presupone que el clúster `pf-devops`, ECR y el rol OIDC ya existen.
- El paso de instalación del AWS Load Balancer Controller es una guía pendiente de configurar para el entorno; por eso Ingress no se crea automáticamente.
- Ajustar la versión de Kubernetes a una soportada por EKS en la región elegida.
- El estado local de Terraform no es adecuado para equipos: configurar S3 + locking remoto antes de trabajo compartido.
