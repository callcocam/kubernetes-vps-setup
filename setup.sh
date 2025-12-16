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
echo "║  🚀 Configurador Kubernetes para Laravel                      ║"
echo "║  Versão 1.0.0                                                  ║"
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
echo -e "${GREEN}  DOCKER HUB${NC}"
echo -e "${GREEN}═══════════════════════════════════════════════════════════════${NC}\n"

# Docker Hub
read_input "🐳 Usuário do Docker Hub:" "" DOCKER_USERNAME
DOCKER_IMAGE="${DOCKER_USERNAME}/${PROJECT_NAME}"

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
echo -e "${GREEN}  RECURSOS (CPU/MEMÓRIA)${NC}"
echo -e "${GREEN}═══════════════════════════════════════════════════════════════${NC}\n"

read_input "💾 Memória mínima (ex: 256Mi, 512Mi):" "256Mi" MEM_REQUEST
read_input "💾 Memória máxima (ex: 512Mi, 1Gi):" "512Mi" MEM_LIMIT
read_input "⚡ CPU mínima (ex: 250m, 500m):" "250m" CPU_REQUEST
read_input "⚡ CPU máxima (ex: 500m, 1000m):" "500m" CPU_LIMIT
read_input "📊 Número de réplicas:" "2" REPLICAS

# Resumo
echo -e "\n${PURPLE}═══════════════════════════════════════════════════════════════${NC}"
echo -e "${PURPLE}  RESUMO DA CONFIGURAÇÃO${NC}"
echo -e "${PURPLE}═══════════════════════════════════════════════════════════════${NC}\n"

echo -e "${CYAN}Projeto:${NC}"
echo -e "  Nome: ${GREEN}${PROJECT_NAME}${NC}"
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
DOCKER_DIR="$PROJECT_ROOT/docker"
GITHUB_DIR="$PROJECT_ROOT/.github/workflows"

echo -e "\n${YELLOW}⏳ Criando estrutura de diretórios...${NC}"
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
    sed -i "s|{{DOCKER_USERNAME}}|${DOCKER_USERNAME}|g" "$output_file"
    sed -i "s|{{DOCKER_IMAGE}}|${DOCKER_IMAGE}|g" "$output_file"
    sed -i "s|{{APP_KEY}}|${APP_KEY}|g" "$output_file"
    sed -i "s|{{APP_EMAIL}}|${APP_EMAIL}|g" "$output_file"
    sed -i "s|{{DB_NAME}}|${DB_NAME}|g" "$output_file"
    sed -i "s|{{DB_USER}}|${DB_USER}|g" "$output_file"
    sed -i "s|{{DB_PASSWORD}}|${DB_PASSWORD}|g" "$output_file"
    sed -i "s|{{REDIS_PASSWORD}}|${REDIS_PASSWORD}|g" "$output_file"
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
    
    echo -e "${GREEN}✅${NC} $(basename "$output_file")"
}

echo -e "\n${YELLOW}⏳ Gerando arquivos Kubernetes...${NC}"

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

echo -e "\n${YELLOW}⏳ Gerando arquivos Docker...${NC}"

# Processar templates Docker
process_template "$SCRIPT_DIR/Dockerfile.stub" "$PROJECT_ROOT/Dockerfile"
process_template "$SCRIPT_DIR/docker/nginx/default.conf.stub" "$DOCKER_DIR/nginx/default.conf"
process_template "$SCRIPT_DIR/docker/supervisor/supervisord.conf.stub" "$DOCKER_DIR/supervisor/supervisord.conf"
process_template "$SCRIPT_DIR/.dockerignore.stub" "$PROJECT_ROOT/.dockerignore"

echo -e "\n${YELLOW}⏳ Gerando GitHub Actions...${NC}"

# Processar template GitHub Actions
process_template "$SCRIPT_DIR/.github/workflows/deploy.yml.stub" "$GITHUB_DIR/deploy.yml"

# Criar arquivo de configuração para referência
CONFIG_FILE="$OUTPUT_DIR/.config"
cat > "$CONFIG_FILE" << EOF
# Configuração gerada em $(date)
PROJECT_NAME=${PROJECT_NAME}
NAMESPACE=${NAMESPACE}
DOMAIN=${DOMAIN}
VPS_IP=${VPS_IP}
DOCKER_USERNAME=${DOCKER_USERNAME}
DOCKER_IMAGE=${DOCKER_IMAGE}
DB_NAME=${DB_NAME}
DB_USER=${DB_USER}
EOF

echo -e "\n${GREEN}═══════════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}  ✅ ARQUIVOS GERADOS COM SUCESSO!${NC}"
echo -e "${GREEN}═══════════════════════════════════════════════════════════════${NC}\n"

echo -e "${CYAN}📂 Arquivos criados em:${NC}"
echo -e "  ${GREEN}kubernetes/${NC} - Configurações Kubernetes"
echo -e "  ${GREEN}docker/${NC} - Configurações Docker"
echo -e "  ${GREEN}.github/workflows/${NC} - CI/CD"
echo -e "  ${GREEN}Dockerfile${NC} - Build da imagem"

echo -e "\n${PURPLE}═══════════════════════════════════════════════════════════════${NC}"
echo -e "${PURPLE}  📋 PRÓXIMOS PASSOS${NC}"
echo -e "${PURPLE}═══════════════════════════════════════════════════════════════${NC}\n"

echo -e "${YELLOW}1.${NC} ${CYAN}Na VPS, criar os diretórios de dados:${NC}"
echo -e "   ${GREEN}ssh root@${VPS_IP}${NC}"
echo -e "   ${GREEN}mkdir -p /data/postgresql /data/redis${NC}"
echo -e "   ${GREEN}chmod 700 /data/postgresql && chmod 755 /data/redis${NC}"
echo -e ""
echo -e "${YELLOW}2.${NC} ${CYAN}Configurar GitHub Secrets:${NC}"
echo -e "   ${GREEN}gh secret set DOCKER_HUB_USERNAME --body \"${DOCKER_USERNAME}\"${NC}"
echo -e "   ${GREEN}gh secret set DOCKER_HUB_TOKEN${NC}"
echo -e "   ${GREEN}gh secret set APP_KEY --body \"${APP_KEY}\"${NC}"
echo -e "   ${GREEN}gh secret set KUBECONFIG < ~/.kube/config${NC}"
echo -e ""
echo -e "${YELLOW}3.${NC} ${CYAN}Configurar DNS (no seu provedor):${NC}"
echo -e "   Tipo: ${GREEN}A${NC}"
echo -e "   Nome: ${GREEN}@${NC}"
echo -e "   Valor: ${GREEN}${VPS_IP}${NC}"
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
echo -e "   ${GREEN}https://${DOMAIN}${NC}"

echo -e "\n${GREEN}✨ Configuração concluída! Boa sorte com seu deploy! 🚀${NC}\n"
