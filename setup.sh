#!/bin/bash

# 🚀 Script de Configuração Kubernetes para Laravel
# Este script cria automaticamente todos os arquivos necessários
# para deploy de projetos Laravel em Kubernetes

set -e

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

echo -e "${PURPLE}"
echo "╔════════════════════════════════════════════════════════════════╗"
echo "║  🚀 Configurador para Projetos Laravel                        ║"
echo "║  Versão 2.0.0 - Dev Local + Produção Kubernetes               ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo -e "${NC}"

# Detectar diretório do script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

echo -e "${CYAN}📁 Diretório do projeto: ${PROJECT_ROOT}${NC}\n"

# Verificar se está no diretório correto
if [[ ! -f "$SCRIPT_DIR/templates/namespace.yaml.stub" ]]; then
    echo -e "${RED}❌ Erro: Templates não encontrados!${NC}"
    echo -e "${YELLOW}Execute este script do diretório kubernetes-vps-setup/${NC}"
    exit 1
fi

# Configuração automática: Local + Produção
echo -e "${GREEN}═══════════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}  🔧 CONFIGURAÇÃO: DESENVOLVIMENTO + PRODUÇÃO${NC}"
echo -e "${GREEN}═══════════════════════════════════════════════════════════════${NC}\n"

echo -e "${CYAN}Este script irá gerar:${NC}"
echo -e "  ${YELLOW}✓${NC} 🛠️  Arquivos de ${CYAN}Desenvolvimento Local${NC} → pasta ${GREEN}.dev/${NC} (não sobe pro git)"
echo -e "  ${YELLOW}✓${NC} 🚀 Arquivos de ${CYAN}Produção Kubernetes${NC} → ${GREEN}kubernetes/${NC} + GitHub Actions"
echo ""
echo -e "${YELLOW}💡 Desenvolvimento local é executado manualmente com docker compose${NC}"
echo -e "${YELLOW}💡 Produção é feita via GitHub Actions (só commit/push)${NC}\n"

SETUP_LOCAL=true
SETUP_PROD=true

# Função para ler input com valor padrão
read_input() {
    local prompt="$1"
    local default="$2"
    local var_name="$3"
    
    if [[ -n "$default" ]]; then
        echo -e "${BLUE}${prompt}${NC} ${YELLOW}[padrão: ${default}]${NC}"
    else
        echo -e "${BLUE}${prompt}${NC}"
    fi
    
    read -r input
    if [[ -z "$input" ]]; then
        eval "$var_name='$default'"
    else
        eval "$var_name='$input'"
    fi
}

# Função para ler senha
read_password() {
    local prompt="$1"
    local var_name="$2"
    
    echo -e "${BLUE}${prompt}${NC}"
    read -s -r password
    echo
    eval "$var_name='$password'"
}

# Gerar senha aleatória
generate_password() {
    openssl rand -base64 32 | tr -d "=+/" | cut -c1-25
}

echo -e "${GREEN}═══════════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}  INFORMAÇÕES DO PROJETO${NC}"
echo -e "${GREEN}═══════════════════════════════════════════════════════════════${NC}\n"

# Informações do Projeto
read_input "📦 Nome do projeto (ex: meu-app):" "kb-app" PROJECT_NAME
read_input "🏢 Namespace Kubernetes (ex: ${PROJECT_NAME}):" "$PROJECT_NAME" NAMESPACE
read_input "🌐 Domínio principal (ex: app.exemplo.com):" "" DOMAIN

echo -e "\n${GREEN}═══════════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}  INFORMAÇÕES DO SERVIDOR VPS${NC}"
echo -e "${GREEN}═══════════════════════════════════════════════════════════════${NC}\n"

# Informações do Servidor
read_input "🖥️  IP da VPS:" "" VPS_IP

echo -e "\n${GREEN}═══════════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}  GITHUB CONTAINER REGISTRY${NC}"
echo -e "${GREEN}═══════════════════════════════════════════════════════════════${NC}\n"

# GitHub Container Registry
read_input "🐙 Usuário/Organização do GitHub:" "" GITHUB_USER
echo -e "${YELLOW}💡 Nome do repositório: apenas o nome, SEM usuário/org!${NC}"
echo -e "${YELLOW}   ✅ Correto: meu-app${NC}"
echo -e "${YELLOW}   ❌ Errado: seu-usuario/meu-app${NC}"
read_input "📦 Nome do repositório GitHub:" "$PROJECT_NAME" GITHUB_REPO_NAME

# Remover qualquer prefixo de usuário caso o usuário tenha digitado errado
GITHUB_REPO_NAME="${GITHUB_REPO_NAME##*/}"
GITHUB_REPO="${GITHUB_USER}/${GITHUB_REPO_NAME}"

echo -e "\n${GREEN}═══════════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}  CONFIGURAÇÕES DO LARAVEL${NC}"
echo -e "${GREEN}═══════════════════════════════════════════════════════════════${NC}\n"

# Laravel
read_input "🔑 APP_KEY (deixe vazio para gerar automaticamente):" "" APP_KEY

if [[ -z "$APP_KEY" ]]; then
    echo -e "${YELLOW}⏳ Gerando APP_KEY...${NC}"
    if command -v php &> /dev/null && [[ -f "$PROJECT_ROOT/artisan" ]]; then
        APP_KEY=$(cd "$PROJECT_ROOT" && php artisan key:generate --show 2>/dev/null || echo "")
    fi
    
    if [[ -z "$APP_KEY" ]]; then
        # Gerar manualmente se PHP não disponível
        RANDOM_KEY=$(openssl rand -base64 32)
        APP_KEY="base64:${RANDOM_KEY}"
    fi
    echo -e "${GREEN}✅ APP_KEY gerada: ${APP_KEY}${NC}"
fi

read_input "📧 Email do APP (ex: admin@${DOMAIN}):" "admin@${DOMAIN}" APP_EMAIL

echo -e "\n${GREEN}═══════════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}  BANCO DE DADOS${NC}"
echo -e "${GREEN}═══════════════════════════════════════════════════════════════${NC}\n"

# Database
read_input "🗄️  Nome do banco de dados:" "laravel" DB_NAME
read_input "👤 Usuário do banco de dados:" "laravel" DB_USER

echo -e "${YELLOW}💡 Deixe vazio para gerar senha automática segura${NC}"
read_password "🔐 Senha do PostgreSQL:" DB_PASSWORD

if [[ -z "$DB_PASSWORD" ]]; then
    DB_PASSWORD=$(generate_password)
    echo -e "${GREEN}✅ Senha gerada: ${DB_PASSWORD}${NC}"
fi

echo -e "\n${GREEN}═══════════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}  REDIS${NC}"
echo -e "${GREEN}═══════════════════════════════════════════════════════════════${NC}\n"

echo -e "${YELLOW}💡 Deixe vazio para gerar senha automática segura${NC}"
read_password "🔐 Senha do Redis:" REDIS_PASSWORD

if [[ -z "$REDIS_PASSWORD" ]]; then
    REDIS_PASSWORD=$(generate_password)
    echo -e "${GREEN}✅ Senha gerada: ${REDIS_PASSWORD}${NC}"
fi

echo -e "\n${GREEN}═══════════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}  ARMAZENAMENTO (OPCIONAL)${NC}"
echo -e "${GREEN}═══════════════════════════════════════════════════════════════${NC}\n"

read_input "☁️  Usar DigitalOcean Spaces/S3? (s/n):" "n" USE_SPACES

DO_SPACES_KEY=""
DO_SPACES_SECRET=""
DO_SPACES_REGION=""
DO_SPACES_BUCKET=""
DO_SPACES_ENDPOINT=""

if [[ "$USE_SPACES" == "s" || "$USE_SPACES" == "S" ]]; then
    read_input "🔑 DigitalOcean Spaces Access Key:" "" DO_SPACES_KEY
    read_password "🔐 DigitalOcean Spaces Secret Key:" DO_SPACES_SECRET
    read_input "🌍 Região (ex: sfo3, nyc3):" "sfo3" DO_SPACES_REGION
    read_input "🪣 Nome do Bucket:" "$PROJECT_NAME" DO_SPACES_BUCKET
    read_input "🔗 Endpoint (ex: https://sfo3.digitaloceanspaces.com):" "https://${DO_SPACES_REGION}.digitaloceanspaces.com" DO_SPACES_ENDPOINT
fi

echo -e "\n${GREEN}═══════════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}  LARAVEL REVERB (WEBSOCKETS)${NC}"
echo -e "${GREEN}═══════════════════════════════════════════════════════════════${NC}\n"

echo -e "${CYAN}Laravel Reverb é o servidor WebSocket oficial do Laravel${NC}"
echo -e "${CYAN}para broadcasting em tempo real (notificações, chat, etc)${NC}\n"

echo -e "${YELLOW}💡 Deixe vazio para gerar credenciais automáticas${NC}"

read_input "🔑 Reverb APP_ID (deixe vazio para gerar):" "" REVERB_APP_ID
if [[ -z "$REVERB_APP_ID" ]]; then
    REVERB_APP_ID=$(openssl rand -hex 16)
    echo -e "${GREEN}✅ APP_ID gerado: ${REVERB_APP_ID}${NC}"
fi

read_password "🔐 Reverb APP_KEY (deixe vazio para gerar):" REVERB_APP_KEY
if [[ -z "$REVERB_APP_KEY" ]]; then
    REVERB_APP_KEY=$(generate_password)
    echo -e "${GREEN}✅ APP_KEY gerado: ${REVERB_APP_KEY}${NC}"
fi

read_password "🔐 Reverb APP_SECRET (deixe vazio para gerar):" REVERB_APP_SECRET
if [[ -z "$REVERB_APP_SECRET" ]]; then
    REVERB_APP_SECRET=$(generate_password)
    echo -e "${GREEN}✅ APP_SECRET gerado: ${REVERB_APP_SECRET}${NC}"
fi

echo -e "\n${GREEN}═══════════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}  RECURSOS (CPU/MEMÓRIA)${NC}"
echo -e "${GREEN}═══════════════════════════════════════════════════════════════${NC}\n"

echo -e "${YELLOW}💡 Escolha um perfil de recursos ou configure manualmente:${NC}\n"

echo -e "${CYAN}1)${NC} 🚀 ${GREEN}Produção VPS${NC} - Alta disponibilidade"
echo -e "   └─ 2 réplicas | RAM: 512Mi-1Gi | CPU: 500m-1000m"
echo -e "   └─ Recomendado para apps em produção com tráfego real\n"

echo -e "${CYAN}2)${NC} 💻 ${YELLOW}Local (Minikube)${NC} - Recursos mínimos"
echo -e "   └─ 1 réplica | RAM: 128Mi-256Mi | CPU: 100m-250m"
echo -e "   └─ Otimizado para Kubernetes local (Minikube, Kind, k3d)\n"

echo -e "${CYAN}3)${NC} 🛠️  ${YELLOW}Desenvolvimento${NC} - Recursos moderados"
echo -e "   └─ 1 réplica | RAM: 256Mi-512Mi | CPU: 250m-500m"
echo -e "   └─ Para ambiente de desenvolvimento/staging\n"

echo -e "${CYAN}4)${NC} 🧪 ${BLUE}Test${NC} - Recursos moderados"
echo -e "   └─ 1 réplica | RAM: 256Mi-512Mi | CPU: 250m-500m"
echo -e "   └─ Para testes automatizados e homologação\n"

echo -e "${CYAN}5)${NC} ⚙️  ${PURPLE}Manual${NC} - Configuração customizada"
echo -e "   └─ Você define todos os valores\n"

read -p "$(echo -e ${BLUE}Escolha uma opção [1-5]:${NC} )" RESOURCE_PROFILE

case $RESOURCE_PROFILE in
    1)
        echo -e "\n${GREEN}✅ Perfil PRODUÇÃO VPS selecionado${NC}\n"
        MEM_REQUEST="512Mi"
        MEM_LIMIT="1Gi"
        CPU_REQUEST="500m"
        CPU_LIMIT="1000m"
        REPLICAS="2"
        ;;
    2)
        echo -e "\n${YELLOW}✅ Perfil LOCAL (Minikube) selecionado${NC}\n"
        MEM_REQUEST="128Mi"
        MEM_LIMIT="256Mi"
        CPU_REQUEST="100m"
        CPU_LIMIT="250m"
        REPLICAS="1"
        echo -e "${CYAN}💡 Otimizado para Kubernetes local com recursos limitados${NC}"
        ;;
    3)
        echo -e "\n${YELLOW}✅ Perfil DESENVOLVIMENTO selecionado${NC}\n"
        MEM_REQUEST="256Mi"
        MEM_LIMIT="512Mi"
        CPU_REQUEST="250m"
        CPU_LIMIT="500m"
        REPLICAS="1"
        ;;
    4)
        echo -e "\n${BLUE}✅ Perfil TEST selecionado${NC}\n"
        MEM_REQUEST="256Mi"
        MEM_LIMIT="512Mi"
        CPU_REQUEST="250m"
        CPU_LIMIT="500m"
        REPLICAS="1"
        ;;
    5|*)
        echo -e "\n${PURPLE}⚙️  Configuração MANUAL${NC}\n"
        read_input "💾 Memória mínima (ex: 256Mi, 512Mi):" "512Mi" MEM_REQUEST
        read_input "💾 Memória máxima (ex: 512Mi, 1Gi):" "1Gi" MEM_LIMIT
        read_input "⚡ CPU mínima (ex: 250m, 500m):" "500m" CPU_REQUEST
        read_input "⚡ CPU máxima (ex: 500m, 1000m):" "1000m" CPU_LIMIT
        read_input "📊 Número de réplicas:" "2" REPLICAS
        ;;
esac

echo -e "${CYAN}Recursos configurados:${NC}"
echo -e "  RAM: ${GREEN}${MEM_REQUEST} → ${MEM_LIMIT}${NC}"
echo -e "  CPU: ${GREEN}${CPU_REQUEST} → ${CPU_LIMIT}${NC}"
echo -e "  Réplicas: ${GREEN}${REPLICAS}${NC}\n"

# Resumo
echo -e "\n${PURPLE}═══════════════════════════════════════════════════════════════${NC}"
echo -e "${PURPLE}  RESUMO DA CONFIGURAÇÃO${NC}"
echo -e "${PURPLE}═══════════════════════════════════════════════════════════════${NC}\n"

echo -e "${CYAN}Projeto:${NC}"
echo -e "  Nome: ${GREEN}${PROJECT_NAME}${NC}"
echo -e "  GitHub: ${GREEN}${GITHUB_REPO}${NC}"
echo -e "  Namespace: ${GREEN}${NAMESPACE}${NC}"
echo -e "  Domínio: ${GREEN}${DOMAIN}${NC}"
echo -e "  Imagem Docker: ${GREEN}${DOCKER_IMAGE}${NC}"
echo -e ""
echo -e "${CYAN}Servidor:${NC}"
echo -e "  IP VPS: ${GREEN}${VPS_IP}${NC}"
echo -e ""
echo -e "${CYAN}Banco de Dados:${NC}"
echo -e "  Database: ${GREEN}${DB_NAME}${NC}"
echo -e "  Usuário: ${GREEN}${DB_USER}${NC}"
echo -e "  Senha: ${GREEN}${DB_PASSWORD:0:10}...${NC}"
echo -e ""
echo -e "${CYAN}Recursos:${NC}"
echo -e "  Réplicas: ${GREEN}${REPLICAS}${NC}"
echo -e "  Memória: ${GREEN}${MEM_REQUEST} - ${MEM_LIMIT}${NC}"
echo -e "  CPU: ${GREEN}${CPU_REQUEST} - ${CPU_LIMIT}${NC}"

echo -e "\n${YELLOW}❓ Confirma as configurações acima? (s/n)${NC}"
read -r confirm

if [[ "$confirm" != "s" && "$confirm" != "S" ]]; then
    echo -e "${RED}❌ Configuração cancelada.${NC}"
    exit 0
fi

# Criar diretórios de output
OUTPUT_DIR="$PROJECT_ROOT/kubernetes"
DEV_DIR="$PROJECT_ROOT/.dev"  # Pasta para arquivos de desenvolvimento (não sobe pro git)
DOCKER_DIR="$PROJECT_ROOT/docker"
GITHUB_DIR="$PROJECT_ROOT/.github/workflows"

echo -e "\n${YELLOW}⏳ Criando estrutura de diretórios...${NC}"

# Desenvolvimento local
mkdir -p "$DEV_DIR"

# Produção
mkdir -p "$OUTPUT_DIR"
mkdir -p "$DOCKER_DIR/nginx"
mkdir -p "$DOCKER_DIR/supervisor"
mkdir -p "$GITHUB_DIR"

# Função para processar template
process_template() {
    local template_file="$1"
    local output_file="$2"
    
    cp "$template_file" "$output_file"
    
    # Substituições
    sed -i "s|{{PROJECT_NAME}}|${PROJECT_NAME}|g" "$output_file"
    sed -i "s|{{NAMESPACE}}|${NAMESPACE}|g" "$output_file"
    sed -i "s|{{DOMAIN}}|${DOMAIN}|g" "$output_file"
    sed -i "s|{{VPS_IP}}|${VPS_IP}|g" "$output_file"
    sed -i "s|{{GITHUB_USER}}|${GITHUB_USER}|g" "$output_file"
    sed -i "s|{{GITHUB_REPO_NAME}}|${GITHUB_REPO_NAME}|g" "$output_file"
    sed -i "s|{{GITHUB_REPO}}|${GITHUB_REPO}|g" "$output_file"
    sed -i "s|{{APP_KEY}}|${APP_KEY}|g" "$output_file"
    sed -i "s|{{APP_EMAIL}}|${APP_EMAIL}|g" "$output_file"
    sed -i "s|{{DB_NAME}}|${DB_NAME}|g" "$output_file"
    sed -i "s|{{DB_USER}}|${DB_USER}|g" "$output_file"
    sed -i "s|{{DB_PASSWORD}}|${DB_PASSWORD}|g" "$output_file"
    sed -i "s|{{REDIS_PASSWORD}}|${REDIS_PASSWORD}|g" "$output_file"
    sed -i "s|{{REVERB_APP_ID}}|${REVERB_APP_ID}|g" "$output_file"
    sed -i "s|{{REVERB_APP_KEY}}|${REVERB_APP_KEY}|g" "$output_file"
    sed -i "s|{{REVERB_APP_SECRET}}|${REVERB_APP_SECRET}|g" "$output_file"
    sed -i "s|{{DO_SPACES_KEY}}|${DO_SPACES_KEY}|g" "$output_file"
    sed -i "s|{{DO_SPACES_SECRET}}|${DO_SPACES_SECRET}|g" "$output_file"
    sed -i "s|{{DO_SPACES_REGION}}|${DO_SPACES_REGION}|g" "$output_file"
    sed -i "s|{{DO_SPACES_BUCKET}}|${DO_SPACES_BUCKET}|g" "$output_file"
    sed -i "s|{{DO_SPACES_ENDPOINT}}|${DO_SPACES_ENDPOINT}|g" "$output_file"
    sed -i "s|{{MEM_REQUEST}}|${MEM_REQUEST}|g" "$output_file"
    sed -i "s|{{MEM_LIMIT}}|${MEM_LIMIT}|g" "$output_file"
    sed -i "s|{{CPU_REQUEST}}|${CPU_REQUEST}|g" "$output_file"
    sed -i "s|{{CPU_LIMIT}}|${CPU_LIMIT}|g" "$output_file"
    sed -i "s|{{REPLICAS}}|${REPLICAS}|g" "$output_file"
    sed -i "s|{{DB_DATABASE}}|${DB_NAME}|g" "$output_file"
    sed -i "s|{{DB_USERNAME}}|${DB_USER}|g" "$output_file"
    sed -i "s|{{APP_NAME}}|${PROJECT_NAME}|g" "$output_file"
    
    echo -e "${GREEN}✅${NC} $(basename "$output_file")"
}

# Gerar arquivos para Desenvolvimento Local (pasta .dev/)
echo -e "\n${CYAN}═══════════════════════════════════════════════════════════════${NC}"
echo -e "${CYAN}  🛠️  DESENVOLVIMENTO LOCAL (.dev/ - não versiona)${NC}"
echo -e "${CYAN}═══════════════════════════════════════════════════════════════${NC}\n"

# Docker Compose
process_template "$SCRIPT_DIR/templates/docker-compose.yml.stub" "$DEV_DIR/docker-compose.yml"

# Dockerfile para dev
process_template "$SCRIPT_DIR/templates/Dockerfile.dev.stub" "$DEV_DIR/Dockerfile.dev"

# Nginx dev
process_template "$SCRIPT_DIR/templates/nginx-dev.conf.stub" "$DEV_DIR/nginx.conf"

# Supervisor dev
process_template "$SCRIPT_DIR/templates/supervisord-dev.conf.stub" "$DEV_DIR/supervisord.conf"

# PHP config
process_template "$SCRIPT_DIR/templates/php-local.ini.stub" "$DEV_DIR/php.ini"

# .env.local
process_template "$SCRIPT_DIR/templates/env.local.stub" "$DEV_DIR/.env.local"

# Script de inicialização automática
cat > "$DEV_DIR/init.sh" << 'INITSCRIPT'
#!/bin/bash
set -e

echo "🚀 Inicializando ambiente de desenvolvimento..."
echo ""

# Verificar se há volumes Docker antigos que podem ter senhas diferentes
if docker volume ls | grep -q "postgres"; then
    echo "⚠️  ATENÇÃO: Detectados volumes Docker existentes!"
    echo "   Se este projeto foi reconfigurado com novas senhas, você precisa limpar os volumes antigos."
    echo ""
    read -p "   Deseja REMOVER volumes existentes e começar do zero? [s/N]: " -n 1 -r REMOVE_VOLUMES
    echo ""
    if [[ $REMOVE_VOLUMES =~ ^[Ss]$ ]]; then
        echo "🗑️  Removendo volumes antigos..."
        docker compose down -v
    else
        echo "⚠️  Mantendo volumes existentes. Se houver erro de autenticação, rode:"
        echo "   docker compose down -v && ./init.sh"
        echo ""
    fi
fi

# 1. Copiar .env
echo "📝 Copiando .env..."
cp .env.local ../.env

# 2. Subir containers
echo "🐳 Subindo containers..."
docker compose up -d

# 3. Aguardar PostgreSQL estar realmente pronto
echo "⏳ Aguardando PostgreSQL aceitar conexões..."
until docker compose exec -T postgres pg_isready -U postgres > /dev/null 2>&1; do
  echo "   Aguardando PostgreSQL..."
  sleep 2
done
echo "✅ PostgreSQL aceitando conexões!"

# 3.1. Aguardar PostgreSQL estar totalmente inicializado (criar DB e usuário)
echo "⏳ Aguardando inicialização completa do banco..."
sleep 5

# 3.2. Testar conexão com credenciais do Laravel
echo "⏳ Testando conexão com banco de dados..."
MAX_ATTEMPTS=10
ATTEMPT=0
until docker compose exec -T app php artisan db:show > /dev/null 2>&1; do
  ATTEMPT=$((ATTEMPT + 1))
  if [ $ATTEMPT -ge $MAX_ATTEMPTS ]; then
    echo "❌ Erro: Não foi possível conectar ao banco após $MAX_ATTEMPTS tentativas"
    echo ""
    echo "   Verificando logs do PostgreSQL..."
    docker compose logs postgres | tail -20
    echo ""
    echo "   ${RED}SOLUÇÃO:${NC} Provavelmente há volumes antigos com senha diferente."
    echo "   Execute: ${GREEN}docker compose down -v && ./init.sh${NC}"
    echo ""
    exit 1
  fi
  echo "   Tentativa $ATTEMPT/$MAX_ATTEMPTS - Aguardando conexão..."
  sleep 3
done
echo "✅ Conexão com banco de dados estabelecida!"

# 4. Ajustar permissões
echo "🔐 Ajustando permissões..."
docker compose exec -T app chmod -R 775 storage bootstrap/cache
docker compose exec -T app chown -R www-data:www-data storage bootstrap/cache

# 5. Instalar dependências
echo "📦 Instalando dependências..."
docker compose exec -T app composer install --no-interaction

# 6. Instalar Laravel Reverb
echo "📡 Instalando Laravel Reverb (WebSocket)..."
docker compose exec -T app composer require laravel/reverb --no-interaction || echo "⚠️  Reverb já instalado ou erro na instalação"

# 7. Migrations
echo "🗄️  Executando migrations..."
docker compose exec -T app php artisan migrate --force

echo ""
echo "✅ Ambiente pronto!"
echo ""
echo "🌐 Acesse: http://localhost:8000"
echo "📧 Mailhog: http://localhost:8025"
INITSCRIPT

chmod +x "$DEV_DIR/init.sh"

# README para desenvolvimento
cat > "$DEV_DIR/README.md" << 'DEVREADME'
# 🛠️ Ambiente de Desenvolvimento Local

Esta pasta contém os arquivos para rodar o projeto localmente com Docker Compose.

> ⚠️ **Esta pasta não sobe para o git** - configurações locais apenas

## 🚀 Quick Start (Automático)

```bash
cd .dev
./init.sh
```

## 📋 Ou Passo a Passo (Manual)

```bash
# Entrar na pasta .dev
cd .dev

# 1. Copiar .env
cp .env.local ../.env

# 2. Subir containers
docker compose up -d

# 3. Ajustar permissões
sleep 5
docker compose exec -T app chmod -R 775 storage bootstrap/cache
docker compose exec -T app chown -R www-data:www-data storage bootstrap/cache

# 4. Instalar dependências
docker compose exec -T app composer install

# 5. Migrations
docker compose exec -T app php artisan migrate --force
```

## 🌐 Acessar

- App: http://localhost:8000
- Mailhog: http://localhost:8025

## 📖 Documentação Completa

Veja: `kubernetes-vps-setup/DEV_LOCAL.md`
DEVREADME

# Gerar arquivos para Produção (Kubernetes + GitHub Actions)
echo -e "\n${CYAN}═══════════════════════════════════════════════════════════════${NC}"
echo -e "${CYAN}  🚀 PRODUÇÃO (Kubernetes + GitHub Actions)${NC}"
echo -e "${CYAN}═══════════════════════════════════════════════════════════════${NC}\n"

# Processar templates Kubernetes
process_template "$SCRIPT_DIR/templates/namespace.yaml.stub" "$OUTPUT_DIR/namespace.yaml"
process_template "$SCRIPT_DIR/templates/secrets.yaml.stub" "$OUTPUT_DIR/secrets.yaml"
process_template "$SCRIPT_DIR/templates/configmap.yaml.stub" "$OUTPUT_DIR/configmap.yaml"
process_template "$SCRIPT_DIR/templates/postgres.yaml.stub" "$OUTPUT_DIR/postgres.yaml"
process_template "$SCRIPT_DIR/templates/redis.yaml.stub" "$OUTPUT_DIR/redis.yaml"
process_template "$SCRIPT_DIR/templates/deployment.yaml.stub" "$OUTPUT_DIR/deployment.yaml"
process_template "$SCRIPT_DIR/templates/service.yaml.stub" "$OUTPUT_DIR/service.yaml"
process_template "$SCRIPT_DIR/templates/ingress.yaml.stub" "$OUTPUT_DIR/ingress.yaml"
process_template "$SCRIPT_DIR/templates/cert-issuer.yaml.stub" "$OUTPUT_DIR/cert-issuer.yaml"
    process_template "$SCRIPT_DIR/templates/migration-job.yaml.stub" "$OUTPUT_DIR/migration-job.yaml"

    echo -e "\n${YELLOW}⏳ Gerando arquivos Docker (Produção)...${NC}"

    # Processar templates Docker
    process_template "$SCRIPT_DIR/Dockerfile.stub" "$PROJECT_ROOT/Dockerfile"
    process_template "$SCRIPT_DIR/docker/nginx/default.conf.stub" "$DOCKER_DIR/nginx/default.conf"
    process_template "$SCRIPT_DIR/docker/supervisor/supervisord.conf.stub" "$DOCKER_DIR/supervisor/supervisord.conf"
    
    if [[ ! -f "$PROJECT_ROOT/.dockerignore" ]]; then
        process_template "$SCRIPT_DIR/.dockerignore.stub" "$PROJECT_ROOT/.dockerignore"
    fi

echo -e "\n${YELLOW}⏳ Gerando GitHub Actions (Deploy Automático)...${NC}"

# Processar templates GitHub Actions
process_template "$SCRIPT_DIR/.github/workflows/deploy.yml.stub" "$GITHUB_DIR/deploy.yml"
process_template "$SCRIPT_DIR/.github/workflows/docker-build.yml.stub" "$GITHUB_DIR/docker-build.yml"
process_template "$SCRIPT_DIR/.github/workflows/tests.yml.stub" "$GITHUB_DIR/tests.yml"
process_template "$SCRIPT_DIR/.github/workflows/lint.yml.stub" "$GITHUB_DIR/lint.yml"

# Atualizar .gitignore para ignorar pasta .dev/
echo -e "\n${YELLOW}⏳ Atualizando .gitignore...${NC}"
GITIGNORE_FILE="$PROJECT_ROOT/.gitignore"

if [[ -f "$GITIGNORE_FILE" ]]; then
    # Verificar se .dev/ já está no .gitignore
    if ! grep -q "^\.dev/" "$GITIGNORE_FILE" 2>/dev/null; then
        echo "" >> "$GITIGNORE_FILE"
        echo "# Ambiente de desenvolvimento local (não versionar)" >> "$GITIGNORE_FILE"
        echo ".dev/" >> "$GITIGNORE_FILE"
        echo -e "${GREEN}✅${NC} .gitignore atualizado"
    else
        echo -e "${YELLOW}ℹ️${NC}  .dev/ já existe no .gitignore"
    fi
else
    # Criar .gitignore se não existir
    cat > "$GITIGNORE_FILE" << 'GITIGNORE'
# Ambiente de desenvolvimento local (não versionar)
.dev/

# Laravel
/node_modules
/public/hot
/public/storage
/storage/*.key
/vendor
.env
.env.backup
.env.production
.phpunit.result.cache
Homestead.json
Homestead.yaml
auth.json
npm-debug.log
yarn-error.log
/.fleet
/.idea
/.vscode
GITIGNORE
    echo -e "${GREEN}✅${NC} .gitignore criado"
fi

# Criar arquivo de configuração para referência
CONFIG_FILE="$OUTPUT_DIR/.config"

cat > "$CONFIG_FILE" << EOF
# Configuração gerada em $(date)
PROJECT_NAME=${PROJECT_NAME}
NAMESPACE=${NAMESPACE}
DOMAIN=${DOMAIN}
VPS_IP=${VPS_IP}
GITHUB_USER=${GITHUB_USER}
GITHUB_REPO=${GITHUB_REPO}
DB_NAME=${DB_NAME}
DB_USER=${DB_USER}
EOF

echo -e "\n${GREEN}═══════════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}  ✅ ARQUIVOS GERADOS COM SUCESSO!${NC}"
echo -e "${GREEN}═══════════════════════════════════════════════════════════════${NC}\n"

echo -e "${CYAN}📂 Arquivos de Desenvolvimento Local:${NC}"
echo -e "  ${GREEN}.dev/docker-compose.yml${NC} - Orquestração dos containers (use: docker compose)"
echo -e "  ${GREEN}.dev/Dockerfile.dev${NC} - Build para desenvolvimento"
echo -e "  ${GREEN}.dev/.env.local${NC} - Variáveis de ambiente"
echo -e "  ${GREEN}.dev/docker/${NC} - Configurações Nginx, Supervisor e PHP"
echo -e "  ${YELLOW}⚠️  Pasta .dev/ NÃO sobe para o git${NC}"

echo -e "\n${CYAN}📂 Arquivos de Produção:${NC}"
echo -e "  ${GREEN}kubernetes/${NC} - Configurações Kubernetes"
echo -e "  ${GREEN}docker/${NC} - Configurações Docker"
echo -e "  ${GREEN}.github/workflows/${NC} - CI/CD (Deploy Automático)"
echo -e "  ${GREEN}Dockerfile${NC} - Build da imagem"

echo -e "\n${PURPLE}═══════════════════════════════════════════════════════════════${NC}"
echo -e "${PURPLE}  📋 PRÓXIMOS PASSOS${NC}"
echo -e "${PURPLE}═══════════════════════════════════════════════════════════════${NC}\n"

echo -e "${CYAN}🛠️  Para Desenvolvimento Local:${NC}"
echo -e ""
echo -e "${YELLOW}Opção 1 - Automático (Recomendado):${NC}"
echo -e "   ${GREEN}cd .dev && ./init.sh${NC}"
echo -e ""
echo -e "${YELLOW}Opção 2 - Manual:${NC}"
echo -e ""
echo -e "${YELLOW}1.${NC} ${CYAN}Entrar na pasta .dev:${NC}"
echo -e "   ${GREEN}cd .dev${NC}"
echo -e ""
echo -e "${YELLOW}2.${NC} ${CYAN}Copiar .env:${NC}"
echo -e "   ${GREEN}cp .env.local ../.env${NC}"
echo -e ""
echo -e "${YELLOW}3.${NC} ${CYAN}Inicializar ambiente:${NC}"
echo -e "   ${GREEN}docker compose up -d && \\${NC}"
echo -e "   ${GREEN}  sleep 8 && \\${NC}"
echo -e "   ${GREEN}  docker compose exec -T app chmod -R 775 storage bootstrap/cache && \\${NC}"
echo -e "   ${GREEN}  docker compose exec -T app chown -R www-data:www-data storage bootstrap/cache && \\${NC}"
echo -e "   ${GREEN}  docker compose exec -T app composer install && \\${NC}"
echo -e "   ${GREEN}  docker compose exec -T app php artisan migrate --force${NC}"
echo -e ""
echo -e "${YELLOW}4.${NC} ${CYAN}Acessar aplicação:${NC}"
echo -e "   🌐 App: ${GREEN}http://localhost:8000${NC}"
echo -e "   📧 Mailhog: ${GREEN}http://localhost:8025${NC}"
echo -e ""
echo -e "${CYAN}📖 Documentação: ${GREEN}kubernetes-vps-setup/DEV_LOCAL.md${NC}"
echo ""
echo -e "${PURPLE}───────────────────────────────────────────────────────────────${NC}"
echo ""
echo -e "${CYAN}🚀 Para Produção (GitHub Actions - Deploy Automático):${NC}"
echo -e ""
echo -e "${YELLOW}1.${NC} ${CYAN}Na VPS, criar os diretórios de dados:${NC}"
echo -e "   ${GREEN}ssh root@${VPS_IP}${NC}"
echo -e "   ${GREEN}mkdir -p /data/postgresql/${NAMESPACE} /data/redis/${NAMESPACE}${NC}"
echo -e "   ${GREEN}chmod 700 /data/postgresql/${NAMESPACE} && chmod 755 /data/redis/${NAMESPACE}${NC}"
echo -e ""
echo -e "${YELLOW}2.${NC} ${CYAN}Configurar GitHub Secrets:${NC}"
echo -e "   ${GREEN}# APP_KEY${NC}"
echo -e "   ${GREEN}gh secret set APP_KEY --body \"${APP_KEY}\"${NC}"
echo -e ""
echo -e "   ${GREEN}# KUBE_CONFIG (do servidor VPS ou local com kubectl configurado)${NC}"
echo -e "   ${GREEN}kubectl config view --flatten --minify | base64 -w 0 | gh secret set KUBE_CONFIG --body-file -${NC}"
echo -e ""
echo -e "   ${YELLOW}💡 O GITHUB_TOKEN já está disponível automaticamente${NC}"
echo -e "   ${YELLOW}💡 Imagens serão publicadas em ghcr.io/${GITHUB_REPO}${NC}"
echo -e "   ${YELLOW}⚠️  IMPORTANTE: Use 'kubectl config view --flatten' para evitar localhost${NC}"
echo -e ""
echo -e "${YELLOW}3.${NC} ${CYAN}Configurar DNS (no seu provedor):${NC}"
echo -e "   Tipo: ${GREEN}A${NC}"
echo -e "   Nome: ${GREEN}@${NC}"
echo -e "   Valor: ${GREEN}${VPS_IP}${NC}"
echo -e "   TTL: ${GREEN}3600${NC}"
echo -e ""
echo -e "${YELLOW}4.${NC} ${CYAN}Fazer primeiro deploy:${NC}"
echo -e "   ${GREEN}git add .${NC}"
echo -e "   ${GREEN}git commit -m \"feat: Add Kubernetes configuration\"${NC}"
echo -e "   ${GREEN}git push origin main${NC}"
echo -e ""
echo -e "${YELLOW}5.${NC} ${CYAN}Aplicar configurações Kubernetes:${NC}"
echo -e "   ${GREEN}kubectl apply -f kubernetes/namespace.yaml${NC}"
echo -e "   ${GREEN}kubectl apply -f kubernetes/secrets.yaml${NC}"
echo -e "   ${GREEN}kubectl apply -f kubernetes/configmap.yaml${NC}"
echo -e "   ${GREEN}kubectl apply -f kubernetes/cert-issuer.yaml${NC}"
echo -e "   ${GREEN}kubectl apply -f kubernetes/postgres.yaml${NC}"
echo -e "   ${GREEN}kubectl apply -f kubernetes/redis.yaml${NC}"
echo -e "   ${GREEN}kubectl apply -f kubernetes/deployment.yaml${NC}"
echo -e "   ${GREEN}kubectl apply -f kubernetes/service.yaml${NC}"
echo -e "   ${GREEN}kubectl apply -f kubernetes/ingress.yaml${NC}"

echo -e "\n${PURPLE}═══════════════════════════════════════════════════════════════${NC}"
echo -e "${PURPLE}  📖 INFORMAÇÕES IMPORTANTES${NC}"
echo -e "${PURPLE}═══════════════════════════════════════════════════════════════${NC}\n"

echo -e "${YELLOW}⚠️  Senhas geradas (salve em local seguro!):${NC}"
echo -e "   PostgreSQL: ${GREEN}${DB_PASSWORD}${NC}"
echo -e "   Redis: ${GREEN}${REDIS_PASSWORD}${NC}"
echo -e ""
echo -e "${YELLOW}🔑 APP_KEY:${NC}"
echo -e "   ${GREEN}${APP_KEY}${NC}"
echo -e ""
echo -e "${YELLOW}📧 Email de contato:${NC}"
echo -e "   ${GREEN}${APP_EMAIL}${NC}"
echo -e ""
echo -e "${YELLOW}🌐 Sua aplicação estará disponível em:${NC}"
echo -e "   ${CYAN}Local:${NC} ${GREEN}http://localhost:8000${NC}"
echo -e "   ${CYAN}Produção:${NC} ${GREEN}https://${DOMAIN}${NC}"

# Copiar documentação e scripts úteis
echo -e "\n${YELLOW}📚 Copiando documentação essencial...${NC}"

# Copiar apenas documentos mais relevantes (processando templates)
if [[ -d "$SCRIPT_DIR/docs" ]]; then
    mkdir -p "$PROJECT_ROOT/docs"
    
    # Lista de documentos essenciais
    ESSENTIAL_DOCS=(
        "QUICK_START.md"              # Guia rápido de 30 minutos
        "SETUP_VPS.md"                # Setup da VPS (uma vez)
        "SETUP_MINIKUBE.md"           # Setup do Minikube (uma vez)
        "DEPLOY_PROJECT.md"           # Deploy de projetos (VPS ou Minikube)
        "MULTIPLE_APPS.md"            # Múltiplas apps no mesmo VPS
        "TROUBLESHOOTING.md"          # Solução de problemas
        "FILE_STRUCTURE.md"           # Estrutura de arquivos
        "GITHUB_REGISTRY_SECRETS.md"  # Configuração de secrets
        "INDEX.md"                    # Índice de navegação
    )
    
    # Copiar e processar cada documento essencial
    for doc_name in "${ESSENTIAL_DOCS[@]}"; do
        doc_file="$SCRIPT_DIR/docs/$doc_name"
        if [[ -f "$doc_file" ]]; then
            output_file="$PROJECT_ROOT/docs/$doc_name"
            process_template "$doc_file" "$output_file"
            echo -e "  ${GREEN}✓${NC} $doc_name"
        fi
    done
    
    echo -e "${GREEN}✅ Documentação essencial copiada e personalizada${NC}"
fi

# Copiar README principal
if [[ -f "$SCRIPT_DIR/README.md" ]]; then
    process_template "$SCRIPT_DIR/README.md" "$PROJECT_ROOT/docs/SETUP_README.md"
fi

# Criar pasta scripts (se houver scripts úteis)
if ls "$SCRIPT_DIR"/*.sh >/dev/null 2>&1; then
    mkdir -p "$PROJECT_ROOT/scripts"
    # Copiar apenas scripts úteis (não o setup.sh)
    for script in "$SCRIPT_DIR"/*.sh; do
        script_name=$(basename "$script")
        if [[ "$script_name" != "setup.sh" ]]; then
            cp "$script" "$PROJECT_ROOT/scripts/" 2>/dev/null || true
        fi
    done
    echo -e "${GREEN}✅ Scripts copiados para ${PROJECT_ROOT}/scripts/${NC}"
fi

# Perguntar se deseja apagar a pasta kubernetes-vps-setup
echo -e "\n${YELLOW}🗑️  Deseja apagar a pasta kubernetes-vps-setup?${NC}"
echo -e "${CYAN}   A configuração já foi concluída e os arquivos importantes foram copiados.${NC}"
read -p "$(echo -e ${YELLOW}Apagar kubernetes-vps-setup? [s/N]:${NC} )" -n 1 -r DELETE_SETUP
echo

if [[ $DELETE_SETUP =~ ^[Ss]$ ]]; then
    echo -e "${YELLOW}🗑️  Removendo kubernetes-vps-setup...${NC}"
    cd "$PROJECT_ROOT"
    rm -rf kubernetes-vps-setup
    echo -e "${GREEN}✅ Pasta removida com sucesso!${NC}"
else
    echo -e "${CYAN}ℹ️  Pasta kubernetes-vps-setup mantida.${NC}"
    echo -e "${CYAN}   Você pode removê-la manualmente depois: ${YELLOW}rm -rf kubernetes-vps-setup${NC}"
fi

echo -e "\n${GREEN}✨ Configuração concluída! Boa sorte com seu projeto! 🚀${NC}\n"
