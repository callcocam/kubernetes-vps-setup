#!/bin/bash

echo "🔧 Configurando GitHub Actions Secrets"
echo "======================================"
echo ""

# Cores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Verificar gh CLI
if ! command -v gh &> /dev/null; then
    echo -e "${RED}❌ GitHub CLI (gh) não encontrado!${NC}"
    echo "Instale: https://cli.github.com/"
    echo ""
    echo "Ubuntu/Debian:"
    echo "  curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg"
    echo "  echo \"deb [signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main\" | sudo tee /etc/apt/sources.list.d/github-cli.list"
    echo "  sudo apt update && sudo apt install gh"
    exit 1
fi

# Verificar autenticação
if ! gh auth status &> /dev/null; then
    echo -e "${YELLOW}⚠️  Não está autenticado no GitHub${NC}"
    echo "Execute: gh auth login"
    exit 1
fi

echo -e "${GREEN}✅ GitHub CLI configurado${NC}"
echo ""

# Obter repository
REPO=$(git config --get remote.origin.url | sed 's/.*github.com[:/]\(.*\)\.git/\1/')
if [ -z "$REPO" ]; then
    echo -e "${RED}❌ Não foi possível detectar o repositório GitHub${NC}"
    echo "Certifique-se de estar dentro de um repositório git com remote configurado."
    exit 1
fi

echo -e "${BLUE}📦 Repositório: ${REPO}${NC}"
echo ""

# 1. APP_KEY
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${CYAN}🔑 1. APP_KEY do Laravel${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo "Gere a chave com: php artisan key:generate --show"
echo ""
read -p "Cole a APP_KEY aqui: " APP_KEY

if [ -n "$APP_KEY" ]; then
    gh secret set APP_KEY -b"$APP_KEY" -R "$REPO"
    echo -e "${GREEN}✅ APP_KEY configurada${NC}"
else
    echo -e "${YELLOW}⚠️  APP_KEY pulada${NC}"
fi
echo ""

# 2. KUBE_CONFIG
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${CYAN}☸️  2. KUBE_CONFIG (Kubernetes)${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo "Cole o conteúdo do seu ~/.kube/config"
echo ""
echo -e "${YELLOW}⚠️  IMPORTANTE:${NC} Substitua o IP interno (10.x.x.x) pelo IP público da VPS!"
echo "   Exemplo: server: https://SEU_IP_VPS:6443"
echo ""
echo "Pressione ${GREEN}Ctrl+D${NC} quando terminar de colar:"
echo ""
KUBE_CONFIG_CONTENT=$(cat)

if [ -n "$KUBE_CONFIG_CONTENT" ]; then
    gh secret set KUBE_CONFIG -b"$KUBE_CONFIG_CONTENT" -R "$REPO"
    echo ""
    echo -e "${GREEN}✅ KUBE_CONFIG configurado${NC}"
else
    echo ""
    echo -e "${YELLOW}⚠️  KUBE_CONFIG pulado${NC}"
fi
echo ""

# 3. GHCR_TOKEN (GitHub Container Registry)
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${CYAN}🐳 3. GHCR_TOKEN (GitHub Container Registry)${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo "Geralmente não é necessário! O GitHub Actions tem acesso ao GHCR automaticamente."
echo ""
read -p "Deseja configurar GHCR_TOKEN manualmente? (s/N): " SETUP_GHCR

if [[ "$SETUP_GHCR" =~ ^[Ss]$ ]]; then
    echo ""
    echo "Crie um Personal Access Token em:"
    echo "https://github.com/settings/tokens/new"
    echo ""
    echo "Permissões necessárias:"
    echo "  - write:packages"
    echo "  - read:packages"
    echo "  - delete:packages"
    echo ""
    read -sp "Cole o token aqui: " GHCR_TOKEN
    echo ""
    
    if [ -n "$GHCR_TOKEN" ]; then
        gh secret set GHCR_TOKEN -b"$GHCR_TOKEN" -R "$REPO"
        echo -e "${GREEN}✅ GHCR_TOKEN configurado${NC}"
    else
        echo -e "${YELLOW}⚠️  GHCR_TOKEN pulado${NC}"
    fi
else
    echo -e "${GREEN}✅ Usando GITHUB_TOKEN automático${NC}"
fi
echo ""

echo "======================================"
echo -e "${GREEN}🎉 Configuração completa!${NC}"
echo ""
echo "📝 Secrets configurados:"
gh secret list -R "$REPO"
echo ""
echo -e "${CYAN}🚀 Próximos passos:${NC}"
echo ""
echo "1. ${GREEN}git add .${NC}"
echo "2. ${GREEN}git commit -m 'feat: Add Kubernetes configuration'${NC}"
echo "3. ${GREEN}git push origin main${NC}"
echo ""
echo "O deploy será feito automaticamente pelo GitHub Actions! 🎊"
echo ""
