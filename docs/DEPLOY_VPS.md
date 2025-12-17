# 🚀 Guia de Deploy: Laravel com Docker e Kubernetes em VPS

> 📘 **Versão Simplificada** - Para detalhes técnicos completos, veja [DEPLOY_VPS_ADVANCED.md](DEPLOY_VPS_ADVANCED.md)

Este guia está dividido em **duas partes principais**:

- **PARTE 1**: Configuração da VPS (faça uma vez, reutilize sempre)
- **PARTE 2**: Deploy de Projetos Laravel (use para cada novo projeto)

> 💡 **Para Iniciantes**: Kubernetes (K8s) é uma plataforma que automatiza o deploy, escalonamento e gerenciamento de aplicações em containers. Pense nele como um "maestro" que coordena todos os componentes da sua aplicação.
> 
> 🎯 **Quer algo mais rápido?** Veja [QUICK_START.md](QUICK_START.md) - Deploy em 30 minutos!

---

## 📋 Índice

### PARTE 1: Preparação da VPS (Execute Uma Vez)
1. [Configuração Inicial da VPS](#parte-1-preparação-da-vps)
2. [Instalação do Docker](#2-instalação-do-docker)
3. [Instalação do Kubernetes](#3-instalação-do-kubernetes)
4. [Configuração do Cluster Kubernetes](#4-configuração-do-cluster-kubernetes)
5. [Instalação de Componentes Essenciais](#5-instalação-de-componentes-essenciais)
6. [Configuração do kubectl Local](#6-configuração-do-kubectl-local)

### PARTE 2: Deploy de Projetos Laravel (Para Cada Projeto)
7. [Preparação do Projeto Laravel](#parte-2-deploy-de-projetos-laravel)
8. [Configuração de Arquivos Kubernetes](#8-configuração-de-arquivos-kubernetes)
9. [Deploy com GitHub Actions](#9-deploy-com-github-actions)
10. [Configuração de DNS e SSL](#10-configuração-de-dns-e-ssl)
11. [Verificação e Troubleshooting](#11-verificação-e-troubleshooting)

---

# 📦 PARTE 1: Preparação da VPS

> ⚠️ **IMPORTANTE**: Faça esta parte apenas uma vez. Depois você poderá fazer deploy de vários projetos Laravel na mesma VPS.

## 1. Configuração Inicial da VPS

### 1.1 Requisitos Mínimos

> 📊 **Recomendações de Hardware**:
> - Para **1-2 projetos pequenos**: 4GB RAM, 2 CPUs, 40GB disco
> - Para **3-5 projetos médios**: 8GB RAM, 4 CPUs, 80GB disco
> - Para **produção com tráfego alto**: 16GB+ RAM, 8+ CPUs, 160GB+ disco

| Requisito | Mínimo | Recomendado |
|-----------|--------|-------------|
| Sistema Operacional | Ubuntu 20.04 LTS | Ubuntu 22.04 LTS |
| RAM | 4GB | 8GB ou mais |
| CPU | 2 cores | 4 cores ou mais |
| Disco | 40GB | 80GB ou mais |
| Rede | IP público fixo | IP público fixo |

### 1.2 Acesso Inicial à VPS

```bash
# Conectar via SSH (substitua SEU_IP_VPS pelo IP real)
ssh root@SEU_IP_VPS

# Atualizar todos os pacotes do sistema
apt update && apt upgrade -y

# Instalar ferramentas essenciais
apt install -y curl wget git nano vim net-tools htop
```

> 💡 **Dica**: Se preferir um editor mais simples que o vim, use `nano` nos comandos seguintes.

### 1.3 Configurar Firewall (UFW)

> 🔒 **Segurança**: O firewall protege sua VPS bloqueando portas não autorizadas.

```bash
# Instalar UFW (Uncomplicated Firewall)
apt install -y ufw

# Configurar regras básicas
ufw allow 22/tcp      # SSH - Para você acessar a VPS
ufw allow 80/tcp      # HTTP - Para aplicações web
ufw allow 443/tcp     # HTTPS - Para aplicações web seguras
ufw allow 6443/tcp    # Kubernetes API - Para gerenciamento do cluster
ufw allow 10250/tcp   # Kubelet API - Para comunicação interna do K8s

# Ativar firewall (--force evita a confirmação)
ufw --force enable

# Verificar status e regras
ufw status verbose
```

**Saída esperada:**
```
Status: active
To                         Action      From
--                         ------      ----
22/tcp                     ALLOW       Anywhere
80/tcp                     ALLOW       Anywhere
443/tcp                    ALLOW       Anywhere
6443/tcp                   ALLOW       Anywhere
10250/tcp                  ALLOW       Anywhere
```

### 1.4 Configurar Hostname (Opcional mas Recomendado)

```bash
# Definir um nome amigável para sua VPS
hostnamectl set-hostname k8s-laravel-cluster

# Adicionar ao arquivo hosts
echo "127.0.0.1 k8s-laravel-cluster" >> /etc/hosts

# Verificar
hostname
```

## 2. Instalação do Docker

> 🐳 **O que é Docker?**: Docker cria "containers" - pacotes isolados que contêm tudo que sua aplicação precisa para rodar (código, dependências, configurações).

### 2.1 Remover Versões Antigas (se existirem)

```bash
# Limpar instalações antigas do Docker
apt remove -y docker docker-engine docker.io containerd runc 2>/dev/null || true
```

### 2.2 Instalar Docker Engine

```bash
# Passo 1: Instalar dependências
apt install -y \
    ca-certificates \
    curl \
    gnupg \
    lsb-release

# Passo 2: Adicionar chave GPG oficial do Docker
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | \
    gpg --dearmor -o /etc/apt/keyrings/docker.gpg
chmod a+r /etc/apt/keyrings/docker.gpg

# Passo 3: Adicionar repositório do Docker
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
  https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | \
  tee /etc/apt/sources.list.d/docker.list > /dev/null

# Passo 4: Instalar Docker Engine e plugins
apt update
apt install -y docker-ce docker-ce-cli containerd.io \
    docker-buildx-plugin docker-compose-plugin

# Passo 5: Verificar instalação
docker --version
```

**Saída esperada:**
```
Docker version 24.0.x, build xxxxxxx
```

### 2.3 Testar Docker

```bash
# Executar container de teste
docker run hello-world
```

**Se ver "Hello from Docker!", a instalação foi bem-sucedida! 🎉**

### 2.4 Configurar Docker para Iniciar Automaticamente

```bash
# Habilitar Docker para iniciar com o sistema
systemctl enable docker
systemctl start docker

# Verificar status
systemctl status docker
```

**Saída esperada (deve mostrar "active (running)"):**
```
● docker.service - Docker Application Container Engine
     Loaded: loaded (/lib/systemd/system/docker.service; enabled)
     Active: active (running) since ...
```

Pressione `q` para sair da visualização.

## 3. Instalação do Kubernetes

> ☸️ **O que é Kubernetes?**: É um orquestrador de containers que gerencia, escala e mantém suas aplicações rodando de forma automatizada.

### 3.1 Preparar o Sistema para Kubernetes

> ⚙️ **Por que estas configurações?**: 
> - **Swap**: Kubernetes desativa swap para garantir performance previsível
> - **Módulos do kernel**: Necessários para networking de containers
> - **Parâmetros sysctl**: Permitem comunicação entre containers

```bash
# Passo 1: Desabilitar swap (obrigatório para Kubernetes)
swapoff -a

# Passo 2: Desabilitar swap permanentemente
sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab

# Passo 3: Configurar módulos do kernel necessários
cat <<EOF | tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF

# Passo 4: Carregar módulos agora (sem reiniciar)
modprobe overlay
modprobe br_netfilter

# Passo 5: Configurar parâmetros de rede para Kubernetes
cat <<EOF | tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF

# Passo 6: Aplicar configurações imediatamente
sysctl --system

# Passo 7: Verificar se módulos foram carregados
lsmod | grep br_netfilter
lsmod | grep overlay
```

**Saída esperada (deve mostrar os módulos):**
```
br_netfilter           32768  0
bridge                307200  1 br_netfilter
overlay               151552  0
```

### 3.2 Instalar Componentes do Kubernetes

> 📦 **Componentes que serão instalados**:
> - **kubeadm**: Ferramenta para criar e gerenciar o cluster
> - **kubelet**: Agente que roda em cada nó e gerencia containers
> - **kubectl**: CLI para interagir com o cluster (você usará bastante!)

```bash
# Passo 1: Instalar dependências
apt update
apt install -y apt-transport-https ca-certificates curl gpg

# Passo 2: Adicionar chave GPG do Kubernetes
# Criando diretório se não existir
mkdir -p -m 755 /etc/apt/keyrings

curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.28/deb/Release.key | \
    gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg

# Passo 3: Adicionar repositório do Kubernetes
echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.28/deb/ /' | \
    tee /etc/apt/sources.list.d/kubernetes.list

# Passo 4: Instalar kubelet, kubeadm e kubectl
apt update
apt install -y kubelet kubeadm kubectl

# Passo 5: Impedir atualizações automáticas (manter versão estável)
apt-mark hold kubelet kubeadm kubectl

# Passo 6: Verificar instalação
kubeadm version
kubectl version --client
```

**Saída esperada:**
```
kubeadm version: &version.Info{Major:"1", Minor:"28"...}
Client Version: v1.28.x
```

### 3.3 Configurar containerd (Runtime de Containers)

> 🔧 **containerd**: É o runtime que realmente executa os containers no Kubernetes.

```bash
# Passo 1: Gerar configuração padrão do containerd
mkdir -p /etc/containerd
containerd config default | tee /etc/containerd/config.toml

# Passo 2: Configurar cgroup driver para systemd (recomendado)
# Isso garante compatibilidade com o systemd do Ubuntu
sed -i 's/SystemdCgroup = false/SystemdCgroup = true/' /etc/containerd/config.toml

# Passo 3: Reiniciar containerd para aplicar mudanças
systemctl restart containerd
systemctl enable containerd

# Passo 4: Verificar status
systemctl status containerd
```

**Saída esperada (deve mostrar "active (running)"):**
```
● containerd.service - containerd container runtime
     Active: active (running) since ...
```

Pressione `q` para sair.

## 4. Configuração do Cluster Kubernetes

> 🎯 **Agora vem a parte importante**: Vamos criar o cluster Kubernetes que hospedará seus projetos Laravel!

### 4.1 Inicializar o Cluster (Nó Master)

> ⚠️ **ATENÇÃO**: Substitua `SEU_IP_VPS` pelo IP público da sua VPS!

```bash
# Inicializar cluster Kubernetes
# O pod-network-cidr é a faixa de IPs para comunicação interna dos pods
kubeadm init \
    --pod-network-cidr=10.244.0.0/16 \
    --apiserver-advertise-address=SEU_IP_VPS

# ⏰ Aguarde... Este processo pode levar 2-5 minutos
```

> 💾 **IMPORTANTE**: Após a inicialização, você verá uma mensagem com um comando `kubeadm join`. 
> **SALVE ESTE COMANDO!** Você precisará dele se quiser adicionar mais nós ao cluster no futuro.

**Exemplo da mensagem de sucesso:**
```
Your Kubernetes control-plane has initialized successfully!

To start using your cluster, you need to run the following as a regular user:

  mkdir -p $HOME/.kube
  sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
  sudo chown $(id -u):$(id -g) $HOME/.kube/config

Then you can join any number of worker nodes by running the following on each:

kubeadm join SEU_IP_VPS:6443 --token abc123.xyz789 \
    --discovery-token-ca-cert-hash sha256:...
```

### 4.2 Configurar kubectl para Acesso ao Cluster

```bash
# Criar diretório de configuração do kubectl
mkdir -p $HOME/.kube

# Copiar arquivo de configuração do cluster
cp -i /etc/kubernetes/admin.conf $HOME/.kube/config

# Definir permissões corretas
chown $(id -u):$(id -g) $HOME/.kube/config

# Testar acesso ao cluster
kubectl get nodes
```

**Saída esperada:**
```
NAME                STATUS     ROLES           AGE   VERSION
k8s-laravel-cluster NotReady   control-plane   1m    v1.28.x
```

> 📝 **Nota**: O status "NotReady" é normal neste momento. Vamos corrigir isso no próximo passo instalando o plugin de rede!

### 4.3 Instalar Plugin de Rede (Flannel CNI)

> 🌐 **CNI (Container Network Interface)**: Permite que os pods se comuniquem entre si. Estamos usando o Flannel, que é simples e confiável.

```bash
# Instalar Flannel para networking entre pods
kubectl apply -f https://github.com/flannel-io/flannel/releases/latest/download/kube-flannel.yml

# Aguardar todos os pods do sistema ficarem prontos (pode levar 1-2 minutos)
echo "Aguardando pods do sistema ficarem prontos..."
kubectl wait --for=condition=ready pod --all -n kube-system --timeout=300s

# Verificar status dos pods do sistema
kubectl get pods -n kube-system
```

**Saída esperada (todos os pods devem estar "Running"):**
```
NAME                                      READY   STATUS    RESTARTS   AGE
coredns-xxx                               1/1     Running   0          5m
coredns-yyy                               1/1     Running   0          5m
etcd-k8s-laravel-cluster                  1/1     Running   0          5m
kube-apiserver-k8s-laravel-cluster        1/1     Running   0          5m
kube-controller-manager-k8s-laravel-...   1/1     Running   0          5m
kube-flannel-ds-xxx                       1/1     Running   0          2m
kube-proxy-xxx                            1/1     Running   0          5m
kube-scheduler-k8s-laravel-cluster        1/1     Running   0          5m
```

### 4.4 Permitir Pods no Nó Master (Configuração Single-Node)

> 🔓 **Single-Node**: Como estamos usando apenas um servidor VPS, precisamos permitir que aplicações rodem no nó master (normalmente isso não é feito em produção com múltiplos nós).

```bash
# Remover "taint" do master node para permitir execução de pods
kubectl taint nodes --all node-role.kubernetes.io/control-plane-

# Verificar nó novamente - agora deve estar "Ready"
kubectl get nodes
```

**Saída esperada:**
```
NAME                  STATUS   ROLES           AGE   VERSION
k8s-laravel-cluster   Ready    control-plane   5m    v1.28.x
```

> ✅ **Parabéns!** Seu cluster Kubernetes está funcionando! 🎉

## 5. Instalação de Componentes Essenciais

> 🛠️ **Componentes que vamos instalar**:
> - **Ingress Controller**: "Porteiro" que gerencia o tráfego HTTP/HTTPS externo
> - **cert-manager**: Cria e renova certificados SSL automaticamente (HTTPS grátis!)

### 5.1 Instalar Nginx Ingress Controller

> 🚪 **Ingress Controller**: Pense nele como um reverse proxy inteligente que roteia requisições HTTP(S) para seus pods com base no domínio/URL.

```bash
# Instalar Nginx Ingress Controller
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.9.5/deploy/static/provider/cloud/deploy.yaml

# Aguardar deployment estar pronto (pode levar 1-2 minutos)
echo "Aguardando Ingress Controller ficar pronto..."
kubectl wait --namespace ingress-nginx \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/component=controller \
  --timeout=120s

# Verificar instalação
kubectl get pods -n ingress-nginx
```

**Saída esperada:**
```
NAME                                        READY   STATUS    RESTARTS   AGE
ingress-nginx-controller-xxx                1/1     Running   0          2m
```

### 5.2 Configurar Ingress para Usar Portas Diretamente no Host

> 🔌 **hostNetwork**: Isso faz o Ingress Controller usar as portas 80 e 443 diretamente no servidor, sem precisar de LoadBalancer externo.

```bash
# Aplicar patch para usar hostNetwork (importante para VPS single-node)
kubectl patch deployment ingress-nginx-controller \
  -n ingress-nginx \
  --type='json' \
  -p='[
    {
      "op": "add",
      "path": "/spec/template/spec/hostNetwork",
      "value": true
    },
    {
      "op": "add",
      "path": "/spec/template/spec/dnsPolicy",
      "value": "ClusterFirstWithHostNet"
    }
  ]'

# Aguardar pods reiniciarem
echo "Aguardando pods reiniciarem com nova configuração..."
sleep 10

# Verificar se está rodando corretamente
kubectl get pods -n ingress-nginx
```

### 5.3 Instalar cert-manager (SSL Automático)

> 🔐 **cert-manager**: Integra com Let's Encrypt para gerar certificados SSL gratuitos e renová-los automaticamente!

```bash
# Instalar cert-manager
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.13.0/cert-manager.yaml

# Aguardar pods ficarem prontos
echo "Aguardando cert-manager ficar pronto..."
kubectl wait --namespace cert-manager \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/instance=cert-manager \
  --timeout=120s

# Verificar instalação
kubectl get pods -n cert-manager
```

**Saída esperada (3 pods rodando):**
```
NAME                                       READY   STATUS    RESTARTS   AGE
cert-manager-xxx                           1/1     Running   0          2m
cert-manager-cainjector-xxx                1/1     Running   0          2m
cert-manager-webhook-xxx                   1/1     Running   0          2m
```

### 5.4 Verificação Final da Infraestrutura

```bash
# Verificar todos os namespaces
kubectl get pods --all-namespaces

# Verificar nós do cluster
kubectl get nodes

# Verificar serviços
kubectl get svc --all-namespaces
```

> ✅ **Checkpoint**: Se todos os pods estão "Running" e o nó está "Ready", sua infraestrutura está pronta! 🎊

## 6. Configuração do kubectl Local

> 💻 **kubectl Local**: Permite gerenciar seu cluster Kubernetes do seu computador local, sem precisar fazer SSH na VPS toda hora!

### 6.1 Instalar kubectl no Seu Computador Local

**No Ubuntu/Debian (seu computador local):**

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

**No macOS:**

```bash
# Usando Homebrew
brew install kubectl

# Verificar instalação
kubectl version --client
```

**No Windows:**

```powershell
# Usando Chocolatey
choco install kubernetes-cli

# Ou baixar manualmente de:
# https://kubernetes.io/docs/tasks/tools/install-kubectl-windows/
```

### 6.2 Copiar Configuração do Cluster

**Na sua VPS (via SSH):**

```bash
# Exibir configuração do cluster
cat /etc/kubernetes/admin.conf
```

**No seu computador local:**

```bash
# Criar diretório de configuração
mkdir -p ~/.kube

# Criar/editar arquivo de config
nano ~/.kube/config

# Cole o conteúdo do admin.conf aqui
# ⚠️ IMPORTANTE: Substitua o IP interno pelo IP público da VPS!
# Procure por: server: https://10.x.x.x:6443
# Substitua por: server: https://SEU_IP_VPS:6443

# Salvar: Ctrl+O, Enter, Ctrl+X

# Definir permissões corretas
chmod 600 ~/.kube/config

# Testar conexão
kubectl get nodes
```

**Saída esperada:**
```
NAME                  STATUS   ROLES           AGE   VERSION
k8s-laravel-cluster   Ready    control-plane   20m   v1.28.x
```

> ✅ **Pronto!** Agora você pode gerenciar seu cluster de qualquer lugar! 🌍

---

# 🚢 PARTE 2: Deploy de Projetos Laravel

> 🎯 **Esta parte você fará para cada projeto Laravel** que quiser hospedar no cluster.
> 
> 💡 **Pré-requisito**: A VPS deve estar com a Parte 1 completa.

## 7. Preparação do Projeto Laravel

### 7.1 Estrutura de Arquivos Kubernetes

Primeiro, vamos criar uma pasta `kubernetes/` no seu projeto Laravel com todos os arquivos de configuração necessários.

```bash
# No diretório raiz do seu projeto Laravel
mkdir -p kubernetes

# Criar arquivos de configuração
touch kubernetes/namespace.yaml
touch kubernetes/secrets.yaml
touch kubernetes/configmap.yaml
touch kubernetes/postgres.yaml
touch kubernetes/redis.yaml
touch kubernetes/deployment.yaml
touch kubernetes/service.yaml
touch kubernetes/ingress.yaml
touch kubernetes/cert-issuer.yaml
touch kubernetes/migration-job.yaml
```

### 7.2 Dockerfile para Laravel

> 🐳 **Dockerfile**: Define como sua aplicação Laravel será empacotada em um container.

Crie um arquivo `Dockerfile` na raiz do projeto:

```dockerfile
# Dockerfile
FROM php:8.4-fpm-alpine

# Instalar dependências do sistema
RUN apk add --no-cache \
    nginx \
    supervisor \
    postgresql-dev \
    libpng-dev \
    libjpeg-turbo-dev \
    freetype-dev \
    zip \
    unzip \
    git \
    curl \
    nodejs \
    npm

# Instalar extensões PHP
RUN docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install -j$(nproc) \
        pdo \
        pdo_pgsql \
        gd \
        pcntl \
        bcmath \
        opcache

# Instalar Redis extension
RUN apk add --no-cache $PHPIZE_DEPS \
    && pecl install redis \
    && docker-php-ext-enable redis

# Instalar Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# Configurar diretório de trabalho
WORKDIR /var/www/html

# Copiar arquivos de dependências primeiro (cache Docker)
COPY composer.json composer.lock ./
RUN composer install --no-dev --no-scripts --no-autoloader --prefer-dist

# Copiar package.json para instalar dependências Node
COPY package*.json ./
RUN npm ci

# Copiar resto da aplicação
COPY . .

# Finalizar instalação Composer
RUN composer dump-autoload --optimize

# Build dos assets com Vite
RUN npm run build

# Configurar Nginx
COPY docker/nginx/default.conf /etc/nginx/http.d/default.conf

# Configurar Supervisor
COPY docker/supervisor/supervisord.conf /etc/supervisor/conf.d/supervisord.conf

# Configurar permissões
RUN chown -R www-data:www-data /var/www/html/storage /var/www/html/bootstrap/cache \
    && chmod -R 775 /var/www/html/storage /var/www/html/bootstrap/cache

# Expor porta
EXPOSE 80

# Iniciar Supervisor (gerencia Nginx + PHP-FPM + Queue Workers)
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]
```

### 7.3 Configuração do Nginx

Crie o arquivo `docker/nginx/default.conf`:

```nginx
server {
    listen 80;
    server_name _;
    root /var/www/html/public;
    index index.php index.html;

    charset utf-8;

    location / {
        try_files $uri $uri/ /index.php?$query_string;
    }

    location = /favicon.ico { access_log off; log_not_found off; }
    location = /robots.txt  { access_log off; log_not_found off; }

    error_page 404 /index.php;

    location ~ \.php$ {
        fastcgi_pass 127.0.0.1:9000;
        fastcgi_param SCRIPT_FILENAME $realpath_root$fastcgi_script_name;
        include fastcgi_params;
    }

    location ~ /\.(?!well-known).* {
        deny all;
    }
}
```

### 7.4 Configuração do Supervisor

Crie o arquivo `docker/supervisor/supervisord.conf`:

```ini
[supervisord]
nodaemon=true
user=root
logfile=/var/log/supervisor/supervisord.log
pidfile=/var/run/supervisord.pid

[program:php-fpm]
command=php-fpm -F
autostart=true
autorestart=true
stdout_logfile=/dev/stdout
stdout_logfile_maxbytes=0
stderr_logfile=/dev/stderr
stderr_logfile_maxbytes=0

[program:nginx]
command=nginx -g 'daemon off;'
autostart=true
autorestart=true
stdout_logfile=/dev/stdout
stdout_logfile_maxbytes=0
stderr_logfile=/dev/stderr
stderr_logfile_maxbytes=0

[program:laravel-worker]
process_name=%(program_name)s_%(process_num)02d
command=php /var/www/html/artisan queue:work --sleep=3 --tries=3 --max-time=3600
autostart=true
autorestart=true
stopasgroup=true
killasgroup=true
numprocs=2
user=www-data
stdout_logfile=/dev/stdout
stdout_logfile_maxbytes=0
stderr_logfile=/dev/stderr
stderr_logfile_maxbytes=0
stopwaitsecs=3600
```

### 7.5 Arquivo .dockerignore

Crie `.dockerignore` na raiz do projeto:

```
.git
.github
.env
.env.*
node_modules
vendor
storage/logs/*
storage/framework/cache/*
storage/framework/sessions/*
storage/framework/views/*
tests
.phpunit.result.cache
.editorconfig
.gitignore
.gitattributes
README.md
```

> ✅ **Checkpoint**: Estrutura básica do projeto pronta para containerização!

## 8. Configuração de Arquivos Kubernetes

> ✨ **Use o script automatizado para gerar todos os arquivos!**

Em vez de criar manualmente cada arquivo YAML, use o script de configuração interativo:

```bash
# No diretório do projeto (onde está o setup.sh)
cd kubernetes-vps-setup
./setup.sh
```

**O script irá:**
1. ✅ Solicitar informações do projeto (nome, domínio, email, etc.)
2. ✅ Gerar automaticamente **15 arquivos** prontos para uso
3. ✅ Criar senhas seguras para PostgreSQL e Redis
4. ✅ Configurar volumes persistentes
5. ✅ Preparar Dockerfile e configurações Nginx/Supervisor
6. ✅ Criar workflow do GitHub Actions para CI/CD

**Arquivos gerados:**

| Categoria | Arquivos |
|-----------|----------|
| **Kubernetes** | `namespace.yaml`, `secrets.yaml`, `configmap.yaml`, `postgres.yaml`, `redis.yaml`, `deployment.yaml`, `service.yaml`, `ingress.yaml`, `cert-issuer.yaml`, `migration-job.yaml` |
| **Docker** | `Dockerfile`, `.dockerignore`, `nginx/default.conf`, `supervisor/supervisord.conf` |
| **CI/CD** | `.github/workflows/deploy.yml` |

> 📖 **Quer entender cada arquivo em detalhes?** Veja [DEPLOY_VPS_ADVANCED.md](DEPLOY_VPS_ADVANCED.md#8-configuração-dos-arquivos-kubernetes)  
> 📁 **Estrutura completa de arquivos:** [FILE_STRUCTURE.md](FILE_STRUCTURE.md)

### 8.1 Executar o Script de Configuração

```bash
./setup.sh
```

**Exemplo de interação:**

```
🚀 Configurador de Deploy Kubernetes para Laravel

📝 Configuração do Projeto
━━━━━━━━━━━━━━━━━━━━━━━━━━

Nome do projeto (ex: meu-app): minha-api
Domínio (ex: app.exemplo.com): api.meusite.com
Seu email (para SSL): contato@meusite.com

📊 Banco de Dados PostgreSQL
━━━━━━━━━━━━━━━━━━━━━━━━━━

Nome do banco (padrão: minha_api): 
Usuário (padrão: minha_api_user): 
Senha (deixe vazio para gerar automaticamente): 
✅ Senha gerada: kR9#mP2$xL5...

[... continua ...]

✅ Configuração concluída!

📁 Arquivos criados em: /caminho/completo/generated/
```

### 8.2 Aplicar Configurações no Cluster

Após gerar os arquivos, aplique-os no Kubernetes:

```bash
# Navegar para o diretório gerado
cd generated

# 1. Criar namespace
kubectl apply -f k8s/namespace.yaml

# 2. Aplicar secrets e configmap
kubectl apply -f k8s/secrets.yaml
kubectl apply -f k8s/configmap.yaml

# 3. Criar certificado SSL
kubectl apply -f k8s/cert-issuer.yaml

# 4. Deploy do banco de dados
kubectl apply -f k8s/postgres.yaml

# 5. Deploy do Redis
kubectl apply -f k8s/redis.yaml

# 6. Deploy da aplicação (após build da imagem Docker - ver Passo 9)
kubectl apply -f k8s/deployment.yaml
kubectl apply -f k8s/service.yaml
kubectl apply -f k8s/ingress.yaml

# 7. Executar migrations (após tudo estar rodando)
kubectl apply -f k8s/migration-job.yaml
```

**Ou aplique tudo de uma vez (após ter a imagem Docker):**

```bash
kubectl apply -f k8s/
```

### 8.3 Verificar Status

```bash
# Ver todos os recursos no namespace
kubectl get all -n minha-api

# Verificar pods
kubectl get pods -n minha-api

# Ver logs de um pod
kubectl logs -f -n minha-api <nome-do-pod>

# Ver certificado SSL
kubectl get certificate -n minha-api
```

> ✅ **Arquivos Kubernetes configurados!** Próximo: criar a imagem Docker.

## 9. Deploy com GitHub Actions

> 🤖 **GitHub Actions**: Automatiza o build da imagem Docker e deploy no Kubernetes sempre que você fizer push no GitHub!

### 9.1 Criar Conta e Token no Docker Hub

> 🐳 **Docker Hub**: Repositório onde armazenaremos as imagens Docker.

1. **Criar conta**: https://hub.docker.com/signup
2. **Criar Access Token**:
   - Acesse: https://hub.docker.com/settings/security
   - Clique em "New Access Token"
   - Nome: `github-actions`
   - Permissões: **Read, Write, Delete**
   - Clique em "Generate"
   - **📋 COPIE O TOKEN** (não será mostrado novamente!)

### 9.2 Configurar GitHub Secrets

> 🔑 **GitHub Secrets**: Armazena credenciais de forma segura para uso no CI/CD.

**Via GitHub CLI (recomendado):**

```bash
# No seu computador local, dentro do projeto
cd /caminho/para/seu-projeto-laravel

# Instalar GitHub CLI (Ubuntu/Debian)
curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | \
    sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] \
    https://cli.github.com/packages stable main" | \
    sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
sudo apt update
sudo apt install gh

# Autenticar com GitHub
gh auth login

# Adicionar secrets (cole os valores quando solicitado)
gh secret set DOCKER_HUB_USERNAME
# Digite seu username do Docker Hub

gh secret set DOCKER_HUB_TOKEN
# Cole o token copiado anteriormente

gh secret set APP_KEY
# Cole a APP_KEY gerada com: php artisan key:generate --show
```

**Configurar KUBECONFIG Secret:**

```bash
# Na VPS, copiar configuração do Kubernetes
cat /etc/kubernetes/admin.conf

# No seu computador local:
# 1. Criar arquivo temporário
nano /tmp/kubeconfig.yaml

# 2. Colar o conteúdo do admin.conf
# 3. ⚠️ IMPORTANTE: Substituir o IP interno pelo IP público da VPS
#    Procurar por: server: https://10.x.x.x:6443
#    Substituir por: server: https://SEU_IP_VPS:6443

# 4. Salvar (Ctrl+O, Enter, Ctrl+X)

# 5. Adicionar como secret
gh secret set KUBECONFIG < /tmp/kubeconfig.yaml

# 6. Remover arquivo temporário
rm /tmp/kubeconfig.yaml

# 7. Verificar secrets criados
gh secret list
```

**Via Interface Web (alternativa):**

1. Acesse: `https://github.com/seu-usuario/seu-repo/settings/secrets/actions`
2. Clique em "New repository secret"
3. Adicione cada secret:
   - `DOCKER_HUB_USERNAME`
   - `DOCKER_HUB_TOKEN`
   - `APP_KEY`
   - `KUBECONFIG` (cole o conteúdo do arquivo modificado)

### 9.3 Criar Workflow do GitHub Actions

Crie o arquivo `.github/workflows/deploy.yml`:

```yaml
name: Build and Deploy

on:
  push:
    branches:
      - main  # Ou master, dependendo do seu branch principal
  workflow_dispatch:  # Permite executar manualmente

env:
  DOCKER_IMAGE: ${{ secrets.DOCKER_HUB_USERNAME }}/meu-projeto  # ⚠️ Ajuste o nome
  NAMESPACE: meu-projeto  # ⚠️ Mesmo nome do namespace Kubernetes

jobs:
  build-and-push:
    name: Build Docker Image
    runs-on: ubuntu-latest
    
    steps:
    - name: Checkout Code
      uses: actions/checkout@v4
      
    - name: Set up Docker Buildx
      uses: docker/setup-buildx-action@v3
      
    - name: Login to Docker Hub
      uses: docker/login-action@v3
      with:
        username: ${{ secrets.DOCKER_HUB_USERNAME }}
        password: ${{ secrets.DOCKER_HUB_TOKEN }}
        
    - name: Build and Push Docker Image
      uses: docker/build-push-action@v5
      with:
        context: .
        push: true
        tags: |
          ${{ env.DOCKER_IMAGE }}:latest
          ${{ env.DOCKER_IMAGE }}:${{ github.sha }}
        cache-from: type=registry,ref=${{ env.DOCKER_IMAGE }}:buildcache
        cache-to: type=registry,ref=${{ env.DOCKER_IMAGE }}:buildcache,mode=max

  deploy:
    name: Deploy to Kubernetes
    needs: build-and-push
    runs-on: ubuntu-latest
    
    steps:
    - name: Checkout Code
      uses: actions/checkout@v4
      
    - name: Setup kubectl
      uses: azure/setup-kubectl@v3
      with:
        version: 'v1.28.0'
        
    - name: Configure kubectl
      run: |
        mkdir -p $HOME/.kube
        echo "${{ secrets.KUBECONFIG }}" > $HOME/.kube/config
        chmod 600 $HOME/.kube/config
        
    - name: Verify Cluster Connection
      run: kubectl get nodes
      
    - name: Create Namespace (if not exists)
      run: kubectl create namespace ${{ env.NAMESPACE }} --dry-run=client -o yaml | kubectl apply -f -
      
    - name: Apply Kubernetes Configurations
      run: |
        # Aplicar secrets e configmaps
        kubectl apply -f kubernetes/secrets.yaml
        kubectl apply -f kubernetes/configmap.yaml
        
        # Aplicar cert-issuer
        kubectl apply -f kubernetes/cert-issuer.yaml
        
        # Aplicar databases
        kubectl apply -f kubernetes/postgres.yaml
        kubectl apply -f kubernetes/redis.yaml
        
        # Aguardar databases estarem prontos
        kubectl wait --for=condition=ready pod -l app=postgres -n ${{ env.NAMESPACE }} --timeout=120s || true
        kubectl wait --for=condition=ready pod -l app=redis -n ${{ env.NAMESPACE }} --timeout=120s || true
        
        # Aplicar aplicação
        kubectl apply -f kubernetes/deployment.yaml
        kubectl apply -f kubernetes/service.yaml
        kubectl apply -f kubernetes/ingress.yaml
        
    - name: Update Deployment Image
      run: |
        kubectl set image deployment/app \
          app=${{ env.DOCKER_IMAGE }}:${{ github.sha }} \
          -n ${{ env.NAMESPACE }}
          
    - name: Wait for Deployment Rollout
      run: kubectl rollout status deployment/app -n ${{ env.NAMESPACE }} --timeout=5m
      
    - name: Run Migrations
      run: kubectl apply -f kubernetes/migration-job.yaml
      
    - name: Get Deployment Status
      run: |
        echo "=== Pods ==="
        kubectl get pods -n ${{ env.NAMESPACE }}
        echo ""
        echo "=== Services ==="
        kubectl get svc -n ${{ env.NAMESPACE }}
        echo ""
        echo "=== Ingress ==="
        kubectl get ingress -n ${{ env.NAMESPACE }}
```

### 9.4 Fazer o Primeiro Deploy

```bash
# No seu computador local, dentro do projeto

# 1. Adicionar todos os arquivos
git add .

# 2. Commit
git commit -m "feat: Adicionar configuração Kubernetes e CI/CD"

# 3. Push para trigger o GitHub Actions
git push origin main  # ou master

# 4. Acompanhar execução
gh run watch

# Ou ver no browser:
# https://github.com/seu-usuario/seu-repo/actions
```

### 9.5 Verificar Deploy

**No seu computador local (com kubectl configurado):**

```bash
# Ver pods
kubectl get pods -n meu-projeto

# Ver logs da aplicação
kubectl logs -f deployment/app -n meu-projeto

# Ver status do ingress
kubectl get ingress -n meu-projeto

# Ver certificado SSL
kubectl get certificate -n meu-projeto
```

**Saída esperada (após alguns minutos):**

```bash
# Pods rodando
NAME                   READY   STATUS    RESTARTS   AGE
app-xxx                1/1     Running   0          2m
postgres-0             1/1     Running   0          5m
redis-0                1/1     Running   0          5m

# Certificado pronto
NAME      READY   SECRET    AGE
app-tls   True    app-tls   3m
```

> ✅ **Deploy automatizado configurado!** 🎉
> 
> Agora, sempre que você fizer `git push`, sua aplicação será automaticamente atualizada no Kubernetes!

## 10. Configuração de DNS e SSL

> 🌐 **DNS**: Aponta seu domínio para a VPS. 🔒 **SSL**: Criptografa a comunicação (HTTPS).

### 10.1 Configurar DNS

**No seu provedor de DNS** (Cloudflare, DigitalOcean, Namecheap, etc.):

| Tipo | Nome/Host | Valor | TTL |
|------|-----------|-------|-----|
| A | @ | SEU_IP_VPS | 3600 |
| A | www | SEU_IP_VPS | 3600 |
| A | * | SEU_IP_VPS | 3600 |

> 💡 **Explicação**:
> - `@` = domínio raiz (exemplo.com)
> - `www` = subdomínio www (www.exemplo.com)
> - `*` = wildcard para todos os subdomínios (api.exemplo.com, admin.exemplo.com, etc.)

**Exemplo de configuração no Cloudflare:**

```
Type: A
Name: @
IPv4 address: 203.0.113.10 (seu IP VPS)
Proxy status: DNS only (nuvem cinza)
TTL: Auto

Type: A
Name: *
IPv4 address: 203.0.113.10 (seu IP VPS)
Proxy status: DNS only (nuvem cinza)
TTL: Auto
```

> ⏰ **Aguarde propagação DNS**: Pode levar de 5 minutos a 48 horas (geralmente 5-30 minutos).

**Verificar propagação DNS:**

```bash
# No seu computador local
dig meuapp.seudominio.com

# Ou usar online: https://dnschecker.org/
```

### 10.2 Verificar Certificado SSL

> 🔐 **O cert-manager criará o certificado automaticamente** quando o DNS estiver configurado corretamente.

```bash
# Verificar certificados
kubectl get certificate -n meu-projeto

# Ver detalhes do certificado
kubectl describe certificate app-tls -n meu-projeto

# Ver certificate request
kubectl get certificaterequest -n meu-projeto

# Ver challenges do Let's Encrypt
kubectl get challenges -n meu-projeto
```

**Status esperado (certificado pronto):**

```
NAME      READY   SECRET    AGE
app-tls   True    app-tls   5m
```

**Se READY = False, ver logs:**

```bash
# Ver logs do cert-manager
kubectl logs -n cert-manager -l app=cert-manager

# Ver eventos do namespace
kubectl get events -n meu-projeto --sort-by='.lastTimestamp'
```

### 10.3 Testar Aplicação

```bash
# Testar HTTP (deve redirecionar para HTTPS)
curl -I http://meuapp.seudominio.com

# Testar HTTPS
curl -I https://meuapp.seudominio.com

# Ou abrir no navegador
https://meuapp.seudominio.com
```

> ✅ **Se abriu no navegador com cadeado verde, tudo funcionou!** 🎉

---

## 11. Verificação e Troubleshooting

### 11.1 Comandos Essenciais de Verificação

> 🔍 **Use estes comandos para verificar o estado da sua aplicação**:

```bash
# Ver todos os pods do projeto
kubectl get pods -n meu-projeto

# Ver logs de um pod específico
kubectl logs POD_NAME -n meu-projeto

# Ver logs em tempo real
kubectl logs -f deployment/app -n meu-projeto

# Ver todos os recursos do namespace
kubectl get all -n meu-projeto

# Ver eventos recentes (muito útil para debug!)
kubectl get events -n meu-projeto --sort-by='.lastTimestamp'

# Ver detalhes de um pod
kubectl describe pod POD_NAME -n meu-projeto

# Executar comando dentro de um pod
kubectl exec -it POD_NAME -n meu-projeto -- bash

# Ver status do deployment
kubectl rollout status deployment/app -n meu-projeto
```

### 11.2 Problemas Comuns e Soluções

#### 🔴 Problema: Pods em estado "ImagePullBackOff"

**Causa**: Kubernetes não consegue baixar a imagem Docker.

```bash
# Verificar erro detalhado
kubectl describe pod POD_NAME -n meu-projeto
```

**Soluções**:

```bash
# 1. Verificar se a imagem existe no Docker Hub
# Acessar: https://hub.docker.com/r/seu-usuario/seu-projeto/tags

# 2. Verificar se GitHub Actions executou com sucesso
gh run list

# 3. Re-trigger do build
git commit --allow-empty -m "Trigger rebuild"
git push origin main

# 4. Verificar se o nome da imagem está correto no deployment.yaml
kubectl get deployment app -n meu-projeto -o yaml | grep image:
```

#### 🔴 Problema: Pods em estado "CrashLoopBackOff"

**Causa**: A aplicação está iniciando mas crashando logo em seguida.

```bash
# Ver logs do pod que crashou
kubectl logs POD_NAME -n meu-projeto --previous

# Ver logs atuais
kubectl logs POD_NAME -n meu-projeto
```

**Causas Comuns**:

1. **APP_KEY não configurada**:
   ```bash
   # Verificar secrets
   kubectl get secret app-secrets -n meu-projeto -o yaml
   
   # Se APP_KEY estiver vazia, gerar nova:
   php artisan key:generate --show
   # Atualizar kubernetes/secrets.yaml e aplicar:
   kubectl apply -f kubernetes/secrets.yaml
   ```

2. **Banco de dados não acessível**:
   ```bash
   # Verificar se PostgreSQL está rodando
   kubectl get pods -l app=postgres -n meu-projeto
   
   # Testar conexão do pod da app
   kubectl exec -it deployment/app -n meu-projeto -- \
     php artisan tinker --execute="DB::connection()->getPdo();"
   ```

3. **Migrations não executadas**:
   ```bash
   # Executar migrations manualmente
   kubectl exec -it deployment/app -n meu-projeto -- \
     php artisan migrate --force
   
   # Ou usar o job:
   kubectl apply -f kubernetes/migration-job.yaml
   ```

4. **Erro no código**:
   ```bash
   # Ver detalhes do erro nos logs
   kubectl logs deployment/app -n meu-projeto | grep "ERROR"
   ```

#### 🔴 Problema: Ingress não responde (erro 502/504)

**Causa**: Ingress Controller não está roteando corretamente.

```bash
# 1. Verificar se Ingress Controller está rodando
kubectl get pods -n ingress-nginx

# 2. Ver logs do Ingress Controller
kubectl logs -n ingress-nginx -l app.kubernetes.io/component=controller

# 3. Verificar configuração do Ingress
kubectl describe ingress app-ingress -n meu-projeto

# 4. Testar localmente na VPS
ssh root@SEU_IP_VPS
curl -I http://localhost
curl -I https://localhost -k

# 5. Verificar se o Service está correto
kubectl get svc -n meu-projeto
kubectl get endpoints -n meu-projeto
```

**Soluções**:

```bash
# Reiniciar Ingress Controller
kubectl rollout restart deployment/ingress-nginx-controller -n ingress-nginx

# Verificar firewall
ufw status

# Deve ter as portas 80 e 443 abertas
ufw allow 80/tcp
ufw allow 443/tcp
```

#### 🔴 Problema: Certificado SSL não criado

**Causa**: cert-manager não conseguiu validar o domínio.

```bash
# 1. Verificar certificado
kubectl get certificate -n meu-projeto
kubectl describe certificate app-tls -n meu-projeto

# 2. Verificar challenges
kubectl get challenges -n meu-projeto
kubectl describe challenge CHALLENGE_NAME -n meu-projeto

# 3. Ver logs do cert-manager
kubectl logs -n cert-manager -l app=cert-manager
```

**Causas Comuns**:

1. **DNS não configurado corretamente**:
   ```bash
   # Testar resolução DNS
   dig meuapp.seudominio.com
   
   # Deve apontar para o IP da VPS
   ```

2. **Porta 80 não acessível** (Let's Encrypt precisa validar via HTTP):
   ```bash
   # Testar da internet
   curl -I http://meuapp.seudominio.com/.well-known/acme-challenge/test
   
   # Verificar firewall
   ufw status | grep 80
   ```

3. **Email inválido no issuer**:
   ```bash
   # Verificar issuer
   kubectl describe clusterissuer letsencrypt-prod
   
   # Atualizar kubernetes/cert-issuer.yaml se necessário
   kubectl apply -f kubernetes/cert-issuer.yaml
   ```

**Forçar nova tentativa de certificado**:

```bash
# Deletar certificado e ingress
kubectl delete certificate app-tls -n meu-projeto
kubectl delete ingress app-ingress -n meu-projeto

# Aguardar 30 segundos
sleep 30

# Reaplicar ingress (que recriará o certificado)
kubectl apply -f kubernetes/ingress.yaml

# Acompanhar criação
kubectl get certificate -n meu-projeto -w
```

#### 🔴 Problema: Aplicação lenta ou sem recursos

**Causa**: Falta de recursos (CPU/memória).

```bash
# Ver uso de recursos dos nós
kubectl top nodes

# Ver uso de recursos dos pods
kubectl top pods -n meu-projeto
```

**Soluções**:

1. **Aumentar recursos no deployment.yaml**:
   ```yaml
   resources:
     requests:
       memory: "512Mi"  # Era 256Mi
       cpu: "500m"       # Era 250m
     limits:
       memory: "1Gi"     # Era 512Mi
       cpu: "1000m"      # Era 500m
   ```

2. **Reduzir número de réplicas**:
   ```yaml
   replicas: 1  # Em vez de 2
   ```

3. **Aplicar mudanças**:
   ```bash
   kubectl apply -f kubernetes/deployment.yaml
   ```

### 11.3 Executar Migrations

```bash
# Método 1: Via Job (recomendado)
kubectl apply -f kubernetes/migration-job.yaml

# Ver status do job
kubectl get jobs -n meu-projeto

# Ver logs da migration
kubectl logs -l job-name=migration -n meu-projeto

# Método 2: Manualmente dentro de um pod
kubectl exec -it deployment/app -n meu-projeto -- \
    php artisan migrate --force

# Ver migrations executadas
kubectl exec -it deployment/app -n meu-projeto -- \
    php artisan migrate:status
```

### 11.4 Acessar o Banco de Dados

```bash
# Conectar ao PostgreSQL
kubectl exec -it postgres-0 -n meu-projeto -- \
    psql -U laravel -d laravel

# Dentro do psql:
# \dt              - Listar tabelas
# \d+ users        - Descrever tabela users
# SELECT * FROM migrations;  - Ver migrations
# \q               - Sair
```

### 11.5 Comandos Úteis de Manutenção

```bash
# Reiniciar deployment (sem downtime)
kubectl rollout restart deployment/app -n meu-projeto

# Escalar número de pods
kubectl scale deployment/app --replicas=3 -n meu-projeto

# Ver histórico de deploys
kubectl rollout history deployment/app -n meu-projeto

# Fazer rollback para versão anterior
kubectl rollout undo deployment/app -n meu-projeto

# Limpar pods com erro
kubectl delete pod --field-selector=status.phase==Failed -n meu-projeto

# Backup do banco de dados
kubectl exec -it postgres-0 -n meu-projeto -- \
    pg_dump -U laravel laravel > backup-$(date +%Y%m%d).sql

# Restore do banco de dados
cat backup.sql | kubectl exec -i postgres-0 -n meu-projeto -- \
    psql -U laravel -d laravel

# Ver todos os logs da aplicação (últimas 100 linhas)
kubectl logs -l app=laravel-app -n meu-projeto --tail=100

# Seguir logs em tempo real
kubectl logs -f -l app=laravel-app -n meu-projeto
```

### 11.6 Atualizar a Aplicação

```bash
# Método automático (via GitHub Actions):
# Apenas faça commit e push
git add .
git commit -m "Atualização da aplicação"
git push origin main

# Acompanhar deploy
gh run watch

# Método manual (se necessário):
# 1. Build e push da imagem
docker build -t seu-usuario/seu-projeto:latest .
docker push seu-usuario/seu-projeto:latest

# 2. Atualizar deployment
kubectl rollout restart deployment/app -n meu-projeto

# 3. Verificar rollout
kubectl rollout status deployment/app -n meu-projeto
```

### 11.7 Monitoramento e Logs

```bash
# Ver eventos em tempo real
kubectl get events -n meu-projeto --watch

# Ver todos os pods com estado
kubectl get pods -n meu-projeto -o wide

# Ver configuração completa de um recurso
kubectl get deployment app -n meu-projeto -o yaml

# Ver todas as variáveis de ambiente de um pod
kubectl exec deployment/app -n meu-projeto -- env

# Executar Artisan Tinker
kubectl exec -it deployment/app -n meu-projeto -- php artisan tinker

# Ver uso de disco nos persistent volumes
kubectl exec -it postgres-0 -n meu-projeto -- df -h

# Ver processos rodando em um pod
kubectl exec -it deployment/app -n meu-projeto -- ps aux
```

---

## 📋 Checklists de Verificação

### ✅ Checklist: Infraestrutura da VPS (Parte 1)

Execute esta checklist **uma vez** ao configurar a VPS:

- [ ] VPS criada com Ubuntu 22.04 LTS
- [ ] Acesso SSH funcionando
- [ ] Sistema atualizado (`apt update && apt upgrade`)
- [ ] Firewall UFW configurado (portas 22, 80, 443, 6443, 10250)
- [ ] Docker instalado e rodando
- [ ] Kubernetes instalado (kubeadm, kubelet, kubectl)
- [ ] Swap desabilitado
- [ ] Módulos do kernel carregados (overlay, br_netfilter)
- [ ] Cluster Kubernetes inicializado
- [ ] CNI Flannel instalado
- [ ] Nó em status "Ready"
- [ ] Taint removido do master node
- [ ] Nginx Ingress Controller instalado
- [ ] Ingress Controller configurado com hostNetwork
- [ ] cert-manager instalado
- [ ] kubectl local configurado e conectando ao cluster
- [ ] Comando `kubectl get nodes` funcionando localmente

**Verificação final da infraestrutura:**

```bash
# Executar na VPS ou localmente (com kubectl configurado):
kubectl get nodes  # Deve mostrar: Ready
kubectl get pods --all-namespaces  # Todos devem estar: Running
kubectl get pods -n ingress-nginx  # Ingress Controller: Running
kubectl get pods -n cert-manager   # cert-manager (3 pods): Running
```

---

### ✅ Checklist: Deploy do Projeto Laravel (Parte 2)

Execute para **cada projeto Laravel**:

**Preparação do Projeto:**

- [ ] Pasta `kubernetes/` criada no projeto
- [ ] Arquivo `Dockerfile` criado
- [ ] Arquivo `docker/nginx/default.conf` criado
- [ ] Arquivo `docker/supervisor/supervisord.conf` criado
- [ ] Arquivo `.dockerignore` criado
- [ ] Todos os arquivos Kubernetes criados (namespace, secrets, configmap, etc.)

**Configuração dos Arquivos:**

- [ ] `namespace.yaml` - nome único definido
- [ ] `secrets.yaml` - APP_KEY gerada
- [ ] `secrets.yaml` - senhas do PostgreSQL e Redis definidas
- [ ] `configmap.yaml` - APP_URL configurada com seu domínio
- [ ] `deployment.yaml` - imagem Docker configurada
- [ ] `cert-issuer.yaml` - email configurado
- [ ] `ingress.yaml` - domínio configurado
- [ ] Diretórios criados na VPS (`/data/postgresql`, `/data/redis`)

**Docker Hub & GitHub:**

- [ ] Conta no Docker Hub criada
- [ ] Access Token do Docker Hub gerado
- [ ] Repositório no GitHub criado
- [ ] GitHub Secrets configurados:
  - [ ] `DOCKER_HUB_USERNAME`
  - [ ] `DOCKER_HUB_TOKEN`
  - [ ] `APP_KEY`
  - [ ] `KUBECONFIG`
- [ ] Arquivo `.github/workflows/deploy.yml` criado
- [ ] Push inicial feito no GitHub
- [ ] GitHub Actions executou com sucesso

**DNS & SSL:**

- [ ] Registros DNS configurados (A record apontando para VPS)
- [ ] DNS propagado (`dig seu-dominio.com` retorna IP da VPS)
- [ ] Certificado SSL criado (`kubectl get certificate`)
- [ ] Status do certificado: READY=True

**Aplicação:**

- [ ] Pods rodando (`kubectl get pods -n seu-namespace`)
- [ ] Services criados (`kubectl get svc -n seu-namespace`)
- [ ] Ingress configurado (`kubectl get ingress -n seu-namespace`)
- [ ] Migrations executadas
- [ ] Aplicação acessível via HTTPS
- [ ] HTTPS funcionando com certificado válido

**Verificação final do projeto:**

```bash
# Executar localmente (com kubectl configurado):
export NAMESPACE="meu-projeto"  # Substitua pelo seu namespace

kubectl get all -n $NAMESPACE
kubectl get certificate -n $NAMESPACE
kubectl get ingress -n $NAMESPACE
kubectl logs deployment/app -n $NAMESPACE --tail=50

# Testar aplicação
curl -I https://seu-dominio.com
```

---

## 🎓 Conceitos Importantes para Iniciantes

### O que é Kubernetes?

**Kubernetes (K8s)** é uma plataforma que automatiza o deploy, escalonamento e gerenciamento de aplicações em containers. Pense nele como um "maestro de orquestra" que coordena todos os componentes da sua aplicação.

### Principais Componentes Kubernetes:

| Componente | Analogia | Função |
|------------|----------|--------|
| **Pod** | Apartamento | Menor unidade executável. Contém um ou mais containers. |
| **Deployment** | Construtor de prédios | Gerencia réplicas de pods e atualizações. |
| **Service** | Portaria do prédio | Expõe pods internamente no cluster. |
| **Ingress** | Entrada principal | Roteia tráfego HTTP/HTTPS externo para services. |
| **ConfigMap** | Quadro de avisos | Armazena configurações não-sensíveis. |
| **Secret** | Cofre | Armazena dados sensíveis (senhas, tokens). |
| **PersistentVolume** | Depósito | Armazenamento permanente de dados. |
| **Namespace** | Andar do prédio | Isola recursos de diferentes projetos. |

### Comandos Essenciais:

```bash
# Ver status geral
kubectl get all -n NAMESPACE

# Ver detalhes de um recurso
kubectl describe TIPO NOME -n NAMESPACE

# Ver logs
kubectl logs POD_NAME -n NAMESPACE

# Executar comando dentro de um pod
kubectl exec -it POD_NAME -n NAMESPACE -- COMANDO

# Aplicar configuração
kubectl apply -f arquivo.yaml

# Deletar recurso
kubectl delete -f arquivo.yaml
```

### Fluxo de Deploy:

1. **Código** → Você escreve código Laravel
2. **Git Push** → Envia código para GitHub
3. **GitHub Actions** → Build automático da imagem Docker
4. **Docker Hub** → Armazena a imagem
5. **Kubernetes** → Baixa a imagem e cria pods
6. **Ingress** → Roteia requisições HTTP(S) para os pods
7. **cert-manager** → Gerencia certificados SSL
8. **Usuário** → Acessa aplicação via HTTPS

---

## 🚀 Próximos Passos

Após ter sua aplicação rodando:

### 1. Configurar Backups Automáticos

```bash
# Na VPS, criar script de backup
ssh root@SEU_IP_VPS

cat > /root/backup-auto.sh << 'EOF'
#!/bin/bash
NAMESPACE="meu-projeto"
DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_DIR="/root/backups"

mkdir -p $BACKUP_DIR

# Backup PostgreSQL
kubectl exec -n $NAMESPACE postgres-0 -- \
    pg_dump -U laravel laravel | \
    gzip > $BACKUP_DIR/db_${DATE}.sql.gz

# Manter apenas últimos 7 backups
find $BACKUP_DIR -name "db_*.sql.gz" | \
    sort -r | tail -n +8 | xargs -r rm

echo "Backup concluído: $BACKUP_DIR/db_${DATE}.sql.gz"
EOF

chmod +x /root/backup-auto.sh

# Agendar backup diário às 3h da manhã
(crontab -l 2>/dev/null; echo "0 3 * * * /root/backup-auto.sh >> /var/log/backup.log 2>&1") | crontab -
```

### 2. Configurar Monitoramento (Opcional)

```bash
# Instalar Prometheus e Grafana
kubectl create namespace monitoring

# Adicionar repositório Helm
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

# Instalar stack de monitoramento
helm install prometheus prometheus-community/kube-prometheus-stack \
    --namespace monitoring

# Acessar Grafana
kubectl port-forward -n monitoring svc/prometheus-grafana 3000:80
# Abrir http://localhost:3000
# Usuário: admin
# Senha: prom-operator
```

### 3. Escalar Aplicação

```bash
# Aumentar número de réplicas
kubectl scale deployment/app --replicas=3 -n meu-projeto

# Configurar autoscaling (escala automaticamente)
kubectl autoscale deployment/app \
    --min=2 --max=10 --cpu-percent=80 \
    -n meu-projeto
```

### 4. Adicionar Mais Projetos

Para adicionar outro projeto Laravel na mesma VPS:

1. Repetir apenas a **PARTE 2** deste guia
2. Usar um **namespace diferente** para cada projeto
3. Configurar **domínio diferente** para cada projeto
4. Os recursos da PARTE 1 (Ingress, cert-manager, etc.) são compartilhados

---

## 📚 Recursos Adicionais

### Documentação Oficial:

- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [kubectl Cheat Sheet](https://kubernetes.io/docs/reference/kubectl/cheatsheet/)
- [Docker Documentation](https://docs.docker.com/)
- [Laravel Deployment](https://laravel.com/docs/deployment)
- [Nginx Ingress Controller](https://kubernetes.github.io/ingress-nginx/)
- [cert-manager](https://cert-manager.io/docs/)

### Tutoriais Recomendados:

- [Kubernetes Basics](https://kubernetes.io/docs/tutorials/kubernetes-basics/)
- [Laravel in Docker](https://laravel.com/docs/sail)
- [CI/CD with GitHub Actions](https://docs.github.com/en/actions)

### Comunidades:

- [Kubernetes Slack](https://slack.k8s.io/)
- [Laravel Discord](https://discord.gg/laravel)
- [DigitalOcean Community](https://www.digitalocean.com/community)

---

## 🔧 Manutenção Regular

### Semanalmente:

```bash
# Verificar status geral
kubectl get nodes
kubectl get pods --all-namespaces

# Ver uso de recursos
kubectl top nodes
kubectl top pods --all-namespaces

# Verificar logs de erro
kubectl logs -l app=laravel-app -n meu-projeto | grep ERROR
```

### Mensalmente:

```bash
# Atualizar sistema da VPS
ssh root@SEU_IP_VPS
apt update && apt upgrade -y

# Verificar backups
ls -lh /root/backups/

# Testar restore de backup (em ambiente de teste!)
```

### Trimestralmente:

- Revisar e atualizar recursos (CPU/memória) dos pods
- Verificar e limpar images Docker antigas
- Atualizar versões do Kubernetes (cuidado com breaking changes!)
- Revisar e rotacionar senhas e tokens

---

## ⚠️ Avisos Importantes

### Segurança:

- **NUNCA** commite arquivos com senhas no Git
- Use sempre `secrets.yaml` para dados sensíveis
- Mantenha o sistema sempre atualizado
- Configure firewall corretamente
- Use senhas fortes para bancos de dados
- Ative autenticação de dois fatores no GitHub e Docker Hub

### Backup:

- **SEMPRE** faça backup do banco de dados regularmente
- Teste a restauração dos backups periodicamente
- Mantenha backups em local diferente da VPS

### Custos:

- Monitore uso de recursos da VPS
- Ajuste número de réplicas conforme necessário
- Considere usar CDN para assets estáticos

---

## 🎉 Conclusão

Parabéns! Você configurou uma infraestrutura moderna e escalável para seus projetos Laravel usando Docker e Kubernetes!

### O que você conseguiu:

✅ Infraestrutura profissional com Kubernetes  
✅ Deploy automático com CI/CD (GitHub Actions)  
✅ SSL gratuito e automático (Let's Encrypt)  
✅ Banco de dados PostgreSQL persistente  
✅ Cache e filas com Redis  
✅ Escalabilidade horizontal (múltiplos pods)  
✅ Zero-downtime deploys  
✅ Infraestrutura reutilizável para múltiplos projetos  

### Agora você pode:

- Fazer deploy de vários projetos Laravel na mesma VPS
- Atualizar aplicações com simples `git push`
- Escalar aplicações conforme demanda
- Ter SSL automático em todos os domínios
- Gerenciar tudo do seu computador com `kubectl`

---

**Criado em**: Dezembro 2024  
**Última atualização**: Dezembro 2024  
**Versões**:
- Kubernetes: v1.28.x
- Docker: 24.x
- Nginx Ingress: v1.9.5
- cert-manager: v1.13.0
- PHP: 8.4
- Laravel: 12.x
- PostgreSQL: 16
- Redis: 7

---

**💡 Dica Final**: Mantenha este documento atualizado conforme você faz melhorias na sua infraestrutura. Ele será uma referência valiosa para você e sua equipe!

**🆘 Precisa de ajuda?** Consulte a seção de [Troubleshooting](#112-problemas-comuns-e-soluções) ou as [comunidades](#comunidades) mencionadas acima.
