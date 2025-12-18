# 🏠 Guia de Deploy Local: Laravel com Kubernetes no seu Computador

> 🚀 **Ambiente de Desenvolvimento Local com Kubernetes** - Simula a produção no seu computador!

Este guia mostra como configurar um cluster Kubernetes **localmente** para desenvolver e testar aplicações Laravel antes de fazer deploy na VPS.

> 💡 **Por que usar Kubernetes localmente?**
> - Testa configurações antes do deploy em produção
> - Ambiente idêntico à produção
> - Aprende Kubernetes sem custo de VPS
> - Debug e desenvolvimento mais rápido

---

## 📋 Índice

### PARTE 1: Preparação do Ambiente Local
1. [Instalação do Docker Desktop](#1-instalação-do-docker-desktop)
2. [Ativar Kubernetes no Docker Desktop](#2-ativar-kubernetes-no-docker-desktop)
3. [Instalação de Componentes Essenciais](#3-instalação-de-componentes-essenciais)
4. [Verificação da Instalação](#4-verificação-da-instalação)

### PARTE 2: Deploy de Projetos Laravel Localmente
5. [Preparação do Projeto Laravel](#5-preparação-do-projeto-laravel)
6. [Configuração dos Arquivos Kubernetes](#6-configuração-dos-arquivos-kubernetes)
7. [Deploy Local](#7-deploy-local)
8. [Acesso à Aplicação](#8-acesso-à-aplicação)
9. [Desenvolvimento e Debug](#9-desenvolvimento-e-debug)

---

# 📦 PARTE 1: Preparação do Ambiente Local

## 1. Instalação do Docker e Minikube (Linux)

> 🐳 **Docker + Minikube**: Stack completo para rodar Kubernetes localmente no Linux!

```bash
# Instalar Docker Engine
sudo apt update
sudo apt install -y ca-certificates curl gnupg lsb-release

# Adicionar chave GPG do Docker
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | \
    sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg

# Adicionar repositório
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
  https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Instalar Docker
sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io \
    docker-buildx-plugin docker-compose-plugin

# Adicionar seu usuário ao grupo docker (evita usar sudo)
sudo usermod -aG docker $USER

# Aplicar mudanças (ou faça logout/login)
newgrp docker

# Verificar instalação
docker --version
docker run hello-world
```

**Para instalar kubectl:**

```bash
# Baixar kubectl
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"

# Tornar executável
chmod +x kubectl

# Mover para PATH
sudo mv kubectl /usr/local/bin/

# Verificar instalação
kubectl version --client
```

**Instalar Minikube (Kubernetes local para Linux):**

```bash
# Baixar Minikube
curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64

# Instalar
sudo install minikube-linux-amd64 /usr/local/bin/minikube

# Verificar
minikube version
```

---

## 2. Iniciar Kubernetes com Minikube

```bash
# Iniciar Minikube com driver Docker
minikube start --driver=docker

# Verificar status
minikube status

# Configurar kubectl para usar Minikube
kubectl config use-context minikube

# Verificar nó
kubectl get nodes
```

**Saída esperada:**
```
NAME       STATUS   ROLES           AGE   VERSION
minikube   Ready    control-plane   2m    v1.28.x
```

---

## 3. Instalação de Componentes Essenciais

### 3.1 Instalar Nginx Ingress Controller

> 🚪 **Ingress Controller local**: Permite acessar aplicações via HTTP/HTTPS no localhost.

```bash
# Habilitar addon do Ingress
minikube addons enable ingress

# Verificar
kubectl get pods -n ingress-nginx
```

**Saída esperada:**
```
NAME                                        READY   STATUS    RESTARTS   AGE
ingress-nginx-controller-xxx                1/1     Running   0          2m
```

### 3.2 Instalar Metrics Server (opcional, para kubectl top)

```bash
# Instalar Metrics Server
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml

# Patch para funcionar localmente (ignora certificados TLS)
kubectl patch deployment metrics-server -n kube-system --type='json' \
  -p='[{"op": "add", "path": "/spec/template/spec/containers/0/args/-", "value": "--kubelet-insecure-tls"}]'

# Aguardar ficar pronto (pode demorar 3-5 minutos)
kubectl wait --namespace kube-system \
  --for=condition=ready pod \
  --selector=k8s-app=metrics-server \
  --timeout=300s

# Se der timeout, não se preocupe! Verifique se está rodando:
kubectl get pods -n kube-system | grep metrics-server

# Aguardar 1-2 minutos para métricas aparecerem
sleep 60

# Testar (se funcionar, está tudo certo!)
kubectl top nodes
```

---

## 4. Verificação da Instalação

```bash
# Verificar nós do cluster
kubectl get nodes

# Verificar todos os pods do sistema
kubectl get pods --all-namespaces

# Verificar serviços
kubectl get svc --all-namespaces

# Verificar versão do Kubernetes
kubectl version
```

> ✅ **Se todos os pods estão "Running", seu Kubernetes local está pronto!** 🎉

---

# 🚢 PARTE 2: Deploy de Projetos Laravel Localmente

## 5. Preparação do Projeto Laravel

### 5.1 Clonar Projeto Existente ou Criar Novo

**🎯 OPÇÃO 1: Usar Docker para criar projeto (RECOMENDADO - não precisa instalar PHP/Composer)**

```bash
# Criar projeto Laravel usando Docker (sem instalar PHP no host)
docker run --rm -v $(pwd):/app composer create-project laravel/laravel {{NAMESPACE}}

# Entrar no projeto
cd {{NAMESPACE}}
```

> ✅ **Vantagem**: Não polui seu sistema com PHP/Composer, tudo roda em container!

**OPÇÃO 2: Usar projeto Laravel existente**

```bash
# Se já tem um projeto Laravel
cd /caminho/para/seu-projeto-laravel
```

**OPÇÃO 3: Instalar Composer no host (não recomendado, mas funciona)**

```bash
# Instalar PHP e Composer
sudo apt install composer php-cli php-xml php-mbstring php-zip

# Criar projeto
composer create-project laravel/laravel {{NAMESPACE}}
cd {{NAMESPACE}}
```

### 5.2 Clonar Repositório de Setup

```bash
# Clonar o repositório kubernetes-vps-setup DENTRO do projeto
git clone https://github.com/SEU_USUARIO/kubernetes-vps-setup.git
# ou
git clone git@github.com:SEU_USUARIO/kubernetes-vps-setup.git

# Ou se você já tem o repositório localmente:
cp -r /caminho/para/kubernetes-vps-setup ./
```

---

## 6. Gerar Configurações Automaticamente

> 🎯 **Setup Automático**: O script `setup.sh` gera TODOS os arquivos necessários!

### 6.1 Executar Script de Setup

```bash
# Entrar no diretório de setup
cd kubernetes-vps-setup

# Executar o script
./setup.sh
```

### 6.2 Responder Perguntas do Setup

O script fará perguntas interativas. Para ambiente **local**, use estas configurações:

```bash
📦 Nome do projeto: {{NAMESPACE}}
🏢 Namespace Kubernetes: {{NAMESPACE}}
🌐 Domínio principal: {{DOMAIN}}  # Use .test para desenvolvimento local

🖥️  IP da VPS: 127.0.0.1  # Usar localhost para ambiente local

🐙 Usuário GitHub: {{GITHUB_USER}}
📦 Nome do repositório: {{GITHUB_REPO}}

🔑 APP_KEY: [deixe vazio - será gerado automaticamente]
📧 Email do APP: admin@{{DOMAIN}}

🗄️  Nome do banco: laravel
👤 Usuário do banco: laravel
🔐 Senha PostgreSQL: [deixe vazio - será gerada automaticamente]

🔐 Senha Redis: [deixe vazio - será gerada automaticamente]

☁️  Usar Spaces/S3?: n  # Não para ambiente local

🔑 Reverb APP_ID: [deixe vazio - será gerado]
🔐 Reverb APP_KEY: [deixe vazio - será gerado]
🔐 Reverb APP_SECRET: [deixe vazio - será gerado]
```

### 6.3 Resultado do Setup

O script criará automaticamente:

```
seu-projeto-laravel/
├── kubernetes/           ← 📁 Arquivos Kubernetes para produção
│   ├── namespace.yaml
│   ├── secrets.yaml
│   ├── configmap.yaml
│   ├── postgres.yaml
│   ├── redis.yaml
│   ├── deployment.yaml
│   ├── service.yaml
│   ├── ingress.yaml
│   ├── cert-issuer.yaml
│   └── migration-job.yaml
├── .dev/                 ← 📁 Desenvolvimento local (Docker Compose)
│   ├── docker-compose.yml
│   ├── Dockerfile.dev
│   ├── nginx.conf
│   ├── supervisord.conf
│   ├── php.ini
│   └── .env.local
├── docker/               ← 📁 Configs Docker para produção
│   ├── nginx/
│   │   └── default.conf
│   └── supervisor/
│       └── supervisord.conf
├── .github/
│   └── workflows/
│       └── deploy.yml    ← 📁 CI/CD (GitHub Actions)
├── Dockerfile            ← 🐳 Dockerfile de produção
└── docs/                 ← 📚 Documentação completa
```

> ✅ **Importante**: Após executar `setup.sh`, o diretório `kubernetes-vps-setup/` será **automaticamente apagado**!

---

## 7. Deploy Local com Docker Compose OU Kubernetes

Após o setup, você tem **duas opções** de desenvolvimento local:

### Opção A: Docker Compose (Recomendado para Dev Local)

```bash
# Usar configuração gerada em .dev/
cd .dev
docker-compose up -d

# Verificar se containers estão rodando
docker-compose ps

# Ver logs (caso haja erro)
docker-compose logs -f

# Acessar aplicação
# http://localhost:8000
```

**Troubleshooting Docker Compose:**

```bash
# Se der erro ERR_CONNECTION_RESET:
# 1. Verificar containers
docker ps

# 2. Ver logs completos
docker-compose logs

# 3. Verificar porta 8000
sudo lsof -i :8000
# ou
sudo netstat -tulpn | grep 8000

# 4. Parar e reiniciar
docker-compose down
docker-compose up -d

# 5. Se não funcionar, use a Opção B (Minikube) - são independentes!
```

### Opção B: Kubernetes Local (Simula Produção)

Continue com os passos abaixo para usar Minikube.

---

## 7. Deploy Local no Minikube

### 7.1 Build da Imagem Docker

```bash
# Retornar ao diretório raiz do projeto
cd ..  # (sair de kubernetes-vps-setup ou .dev)

# Build usando Dockerfile gerado
docker build -t {{GITHUB_USER}}/{{GITHUB_REPO}}:latest .

# Verificar imagem
docker images | grep {{GITHUB_REPO}}
```

### 7.2 Carregar Imagem no Minikube

```bash
# Carregar imagem no cluster Minikube
minikube image load {{GITHUB_USER}}/{{GITHUB_REPO}}:latest

# Verificar
minikube image ls | grep {{GITHUB_REPO}}
```

### 7.3 Aplicar Configurações no Kubernetes

```bash
# Aplicar todos os arquivos de uma vez
kubectl apply -f kubernetes/

# Aguardar recursos serem criados
sleep 5
```

### 7.4 Verificar e Aguardar Pods Ficarem Prontos

```bash
# Ver status dos pods
kubectl get pods -n {{NAMESPACE}} -w

# Aguardar até todos ficarem "Running"
# Pressione Ctrl+C quando todos estiverem prontos
```

### 7.5 Executar Migrations

```bash
# Executar migration-job gerado pelo setup.sh
kubectl apply -f kubernetes/migration-job.yaml

# Ou executar dentro do pod da aplicação
kubectl exec -it -n {{NAMESPACE}} deployment/app -- \
    php artisan migrate --force

# Seed (opcional)
kubectl exec -it -n {{NAMESPACE}} deployment/app -- \
    php artisan db:seed --force
```

---

## 8. Acesso à Aplicação

### 8.1 Configurar /etc/hosts

**No Linux:**

```bash
# Editar /etc/hosts
sudo nano /etc/hosts

# Adicionar linha (ao final do arquivo):
127.0.0.1 {{DOMAIN}}

# Salvar: Ctrl+O, Enter, Ctrl+X
```

> 💡 **Dica**: Use domínios `.test` para desenvolvimento local (padrão recomendado)

### 8.1.1 Virtual Hosts - Múltiplos Domínios/Subdomínios

**Você pode configurar múltiplos domínios e subdomínios!** Exemplo:

```bash
# Editar /etc/hosts
sudo nano /etc/hosts

# Adicionar múltiplos domínios:
127.0.0.1 {{DOMAIN}}
127.0.0.1 admin.{{DOMAIN}}
127.0.0.1 api.{{DOMAIN}}
127.0.0.1 app.{{DOMAIN}}
```

**Depois, configure o Ingress para responder a cada domínio:**

Edite `kubernetes/ingress.yaml` após o setup:

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: app-ingress
  namespace: {{NAMESPACE}}
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
spec:
  ingressClassName: nginx
  rules:
  # Domínio principal
  - host: {{DOMAIN}}
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: app-service
            port:
              number: 80
  
  # Subdomínio admin (pode apontar para mesmo serviço ou outro)
  - host: admin.{{DOMAIN}}
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: app-service  # Mesmo serviço
            port:
              number: 80
  
  # Subdomínio API (exemplo com serviço diferente)
  - host: api.{{DOMAIN}}
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: app-service
            port:
              number: 80
```

**Reaplicar Ingress:**

```bash
kubectl apply -f kubernetes/ingress.yaml

# Verificar
kubectl get ingress -n {{NAMESPACE}}
```

**Agora você pode acessar:**
- http://{{DOMAIN}}
- http://admin.{{DOMAIN}}
- http://api.{{DOMAIN}}

> 💡 **No Laravel**: Use rotas com `domain()` para diferenciar subdomínios:

```php
// routes/web.php
Route::domain('{{DOMAIN}}')->group(function () {
    Route::get('/', [HomeController::class, 'index']);
});

Route::domain('admin.{{DOMAIN}}')->group(function () {
    Route::get('/', [AdminController::class, 'dashboard']);
});

Route::domain('api.{{DOMAIN}}')->group(function () {
    Route::get('/status', [ApiController::class, 'status']);
});
```

### 8.2 Minikube Tunnel

```bash
# Iniciar tunnel do Minikube (deixar rodando em terminal separado)
minikube tunnel

# Em outro terminal, verificar IP do Ingress
kubectl get ingress -n {{NAMESPACE}}

# Se tunnel estiver ativo, acessar normalmente
```

### 8.3 Acessar no Navegador

```bash
# Abrir navegador em:
http://{{DOMAIN}}

# Testar subdomínios:
http://admin.{{DOMAIN}}

# Ou testar via curl:
curl -I http://{{DOMAIN}}
curl -I http://admin.{{DOMAIN}}
```

---

## 9. Desenvolvimento e Debug

### 9.1 Ver Logs em Tempo Real

```bash
# Logs da aplicação
kubectl logs -f -n {{NAMESPACE}} deployment/app

# Logs do PostgreSQL
kubectl logs -f -n {{NAMESPACE}} statefulset/postgres

# Logs do Redis
kubectl logs -f -n {{NAMESPACE}} statefulset/redis
```

### 9.2 Executar Comandos Artisan

```bash
# Entrar no pod
kubectl exec -it -n {{NAMESPACE}} deployment/app -- bash

# Dentro do pod:
php artisan migrate
php artisan tinker
php artisan route:list
php artisan queue:work
exit
```

### 9.3 Acessar Banco de Dados

```bash
# Conectar ao PostgreSQL
kubectl exec -it -n {{NAMESPACE}} statefulset/postgres -- \
    psql -U {{DB_USER}} -d {{DB_NAME}}

# Dentro do psql:
# \dt              - Listar tabelas
# \d+ users        - Descrever tabela
# SELECT * FROM users;
# \q               - Sair
```

### 9.4 Rebuild e Redeploy Rápido

```bash
# 1. Fazer mudanças no código

# 2. Rebuild da imagem
docker build -t {{GITHUB_USER}}/{{GITHUB_REPO}}:latest .

# 3. Para Minikube, recarregar imagem
minikube image load {{GITHUB_USER}}/{{GITHUB_REPO}}:latest

# 4. Deletar pod atual (Kubernetes recriará com nova imagem)
kubectl delete pod -n {{NAMESPACE}} -l app=laravel-app

# 5. Aguardar novo pod ficar pronto
kubectl get pods -n {{NAMESPACE}} -w
```

### 9.5 Ver Recursos

```bash
# Ver uso de CPU/memória
kubectl top pods -n {{NAMESPACE}}
kubectl top nodes

# Ver todos os recursos
kubectl get all -n {{NAMESPACE}}

# Ver eventos
kubectl get events -n {{NAMESPACE}} --sort-by='.lastTimestamp'
```

### 9.6 Port Forward (acesso direto sem Ingress)

```bash
# Acessar aplicação diretamente na porta 8080 local
kubectl port-forward -n {{NAMESPACE}} deployment/app 8080:80

# Abrir: http://localhost:8080

# Acessar PostgreSQL diretamente
kubectl port-forward -n {{NAMESPACE}} statefulset/postgres 5432:5432

# Conectar com cliente SQL local: localhost:5432
```

---

## 🔧 Troubleshooting Local

### Problema: Imagem não encontrada (ImagePullBackOff)

```bash
# Verificar se a imagem existe localmente
docker images | grep {{GITHUB_REPO}}

# Rebuild da imagem
docker build -t {{GITHUB_USER}}/{{GITHUB_REPO}}:latest .

# Carregar imagem no Minikube
minikube image load {{GITHUB_USER}}/{{GITHUB_REPO}}:latest

# Deletar pod para forçar recriação
kubectl delete pod -n {{NAMESPACE}} -l app=laravel-app
```

### Problema: Ingress não responde

```bash
# Verificar se Ingress Controller está rodando
kubectl get pods -n ingress-nginx

# Para Minikube, verificar se tunnel está ativo
minikube tunnel

# Verificar /etc/hosts
cat /etc/hosts | grep {{DOMAIN}}

# Ver detalhes do Ingress
kubectl describe ingress -n {{NAMESPACE}} app-ingress
```

### Problema: Pods em CrashLoopBackOff

```bash
# Ver logs do pod
kubectl logs -n {{NAMESPACE}} -l app=laravel-app --previous

# Ver eventos
kubectl describe pod -n {{NAMESPACE}} -l app=laravel-app

# Causas comuns:
# - APP_KEY não configurada (verifique kubernetes/secrets.yaml)
# - Banco não acessível
# - Erro no código
```

---

## 🧹 Limpeza e Reset

### Deletar Aplicação

```bash
# Deletar todos os recursos do namespace
kubectl delete namespace {{NAMESPACE}}

# Ou deletar aplicando os arquivos com --delete
kubectl delete -f kubernetes/
```

### Resetar Kubernetes Local

```bash
# Parar Minikube
minikube stop

# Deletar cluster
minikube delete

# Reiniciar do zero
minikube start --driver=docker
minikube addons enable ingress
```

---

## 📊 Comparação: Local vs VPS

| Aspecto | Kubernetes Local | Kubernetes VPS |
|---------|------------------|----------------|
| **Infraestrutura** | Minikube (Linux) | kubeadm, containerd |
| **SSL** | Não necessário | cert-manager + Let's Encrypt |
| **DNS** | /etc/hosts | Provedor de DNS real |
| **Ingress** | Nginx (localhost) | Nginx (hostNetwork) |
| **Imagens** | Build local | Docker Hub/GHCR |
| **CI/CD** | Manual | GitHub Actions |
| **Custo** | Grátis | $5-50/mês (VPS) |
| **Performance** | Depende do PC | Dedicada |
| **Acesso** | Apenas local | Internet pública |

---

## 🚀 Próximos Passos

### 1. Desenvolva Localmente

- Teste features novas
- Debug com Xdebug
- Valide migrations
- Teste jobs e queues

### 2. Quando Estiver Pronto

- Siga o [DEPLOY_VPS.md](DEPLOY_VPS.md) para produção
- Use os mesmos arquivos YAML (apenas ajuste imagens e domínios)
- Configure CI/CD com GitHub Actions

### 3. Melhore o Ambiente Local

**Dashboard do Kubernetes:**

```bash
# Adicionar Dashboard
kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/v2.7.0/aio/deploy/recommended.yaml

# Acessar Dashboard
kubectl proxy
# Abrir: http://localhost:8001/api/v1/namespaces/kubernetes-dashboard/services/https:kubernetes-dashboard:/proxy/
```

**SSL Local (HTTPS) - Opcional:**

Para usar HTTPS localmente (https://plannerate.test):

```bash
# 1. Instalar mkcert (gera certificados SSL confiáveis localmente)
sudo apt install libnss3-tools
wget https://github.com/FiloSottile/mkcert/releases/download/v1.4.4/mkcert-v1.4.4-linux-amd64
sudo mv mkcert-v1.4.4-linux-amd64 /usr/local/bin/mkcert
sudo chmod +x /usr/local/bin/mkcert

# 2. Instalar CA local
mkcert -install

# 3. Gerar certificados para seus domínios
mkcert {{DOMAIN}} "*.{{DOMAIN}}"

# 4. Criar Secret com certificado
kubectl create secret tls {{NAMESPACE}}-tls \
  --cert={{DOMAIN}}+1.pem \
  --key={{DOMAIN}}+1-key.pem \
  -n {{NAMESPACE}}

# 5. Atualizar Ingress para usar TLS
kubectl edit ingress app-ingress -n {{NAMESPACE}}
# Adicionar:
# spec:
#   tls:
#   - hosts:
#     - {{DOMAIN}}
#     - admin.{{DOMAIN}}
#     secretName: {{NAMESPACE}}-tls
```

Agora acesse com HTTPS:
- https://{{DOMAIN}} ✅
- https://admin.{{DOMAIN}} ✅

---

## 📚 Recursos

- [Docker Engine](https://docs.docker.com/engine/install/ubuntu/)
- [Minikube](https://minikube.sigs.k8s.io/)
- [Kind (Kubernetes in Docker)](https://kind.sigs.k8s.io/)
- [k3d (k3s in Docker)](https://k3d.io/)
- [Kubernetes Dashboard](https://kubernetes.io/docs/tasks/access-application-cluster/web-ui-dashboard/)

---

## ✅ Checklist de Desenvolvimento Local

- [ ] Minikube instalado e rodando (`minikube status`)
- [ ] Kubernetes funcionando (`kubectl get nodes`)
- [ ] Nginx Ingress Controller instalado (`minikube addons enable ingress`)
- [ ] Repositório kubernetes-vps-setup clonado no projeto Laravel
- [ ] Script `setup.sh` executado com sucesso
- [ ] Arquivos gerados em `kubernetes/`, `docker/`, `.dev/`
- [ ] Imagem Docker construída (`docker build`)
- [ ] Imagem carregada no Minikube (`minikube image load`)
- [ ] Recursos aplicados no cluster (`kubectl apply -f kubernetes/`)
- [ ] Pods rodando (`kubectl get pods -n {{NAMESPACE}}`)
- [ ] /etc/hosts configurado (`127.0.0.1 {{DOMAIN}}`)
- [ ] Minikube tunnel ativo (`minikube tunnel`)
- [ ] Aplicação acessível no navegador
- [ ] Migrations executadas
- [ ] Banco de dados populado (seed)

---

**🎉 Pronto!** Agora você tem um ambiente Kubernetes local completo, gerado automaticamente!

**💡 Dica Final**: 
- Para **desenvolvimento rápido**: Use Docker Compose (pasta `.dev/`)
- Para **simular produção**: Use Kubernetes local (Minikube)
- Ambos foram gerados pelo mesmo `setup.sh`!
