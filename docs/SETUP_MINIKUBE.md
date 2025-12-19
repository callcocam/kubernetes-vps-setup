# 💻 Configuração do Minikube para Desenvolvimento Local

> ⏱️ **Tempo**: ~20 minutos | **Execute uma vez no seu computador**
> 
> Este guia configura Minikube localmente. Depois você pode fazer deploy de **múltiplos projetos Laravel** no mesmo cluster.

---

## 📋 O que você vai fazer

1. Instalar Docker
2. Instalar kubectl
3. Instalar Minikube
4. Inicializar cluster Minikube
5. Instalar Nginx Ingress Controller
6. (Opcional) Instalar Metrics Server

---

## 1. Instalar Docker Engine (Linux)

```bash
# Atualizar sistema
sudo apt update

# Instalar dependências
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

---

## 2. Instalar kubectl

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

---

## 3. Instalar Minikube

```bash
# Baixar Minikube
curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64

# Instalar
sudo install minikube-linux-amd64 /usr/local/bin/minikube

# Verificar
minikube version
```

---

## 4. Iniciar Minikube

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

## 5. Instalar Nginx Ingress Controller

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

---

## 6. (Opcional) Instalar Metrics Server

> Para usar `kubectl top pods` e `kubectl top nodes`

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

# Testar (aguarde 1-2 minutos para métricas aparecerem)
sleep 60
kubectl top nodes
```

---

## 7. Verificar Instalação

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

---

## ✅ Minikube Pronto!

Seu ambiente de desenvolvimento Kubernetes está configurado!

**Próximos passos:**
- Para fazer deploy de um projeto: [DEPLOY_PROJECT.md](DEPLOY_PROJECT.md)

**Importante:**
- Esta configuração é feita **uma vez**
- Você pode fazer deploy de **múltiplos projetos** Laravel
- Cada projeto terá seu próprio namespace

---

## 🔧 Comandos Úteis do Minikube

```bash
# Parar Minikube
minikube stop

# Iniciar Minikube
minikube start

# Deletar cluster (remove tudo)
minikube delete

# Ver status
minikube status

# Abrir Dashboard
minikube dashboard

# Ver logs
minikube logs

# SSH no nó
minikube ssh

# Ver IP do Minikube
minikube ip

# Tunnel para acessar services
minikube tunnel
```

---

## 🧹 Limpeza

### Resetar Minikube Completamente

```bash
# Parar e deletar cluster (LIMPA TUDO)
minikube stop
minikube delete

# Reiniciar do zero
minikube start --driver=docker
minikube addons enable ingress

# Verificar que está limpo
kubectl get namespaces
kubectl get pods -A
```

### Limpar Imagens Antigas

```bash
# Ver imagens no Minikube
minikube image ls

# Limpar imagens não utilizadas
minikube image rm <nome-da-imagem>
```
