# 🚀 Deploy de Projetos Laravel com Kubernetes

> 📘 **Guia Unificado** - Deploy para **VPS (produção)** ou **Minikube (local)**
> 
> - 🖥️ **VPS não configurada?** → [SETUP_VPS.md](SETUP_VPS.md)
> - 💻 **Minikube não configurado?** → [SETUP_MINIKUBE.md](SETUP_MINIKUBE.md)
> - 🚀 **Quer velocidade?** → [QUICK_START.md](QUICK_START.md)

---

## 📋 O que você vai fazer

1. Preparar projeto Laravel
2. Executar `setup.sh` (gera configs automaticamente)
3. **VPS**: Configurar GitHub Actions + DNS + SSL
4. **Minikube**: Build local + ajustar deployment
5. Fazer deploy
6. Executar migrations

---

## 1. Preparar Projeto Laravel

### Opção A: Projeto Existente

```bash
cd /caminho/para/seu-projeto-laravel
```

### Opção B: Criar Novo (com Docker - sem instalar PHP)

```bash
# Criar projeto usando Docker
docker run --rm -v $(pwd):/app composer create-project laravel/laravel meu-projeto
cd meu-projeto
```

### Opção C: Criar Novo (com Composer instalado)

```bash
composer create-project laravel/laravel meu-projeto
cd meu-projeto
```

---

## 2. Clonar Repositório de Setup

```bash
# Dentro do diretório do projeto Laravel
git clone https://github.com/{{GITHUB_REPO}}.git kubernetes-vps-setup
cd kubernetes-vps-setup
```

---

## 3. Executar Setup

```bash
./setup.sh
```

### Perguntas do Setup

```bash
📦 Nome do projeto: {{PROJECT_NAME}}
🏢 Namespace: {{NAMESPACE}}
🌐 Domínio: {{DOMAIN}}  # Para produção (VPS)

💡 Para ambiente LOCAL (se escolher "Ambos"):
   Domínio local: {{PROJECT_NAME}}.test (gerado automaticamente)
   IP local: 127.0.0.1

🖥️  IP da VPS: {{VPS_IP}}

🐙 Usuário GitHub: {{GITHUB_USER}}
📦 Nome do repositório: {{GITHUB_REPO_NAME}}  # SEM usuário/org, apenas nome!

🔑 APP_KEY: [ENTER - gera automático]
📧 Email: {{APP_EMAIL}}
🗄️  Banco: {{DB_NAME}}
👤 Usuário: laravel
🔐 Senhas: [ENTER - gera automático]
☁️  Spaces: n

🔴 Reverb: [ENTER em todos - gera automático]

⭐ Perfil de Recursos:
  VPS Produção: 1) 🚀 Produção (2 réplicas, 512MB RAM)
  Minikube: 2) 💻 Local (1 réplica, 128MB RAM)
```

**Arquivos gerados:**
```
{{PROJECT_NAME}}/
├── kubernetes/          # Manifests K8s
├── docker/             # Configs Docker
├── .github/workflows/  # CI/CD
├── Dockerfile          # Build produção
├── .dev/              # Dev local (Docker Compose)
└── docs/              # Documentação
```

---

# 🖥️ DEPLOY EM VPS (PRODUÇÃO)

> ⏱️ **Tempo**: ~20 minutos por projeto
> 
> **Pré-requisito**: VPS configurada com [SETUP_VPS.md](SETUP_VPS.md)

## 4. Configurar GitHub Container Registry

### 4.1 Criar Personal Access Token

1. GitHub → Settings → Developer settings → Personal access tokens → Tokens (classic)
2. "Generate new token (classic)"
3. Nome: `ghcr-token`
4. Scopes: ✅ `write:packages`, ✅ `read:packages`, ✅ `delete:packages`
5. Generate → **Copiar token**

### 4.2 Configurar Secrets no GitHub

```bash
# No projeto Laravel (fora de kubernetes-vps-setup)
cd ..

# Instalar GitHub CLI (se não tiver)
curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | \
    sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] \
    https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list
sudo apt update && sudo apt install gh

# Autenticar
gh auth login

# Adicionar secrets
gh secret set GHCR_TOKEN
# Cole o token do GHCR

gh secret set KUBE_CONFIG
# Cole o conteúdo de ~/.kube/config
```

**Ou via interface web:**
- Repositório → Settings → Secrets and variables → Actions
- New repository secret:
  - `GHCR_TOKEN`: seu token GHCR
  - `KUBE_CONFIG`: conteúdo de `~/.kube/config`

---

## 5. Configurar DNS

**No seu provedor de DNS (Cloudflare, GoDaddy, etc):**

```
Tipo    Nome    Valor
A       @       SEU_IP_VPS
A       *       SEU_IP_VPS
```

**Testar:**
```bash
# Aguardar 1-5 minutos para propagar
nslookup {{DOMAIN}}
ping {{DOMAIN}}
```

---

## 6. Criar Diretórios de Dados na VPS

```bash
# Na VPS
ssh root@{{VPS_IP}}

# Criar diretórios para este projeto
mkdir -p /data/postgresql/{{NAMESPACE}}
mkdir -p /data/redis/{{NAMESPACE}}

# Ajustar permissões
chmod 700 /data/postgresql/{{NAMESPACE}}
chmod 755 /data/redis/{{NAMESPACE}}

exit
```

---

## 7. Fazer Deploy (GitHub Actions)

```bash
# Adicionar arquivos
git add .
git commit -m "Initial Kubernetes setup"
git push origin main

# GitHub Actions vai:
# - Build da imagem Docker
# - Push para ghcr.io
# - Deploy no Kubernetes
```

**Acompanhar deploy:**
- GitHub → Actions → Ver workflow rodando

---

## 8. Executar Migrations (VPS)

```bash
# Aguardar pods ficarem prontos
kubectl get pods -n {{NAMESPACE}}

# Via migration-job (recomendado)
kubectl apply -f kubernetes/migration-job.yaml

# Ou manualmente
kubectl exec -it -n {{NAMESPACE}} deployment/app -- php artisan migrate --force
```

---

## 9. Verificar SSL (VPS)

```bash
# Ver certificado (pode levar 2-5 minutos)
kubectl get certificate -n {{NAMESPACE}}
kubectl describe certificate -n {{NAMESPACE}} app-tls

# Status "Ready: True" = SSL funcionando!
```

**Acessar aplicação:**
```
https://{{DOMAIN}}
```

---

# 💻 DEPLOY LOCAL

Você tem **duas opções independentes** para testar localmente (escolha UMA):

1. **Docker Compose** → Mais simples, sem Kubernetes (apenas containers Docker)
2. **Minikube** → Ambiente idêntico à produção (cluster Kubernetes local)

**💡 As opções são alternativas, não sequenciais!** Você pode pular a Opção A e ir direto para a Opção B.

---

## Opção A: Docker Compose (Simples e Rápido)

> ⏱️ **Tempo**: ~5 minutos
> 
> **Pré-requisito**: Docker instalado

### 1. Acessar diretório .dev

```bash
# No projeto Laravel (fora de kubernetes-vps-setup)
cd ..
cd .dev
```

### 2. Inicializar ambiente

```bash
# Executar script de inicialização
./init.sh
```

**O que o init.sh faz:**
- ✅ Cria volumes Docker (PostgreSQL e Redis)
- ✅ Sobe containers (app, postgres, redis, nginx)
- ✅ Instala dependências Composer
- ✅ Gera APP_KEY
- ✅ Executa migrations
- ✅ Configura permissões

### 3. Acessar aplicação

```bash
# Aplicação estará disponível em:
http://localhost:8080
```

### 4. Comandos Úteis (Docker Compose)

```bash
# Ver logs
docker-compose logs -f app

# Acessar container
docker-compose exec app bash

# Executar migrations
docker-compose exec app php artisan migrate

# Parar ambiente
docker-compose down

# Parar e remover volumes (apaga dados)
docker-compose down -v
```

---

## Opção B: Minikube (Ambiente Kubernetes)

> ⏱️ **Tempo**: ~15 minutos
> 
> **Pré-requisito**: Minikube configurado com [SETUP_MINIKUBE.md](SETUP_MINIKUBE.md)

### 4. Build da Imagem Docker

```bash
# No diretório do projeto (fora de kubernetes-vps-setup)
cd ..

# Build usando Dockerfile gerado
docker build -t {{GITHUB_REPO}}:latest .

# Verificar imagem
docker images | grep {{GITHUB_REPO_NAME}}
```

---

## 5. Carregar Imagem no Minikube

```bash
# Carregar imagem no cluster Minikube
minikube image load {{GITHUB_REPO}}:latest

# Verificar
minikube image ls | grep {{GITHUB_REPO_NAME}}
```

---

## 6. Ajustar Deployment para Minikube

> ✅ **PRONTO**: O `setup.sh` já gerou os arquivos corretos em `.dev/kubernetes/` (sem ghcr.io/)!

**Use os arquivos `.dev/kubernetes/` para Minikube** - eles já têm as imagens locais configuradas:

```bash
# Conferir que as imagens estão corretas (SEM ghcr.io/)
grep "image:" .dev/kubernetes/deployment.yaml | head -1
# Deve mostrar: image: {{GITHUB_REPO}}:latest

grep "image:" .dev/kubernetes/migration-job.yaml | head -1
# Deve mostrar: image: {{GITHUB_REPO}}:latest
```

**Por quê dois diretórios?**
- **`kubernetes/`** → Produção (com `ghcr.io/`) - **VAI PRO GIT** ✅
- **`.dev/kubernetes/`** → Minikube (sem `ghcr.io/`) - **NÃO VAI PRO GIT** ❌

Assim você pode testar localmente sem risco de quebrar produção!

---

## 7. Aplicar Configurações (Minikube)

**⚠️ IMPORTANTE**: Use os arquivos de `.dev/kubernetes/` para Minikube!

```bash
# Aplicar namespace, secrets, configmap
kubectl apply -f .dev/kubernetes/namespace.yaml
kubectl apply -f .dev/kubernetes/secrets.yaml
kubectl apply -f .dev/kubernetes/configmap.yaml

# Aplicar PostgreSQL e Redis
kubectl apply -f .dev/kubernetes/postgres.yaml
kubectl apply -f .dev/kubernetes/redis.yaml

# Aguardar databases ficarem Ready
kubectl wait --for=condition=ready pod -l app=postgres -n {{NAMESPACE}} --timeout=120s
kubectl wait --for=condition=ready pod -l app=redis -n {{NAMESPACE}} --timeout=120s

# Aplicar aplicação e serviços
kubectl apply -f .dev/kubernetes/deployment.yaml
kubectl apply -f .dev/kubernetes/service.yaml
kubectl apply -f .dev/kubernetes/ingress.yaml

# NÃO aplicar cert-issuer.yaml (só para produção com SSL)
```

**Por quê .dev/kubernetes/?**
- `.dev/kubernetes/` → Imagens locais (ex: `{{GITHUB_REPO}}:latest`)
- `kubernetes/` → Imagens GHCR (ex: `ghcr.io/{{GITHUB_REPO}}:latest`)
- O diretório `.dev/` não vai pro Git, garantindo que você pode testar localmente **sem quebrar produção**!

---

## 8. Executar Migrations (Minikube)

```bash
# Aplicar migration-job (usar .dev/kubernetes/)
kubectl apply -f .dev/kubernetes/migration-job.yaml

# Acompanhar logs
kubectl logs -f job/migration -n {{NAMESPACE}}
```

---

## 9. Configurar Acesso Local

### 9.1 Editar /etc/hosts

```bash
# Editar arquivo
sudo nano /etc/hosts

# Adicionar linha (usar o domínio gerado: PROJETO.test)
127.0.0.1 {{PROJECT_NAME}}.test

# Salvar: Ctrl+O, Enter, Ctrl+X
```

**💡 Dica**: O `setup.sh` gera automaticamente `PROJETO.test` como domínio local.

### 9.2 Iniciar Minikube Tunnel

```bash
# Em um terminal separado, deixar rodando
minikube tunnel
```

### 9.3 Acessar no Navegador

```bash
# Abrir navegador em (usar o domínio gerado):
http://{{PROJECT_NAME}}.test
```

**💡 Se escolheu "Ambos" no setup.sh**:
- Produção (VPS): `https://{{DOMAIN}}`
- Local (Minikube): `http://{{PROJECT_NAME}}.test`

---

## 🔧 Troubleshooting

### VPS: Pods não iniciam (ImagePullBackOff)

```bash
# Verificar logs
kubectl describe pod -n {{NAMESPACE}} -l app=laravel-app

# Recriar secret para GHCR
kubectl delete secret ghcr-secret -n {{NAMESPACE}}
kubectl create secret docker-registry ghcr-secret \
  --docker-server=ghcr.io \
  --docker-username={{GITHUB_USER}} \
  --docker-password=SEU_TOKEN_GHCR \
  -n {{NAMESPACE}}

# Reiniciar
kubectl rollout restart deployment/app -n {{NAMESPACE}}
```

### VPS: SSL não emite

```bash
# Ver logs do cert-manager
kubectl logs -n cert-manager -l app=cert-manager

# Ver certificado
kubectl describe certificate -n {{NAMESPACE}} app-tls

# Deletar e recriar
kubectl delete certificate app-tls -n {{NAMESPACE}}
kubectl apply -f kubernetes/ingress.yaml
```

### Minikube: Imagem não encontrada

```bash
# Verificar se existe localmente
docker images | grep {{GITHUB_REPO_NAME}}

# Rebuild
docker build -t {{GITHUB_REPO}}:latest .

# Recarregar no Minikube
minikube image load {{GITHUB_REPO}}:latest

# Reiniciar pod
kubectl delete pod -n {{NAMESPACE}} -l app=laravel-app
```

### Minikube: Ingress não responde

```bash
# Verificar Ingress Controller
kubectl get pods -n ingress-nginx

# Verificar tunnel está ativo
minikube tunnel

# Verificar /etc/hosts (usar domínio gerado: PROJETO.test)
cat /etc/hosts | grep {{PROJECT_NAME}}.test
```

### CrashLoopBackOff (VPS ou Minikube)

```bash
# Ver logs
kubectl logs -n {{NAMESPACE}} -l app=laravel-app --previous

# Causas comuns:
# - APP_KEY não configurada
# - Banco não acessível
# - Erro no código

# Acessar container
kubectl exec -it -n {{NAMESPACE}} deployment/app -- bash
php artisan config:cache
php artisan migrate --force
exit
```

---

## 📊 Comandos Úteis

```bash
# Ver tudo no namespace
kubectl get all -n {{NAMESPACE}}

# Ver recursos (CPU/RAM)
kubectl top pods -n {{NAMESPACE}}
kubectl top nodes

# Ver logs em tempo real
kubectl logs -f -n {{NAMESPACE}} deployment/app

# Escalar aplicação
kubectl scale deployment app -n {{NAMESPACE}} --replicas=3

# Reiniciar pods
kubectl rollout restart deployment/app -n {{NAMESPACE}}

# Executar comandos Artisan
kubectl exec -it -n {{NAMESPACE}} deployment/app -- php artisan tinker

# Acessar PostgreSQL
kubectl exec -it -n {{NAMESPACE}} statefulset/postgres -- psql -U {{DB_USER}} -d {{DB_NAME}}

# Deletar projeto completo
kubectl delete namespace {{NAMESPACE}}
```

---

## 🔄 Atualizar Projeto Existente

### VPS (Automático - GitHub Actions)

```bash
# Fazer mudanças no código
git add .
git commit -m "Nova feature"
git push origin main

# GitHub Actions faz deploy automático!
```

### Minikube (Manual)

```bash
# 1. Rebuild da imagem
docker build -t {{GITHUB_REPO}}:latest .

# 2. Recarregar no Minikube
minikube image load {{GITHUB_REPO}}:latest

# 3. Reiniciar pods
kubectl delete pod -n {{NAMESPACE}} -l app=laravel-app

# 4. Aguardar
kubectl get pods -n {{NAMESPACE}} -w
```

---

## 🧹 Limpeza

### Deletar Um Projeto

```bash
# Deletar namespace completo (remove TUDO)
kubectl delete namespace {{NAMESPACE}}
```

### Minikube: Deletar Múltiplos Projetos

```bash
# Deletar vários namespaces
kubectl delete namespace projeto1 projeto2 projeto3

# Ver o que sobrou
kubectl get namespaces
```

---

## ✅ Checklist

**Ambos (VPS e Minikube):**
- [ ] Infraestrutura configurada (VPS ou Minikube)
- [ ] Projeto Laravel preparado
- [ ] `setup.sh` executado
- [ ] Arquivos gerados em `kubernetes/`

**Apenas VPS:**
- [ ] GitHub Container Registry configurado
- [ ] Secrets do GitHub (GHCR_TOKEN, KUBE_CONFIG)
- [ ] DNS apontando para VPS
- [ ] Push para GitHub feito
- [ ] Diretórios `/data/postgresql/APP` e `/data/redis/APP` criados na VPS
- [ ] SSL emitido

**Apenas Minikube:**
- [ ] Imagem Docker construída
- [ ] Imagem carregada no Minikube
- [ ] `deployment.yaml` e `migration-job.yaml` ajustados (sem `ghcr.io/`)
- [ ] `/etc/hosts` configurado
- [ ] `minikube tunnel` rodando

**Ambos:**
- [ ] Pods rodando (`kubectl get pods -n NAMESPACE`)
- [ ] Migrations executadas
- [ ] Aplicação acessível

---

**🎉 Pronto!** Seu projeto Laravel está rodando em Kubernetes!

**Próximos passos:**
- Deploy de mais projetos: Repetir este guia com novo namespace/domínio
- Múltiplas apps: Ver [MULTIPLE_APPS.md](MULTIPLE_APPS.md)
- Troubleshooting: Ver [TROUBLESHOOTING.md](TROUBLESHOOTING.md)
