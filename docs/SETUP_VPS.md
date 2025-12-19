# 🖥️ Configuração da VPS para Kubernetes

> ⏱️ **Tempo**: ~40 minutos | **Execute uma vez por VPS**
> 
> Este guia configura a infraestrutura base. Depois você pode fazer deploy de **múltiplos projetos Laravel** nesta mesma VPS.

---

## 📋 O que você vai fazer

1. Configurar VPS e firewall
2. Instalar Docker
3. Instalar Kubernetes (kubeadm, kubectl, kubelet)
4. Inicializar cluster Kubernetes
5. Instalar Ingress Controller (Nginx)
6. Instalar cert-manager (SSL automático)
7. Configurar kubectl local

---

## 1. Requisitos

- **VPS**: Ubuntu 22.04 LTS (ou 24.04 LTS)
- **Mínimo**: 4GB RAM, 2 CPUs, 40GB disco
- **Recomendado**: 8GB RAM, 4 CPUs, 80GB disco
- **IP público fixo**

---

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

---

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

---

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

---

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

---

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

---

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

---

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

---

## 9. Criar Diretórios para Dados Persistentes

```bash
# Na VPS, criar diretórios base (você criará um por app depois)
mkdir -p /data/postgresql
mkdir -p /data/redis

# Ajustar permissões
chmod 755 /data
```

---

## ✅ VPS Pronta!

Sua VPS está configurada e pronta para receber projetos Laravel!

**Próximos passos:**
- Para fazer deploy de um projeto: [DEPLOY_PROJECT.md](DEPLOY_PROJECT.md)
- Para múltiplas apps na mesma VPS: [MULTIPLE_APPS.md](MULTIPLE_APPS.md)

**Importante:**
- Esta configuração é feita **uma vez**
- Você pode fazer deploy de **múltiplos projetos** Laravel
- Cada projeto terá seu próprio namespace, banco, domínio

---

## 🔧 Comandos Úteis

```bash
# Ver todos os namespaces
kubectl get namespaces

# Ver todos os pods de todos os namespaces
kubectl get pods -A

# Ver uso de recursos
kubectl top nodes
kubectl top pods -A

# Reiniciar Ingress Controller
kubectl rollout restart deployment ingress-nginx-controller -n ingress-nginx

# Ver certificados SSL
kubectl get certificates -A
```
