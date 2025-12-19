Você está certo! O documento está com problemas de formatação. Vou corrigir:

**Principais problemas encontrados:**

1. **Seção 5** - Bloco de código não fechado corretamente
2. **Seção 8.1** aparece antes da seção 8 (ordem errada)
3. Faltam fechamentos de blocos markdown

Aqui está a versão corrigida:

```markdown
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

# Configurar containerd ANTES de instalar Kubernetes (IMPORTANTE!)
systemctl stop containerd
rm -f /etc/containerd/config.toml
containerd config default > /etc/containerd/config.toml

# Habilitar systemd cgroup (necessário para Kubernetes)
sed -i 's/SystemdCgroup = false/SystemdCgroup = true/g' /etc/containerd/config.toml

# Reiniciar containerd
systemctl restart containerd
systemctl enable containerd

# Configurar crictl
cat > /etc/crictl.yaml <<EOF
runtime-endpoint: unix:///run/containerd/containerd.sock
image-endpoint: unix:///run/containerd/containerd.sock
timeout: 2
EOF

# Instalar crictl (baixar binário)
CRICTL_VERSION=v1.28.0
curl -L \
  https://github.com/kubernetes-sigs/cri-tools/releases/download/${CRICTL_VERSION}/crictl-${CRICTL_VERSION}-linux-amd64.tar.gz \
  -o /tmp/crictl.tar.gz
tar -zxvf /tmp/crictl.tar.gz -C /usr/local/bin
chmod +x /usr/local/bin/crictl
rm -f /tmp/crictl.tar.gz

# Verificar se containerd está funcionando
crictl version
crictl ps
# Deve retornar lista vazia (sem erros)

# Adicionar repositório Kubernetes
apt install -y apt-transport-https ca-certificates curl
mkdir -p /etc/apt/keyrings
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.28/deb/Release.key | \
    gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg

echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.28/deb/ /" | \
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
# ⚠️ IMPORTANTE: Substitua SEU_IP_VPS_AQUI pelo IP público da sua VPS!

kubeadm init \
  --pod-network-cidr=10.244.0.0/16 \
  --apiserver-advertise-address=SEU_IP_VPS_AQUI \
  --node-name=k8s-laravel-cluster

# Aguarde aparecer: "Your Kubernetes control-plane has initialized successfully!"

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
# Todos os pods devem estar Running
```

### 5.1 Troubleshooting (CRI/containerd)

Se aparecer erro semelhante a: "unknown service runtime.v1.RuntimeService" ou o `crictl` não funcionar:

```bash
# 1) Reconfigurar containerd com cgroup systemd
systemctl stop kubelet containerd
rm -f /etc/containerd/config.toml
containerd config default > /etc/containerd/config.toml
sed -i 's/SystemdCgroup = false/SystemdCgroup = true/g' /etc/containerd/config.toml
systemctl restart containerd
systemctl enable containerd

# 2) Instalar e configurar crictl (se não instalou antes)
CRICTL_VERSION=v1.28.0
curl -L \
  https://github.com/kubernetes-sigs/cri-tools/releases/download/${CRICTL_VERSION}/crictl-${CRICTL_VERSION}-linux-amd64.tar.gz \
  -o /tmp/crictl.tar.gz
tar -zxvf /tmp/crictl.tar.gz -C /usr/local/bin
chmod +x /usr/local/bin/crictl
rm -f /tmp/crictl.tar.gz

cat > /etc/crictl.yaml <<EOF
runtime-endpoint: unix:///run/containerd/containerd.sock
image-endpoint: unix:///run/containerd/containerd.sock
timeout: 2
EOF

crictl ps  # Deve funcionar (lista vazia)

# 3) Resetar kubeadm e inicializar novamente
kubeadm reset -f
kubeadm init \
  --pod-network-cidr=10.244.0.0/16 \
  --apiserver-advertise-address=SEU_IP_VPS_AQUI \
  --node-name=k8s-laravel-cluster
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

### 8.1 Opção A: Substituir contexto atual (apenas VPS)

```bash
# Na VPS, copiar config
cat /etc/kubernetes/admin.conf

# No seu computador, criar/substituir arquivo
mkdir -p ~/.kube
nano ~/.kube/config
# Cole o conteúdo copiado

# Editar: trocar server para usar IP público
# Encontre: server: https://10.0.0.1:6443 (ou similar)
# Substitua: server: https://SEU_IP_VPS:6443

# Testar
kubectl get nodes
# Deve mostrar o nó da VPS!
```

### 8.2 Opção B: Manter múltiplos clusters (Minikube + VPS) - RECOMENDADO

```bash
# 1. Fazer backup do seu config atual
cp ~/.kube/config ~/.kube/config.backup

# 2. Na VPS, copiar o admin.conf
ssh root@SEU_IP_VPS 'cat /etc/kubernetes/admin.conf' > ~/.kube/config-vps

# 3. Editar o config-vps e mudar o server IP
# Substitua o IP interno pelo IP público da VPS
sed -i 's|server: https://[0-9.]*:6443|server: https://SEU_IP_VPS:6443|g' ~/.kube/config-vps

# 4. Mesclar os contextos
KUBECONFIG=$HOME/.kube/config:$HOME/.kube/config-vps \
  kubectl config view --merge --flatten > $HOME/.kube/config-merged

# 5. Substituir o config
mv $HOME/.kube/config-merged $HOME/.kube/config
chmod 600 ~/.kube/config

# 6. Renomear o contexto da VPS para algo mais amigável
kubectl config rename-context kubernetes-admin@kubernetes vps-laravel 2>/dev/null || true

# 7. Ver todos os contextos disponíveis
kubectl config get-contexts

# 8. Alternar entre contextos
kubectl config use-context minikube    # Para usar Minikube
kubectl config use-context vps-laravel # Para usar VPS

# Ver contexto atual
kubectl config current-context
```

### 8.3 Aliases úteis (opcional)

```bash
# Adicionar ao ~/.bashrc ou ~/.zshrc
cat >> ~/.bashrc << 'EOF'

# Aliases kubectl
alias k='kubectl'
alias kc='kubectl config use-context'
alias kgc='kubectl config get-contexts'
alias kctx='kubectl config current-context'
EOF

# Recarregar shell
source ~/.bashrc  # ou: source ~/.zshrc

# Testar
k get nodes
kctx
kgc
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

# Ver logs de um pod
kubectl logs -f POD_NAME -n NAMESPACE

# Entrar em um pod
kubectl exec -it POD_NAME -n NAMESPACE -- bash
```
```

**Principais correções:**

1. ✅ Fechado bloco de código da seção 5
2. ✅ Movido seção 8.1 para dentro da seção 8
3. ✅ Adicionado seção 8.3 para aliases
4. ✅ Melhorado comandos de mesclagem de contextos
5. ✅ Adicionado mais comandos úteis
6. ✅ Corrigido formatação markdown

Agora está organizado e funcional! 🚀