# 🚀 Guia de Deploy: Laravel com Kubernetes em VPS

> 📘 **Guia Prático** - Deploy completo sem verbosidade excessiva
> 
> - 🚀 **Quer velocidade?** → [QUICK_START.md](QUICK_START.md) (30 minutos)
> - 📚 **Quer entender tudo?** → [DEPLOY_VPS_ADVANCED.md](DEPLOY_VPS_ADVANCED.md) (detalhes técnicos)

---

## 📋 O que você vai fazer

**PARTE 1 - VPS** (execute uma vez, reutilize sempre):
1. Configurar VPS e firewall
2. Instalar Docker + Kubernetes
3. Configurar Ingress Controller + cert-manager

**PARTE 2 - Laravel** (para cada projeto):
4. Gerar configs com `setup.sh`
5. Configurar GitHub Actions
6. Configurar DNS e SSL
7. Fazer deploy

---

# 📦 PARTE 1: Preparar VPS

> ⏱️ **Tempo**: ~40 minutos | **Execute uma vez**

## 1. Requisitos

- **VPS**: Ubuntu 22.04 LTS
- **Mínimo**: 4GB RAM, 2 CPUs, 40GB disco
- **Recomendado**: 8GB RAM, 4 CPUs, 80GB disco
- **IP público fixo**

## 2. Setup Inicial

```bash
# Conectar na VPS
ssh root@SEU_IP_VPS

# Atualizar sistema
apt update && apt upgrade -y

# Instalar ferramentas
apt install -y curl wget git nano net-tools htop

# Configurar firewall
apt install -y ufw
ufw allow 22/tcp      # SSH
ufw allow 80/tcp      # HTTP
ufw allow 443/tcp     # HTTPS
ufw allow 6443/tcp    # Kubernetes API
ufw allow 10250/tcp   # Kubelet
ufw --force enable
ufw status
```

## 3. Instalar Docker

```bash
# Remover versões antigas
apt remove -y docker docker-engine docker.io containerd runc 2>/dev/null || true

# Adicionar repositório
apt install -y ca-certificates curl gnupg lsb-release
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | \
    gpg --dearmor -o /etc/apt/keyrings/docker.gpg
chmod a+r /etc/apt/keyrings/docker.gpg

echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
    https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | \
    tee /etc/apt/sources.list.d/docker.list > /dev/null

# Instalar Docker
apt update
apt install -y docker-ce docker-ce-cli containerd.io \
    docker-buildx-plugin docker-compose-plugin

# Habilitar e iniciar
systemctl enable docker
systemctl start docker

# Testar
docker --version
docker run hello-world
```

## 4. Instalar Kubernetes

```bash
# Desabilitar swap (obrigatório)
swapoff -a
sed -i '/ swap / s/^/#/' /etc/fstab

# Configurar módulos do kernel
cat <<EOF | tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF

modprobe overlay
modprobe br_netfilter

# Configurar sysctl
cat <<EOF | tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF

sysctl --system

# Adicionar repositório Kubernetes
apt install -y apt-transport-https ca-certificates curl
mkdir -p /etc/apt/keyrings
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.28/deb/Release.key | \
    gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg

echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] \
    https://pkgs.k8s.io/core:/stable:/v1.28/deb/ /' | \
    tee /etc/apt/sources.list.d/kubernetes.list

# Instalar componentes
apt update
apt install -y kubelet kubeadm kubectl
apt-mark hold kubelet kubeadm kubectl

# Verificar
kubeadm version
kubectl version --client
kubelet --version
```

## 5. Inicializar Cluster

```bash
# Iniciar cluster (substitua SEU_IP_VPS)
kubeadm init \
  --pod-network-cidr=10.244.0.0/16 \
  --apiserver-advertise-address=SEU_IP_VPS \
  --node-name=k8s-laravel-cluster

# Configurar kubectl para root
mkdir -p $HOME/.kube
cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
chown $(id -u):$(id -g) $HOME/.kube/config

# Verificar
kubectl get nodes
# Deve mostrar: NotReady (normal, falta rede)

# Instalar rede Flannel
kubectl apply -f https://github.com/flannel-io/flannel/releases/latest/download/kube-flannel.yml

# Aguardar 30 segundos
sleep 30

# Permitir pods no master (single-node)
kubectl taint nodes --all node-role.kubernetes.io/control-plane-

# Verificar novamente (deve estar Ready agora)
kubectl get nodes
kubectl get pods -A
```

## 6. Instalar Ingress Controller

```bash
# Instalar Nginx Ingress
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.9.5/deploy/static/provider/cloud/deploy.yaml

# Aguardar ficar pronto
kubectl wait --namespace ingress-nginx \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/component=controller \
  --timeout=120s

# Configurar hostNetwork (usar portas 80/443 diretamente)
kubectl patch deployment ingress-nginx-controller \
  -n ingress-nginx \
  --type='json' \
  -p='[
    {"op": "add", "path": "/spec/template/spec/hostNetwork", "value": true},
    {"op": "add", "path": "/spec/template/spec/dnsPolicy", "value": "ClusterFirstWithHostNet"}
  ]'

# Verificar
kubectl get pods -n ingress-nginx
```

## 7. Instalar cert-manager (SSL)

```bash
# Instalar cert-manager
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.13.0/cert-manager.yaml

# Aguardar
kubectl wait --namespace cert-manager \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/instance=cert-manager \
  --timeout=120s

# Verificar
kubectl get pods -n cert-manager
```

## 8. Configurar kubectl Local (Seu Computador)

```bash
# Na VPS, copiar config
cat /etc/kubernetes/admin.conf

# No seu computador, criar arquivo
mkdir -p ~/.kube
nano ~/.kube/config
# Cole o conteúdo copiado

# Editar: trocar server: https://SEU_IP_VPS:6443
# (substituir IP interno pelo IP público da VPS)

# Testar
kubectl get nodes
# Deve mostrar o nó da VPS!
```

> ✅ **VPS pronta!** Agora você pode fazer deploy de múltiplos projetos Laravel.

---

# 🚢 PARTE 2: Deploy Laravel

> ⏱️ **Tempo**: ~20 minutos por projeto

## 9. Preparar Projeto Laravel

```bash
# Opção 1: Projeto existente
cd /caminho/para/seu-projeto

# Opção 2: Criar novo (com Docker, sem instalar PHP)
docker run --rm -v $(pwd):/app composer create-project laravel/laravel meu-projeto
cd meu-projeto

# Clonar repositório de setup
git clone https://github.com/SEU_USUARIO/kubernetes-vps-setup.git
cd kubernetes-vps-setup
```

## 10. Executar Setup

```bash
./setup.sh
```

**Perguntas importantes:**

```bash
📦 Nome do projeto: meu-app
🏢 Namespace: meu-app
🌐 Domínio: meuapp.com
🖥️  IP da VPS: SEU_IP_PUBLICO

🐙 Usuário/Organização GitHub: seu-usuario
💡 Nome do repositório: apenas o nome, SEM usuário/org!
   ✅ Correto: meu-app
   ❌ Errado: seu-usuario/meu-app
📦 Nome do repositório GitHub: meu-app

🔑 APP_KEY: [ENTER - gera automático]
📧 Email: admin@meuapp.com
🗄️  Banco: laravel
👤 Usuário: laravel
🔐 Senhas: [ENTER - gera automático]
☁️  Spaces: n

🔴 Reverb: [ENTER em todos - gera automático]

⭐ Perfil de Recursos:
  1) 🚀 Produção (2 réplicas, 512MB RAM)
  2) 🛠️  Dev (1 réplica, 256MB RAM)
  3) 🏢 Empresarial (3 réplicas, 1GB RAM)
  4) 🖥️  Local (Minikube) (1 réplica, 128MB RAM)
Escolha: 1
```

**Arquivos gerados:**
```
seu-projeto/
├── kubernetes/          # Manifests K8s
├── docker/             # Configs Docker
├── .github/workflows/  # CI/CD
├── Dockerfile          # Build produção
├── .dev/              # Dev local (Docker Compose)
└── docs/              # Documentação
```

## 11. Configurar GitHub Container Registry

> 📦 **GHCR**: Armazena imagens Docker gratuitamente

**11.1 Criar Personal Access Token:**

1. GitHub → Settings → Developer settings → Personal access tokens → Tokens (classic)
2. "Generate new token (classic)"
3. Nome: `ghcr-token`
4. Scopes: ✅ `write:packages`, ✅ `read:packages`, ✅ `delete:packages`
5. Generate → **Copiar token**

**11.2 Configurar Secrets no GitHub:**

```bash
# No projeto Laravel
cd ..  # Voltar para raiz do projeto

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
# Cole o conteúdo de ~/.kube/config (arquivo local)
```

**Ou via interface web:**
- Repositório → Settings → Secrets and variables → Actions
- New repository secret:
  - `GHCR_TOKEN`: seu token GHCR
  - `KUBE_CONFIG`: conteúdo de `~/.kube/config`

## 12. Configurar DNS

**No seu provedor de DNS (Cloudflare, GoDaddy, etc):**

```
Tipo    Nome    Valor
A       @       SEU_IP_VPS
A       *       SEU_IP_VPS
```

**Testar:**
```bash
# Aguardar 1-5 minutos para propagar
nslookup meuapp.com
ping meuapp.com
```

## 13. Fazer Deploy

**13.1 Push para GitHub (CI/CD automático):**

```bash
# Adicionar arquivos
git add .
git commit -m "Initial Kubernetes setup"
git push origin main

# GitHub Actions vai:
# - Build da imagem Docker
# - Push para GHCR
# - Deploy no Kubernetes
```

**Acompanhar deploy:**
- GitHub → Actions → Ver workflow rodando

**13.2 Ou fazer deploy manual:**

```bash
# Build e push da imagem
docker build -t seu-usuario/meu-app:latest .
docker tag seu-usuario/meu-app:latest ghcr.io/seu-usuario/meu-app:latest
docker push ghcr.io/seu-usuario/meu-app:latest

# Aplicar configs Kubernetes
kubectl apply -f kubernetes/

# Verificar
kubectl get pods -n meu-app
kubectl get ingress -n meu-app
```

## 14. Executar Migrations

```bash
# Via migration-job (automático)
kubectl apply -f kubernetes/migration-job.yaml

# Ou manualmente
kubectl exec -it -n meu-app deployment/app -- php artisan migrate --force

# Seeds (opcional)
kubectl exec -it -n meu-app deployment/app -- php artisan db:seed --force
```

## 15. Verificar SSL

```bash
# Ver certificado
kubectl get certificate -n meu-app
kubectl describe certificate -n meu-app app-tls

# Pode levar 2-5 minutos para emitir
# Status "Ready: True" = SSL funcionando!
```

**Acessar aplicação:**
```
https://meuapp.com
```

---

## 🔧 Troubleshooting

### Pods não iniciam (ImagePullBackOff)

```bash
# Verificar logs
kubectl describe pod -n meu-app -l app=laravel-app

# Recriar secret para GHCR
kubectl delete secret ghcr-secret -n meu-app
kubectl create secret docker-registry ghcr-secret \
  --docker-server=ghcr.io \
  --docker-username=SEU_USUARIO \
  --docker-password=SEU_TOKEN_GHCR \
  -n meu-app

# Reiniciar deploy
kubectl rollout restart deployment/app -n meu-app
```

### SSL não emite (cert-manager)

```bash
# Ver logs do cert-manager
kubectl logs -n cert-manager -l app=cert-manager

# Ver certificado
kubectl describe certificate -n meu-app app-tls
kubectl describe certificaterequest -n meu-app

# Deletar e recriar
kubectl delete certificate app-tls -n meu-app
kubectl apply -f kubernetes/ingress.yaml
```

### Aplicação em CrashLoopBackOff

```bash
# Ver logs
kubectl logs -n meu-app -l app=laravel-app --previous

# Causas comuns:
# - APP_KEY não configurada
# - Banco não acessível
# - Erro no código

# Acessar container
kubectl exec -it -n meu-app deployment/app -- bash
php artisan config:cache
php artisan migrate --force
exit
```

### Ver logs em tempo real

```bash
# Aplicação
kubectl logs -f -n meu-app deployment/app

# Todos os containers
kubectl logs -f -n meu-app deployment/app --all-containers=true

# PostgreSQL
kubectl logs -f -n meu-app statefulset/postgres

# Ingress
kubectl logs -f -n ingress-nginx -l app.kubernetes.io/component=controller
```

---

## 📊 Comandos Úteis

```bash
# Ver tudo no namespace
kubectl get all -n meu-app

# Ver recursos (CPU/RAM)
kubectl top pods -n meu-app
kubectl top nodes

# Escalar aplicação
kubectl scale deployment app -n meu-app --replicas=3

# Atualizar imagem (novo deploy)
kubectl set image deployment/app app=ghcr.io/usuario/app:v2 -n meu-app

# Rollback
kubectl rollout undo deployment/app -n meu-app

# Ver histórico
kubectl rollout history deployment/app -n meu-app

# Reiniciar pods
kubectl rollout restart deployment/app -n meu-app

# Deletar projeto completo
kubectl delete namespace meu-app
```

---

## 🎯 Próximos Passos

**Deploy de mais projetos:**
1. Clone novo projeto Laravel
2. Execute `setup.sh` novamente
3. Use namespace e domínio diferentes
4. Push para GitHub → deploy automático!

**Monitoramento:**
- Ver [DEPLOY_VPS_ADVANCED.md](DEPLOY_VPS_ADVANCED.md) para Prometheus + Grafana

**Backup:**
```bash
# Backup PostgreSQL
kubectl exec -n meu-app statefulset/postgres -- \
  pg_dump -U laravel laravel > backup.sql

# Restaurar
cat backup.sql | kubectl exec -i -n meu-app statefulset/postgres -- \
  psql -U laravel -d laravel
```

---

## ✅ Checklist

**PARTE 1 - VPS:**
- [ ] VPS criada e acessível via SSH
- [ ] Docker instalado e funcionando
- [ ] Kubernetes instalado (kubeadm, kubectl, kubelet)
- [ ] Cluster inicializado e nó "Ready"
- [ ] Ingress Controller instalado
- [ ] cert-manager instalado
- [ ] kubectl local configurado

**PARTE 2 - Laravel:**
- [ ] Projeto Laravel preparado
- [ ] `setup.sh` executado com sucesso
- [ ] GitHub Container Registry configurado
- [ ] Secrets do GitHub configurados (GHCR_TOKEN, KUBE_CONFIG)
- [ ] DNS apontando para VPS
- [ ] Push para GitHub feito
- [ ] Pods rodando (`kubectl get pods -n NAMESPACE`)
- [ ] Migrations executadas
- [ ] SSL emitido (certificado "Ready")
- [ ] Aplicação acessível via HTTPS

---

**🎉 Parabéns!** Sua aplicação Laravel está rodando em Kubernetes com SSL automático!

Para dúvidas ou problemas, consulte [TROUBLESHOOTING.md](TROUBLESHOOTING.md) ou [DEPLOY_VPS_ADVANCED.md](DEPLOY_VPS_ADVANCED.md).
