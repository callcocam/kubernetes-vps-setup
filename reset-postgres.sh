#!/bin/bash

# 🔄 Script de Reset do PostgreSQL
# Este script limpa completamente o PostgreSQL e recria do zero
# Use quando houver problemas com dados antigos ou credenciais incorretas

set -e

# Cores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${RED}"
echo "╔════════════════════════════════════════════════════════════════╗"
echo "║  ⚠️  RESET COMPLETO DO POSTGRESQL                             ║"
echo "║  Este script VAI DELETAR TODOS OS DADOS do PostgreSQL!        ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo -e "${NC}"

# Verificar se namespace foi fornecido
if [[ -z "$1" ]]; then
    echo -e "${RED}Erro: Namespace não fornecido${NC}"
    echo -e "${YELLOW}Uso: $0 <namespace>${NC}"
    echo -e "${YELLOW}Exemplo: $0 meu-app${NC}"
    exit 1
fi

NAMESPACE="$1"

echo -e "${YELLOW}⚠️  Você está prestes a deletar TODOS os dados do PostgreSQL no namespace: ${RED}${NAMESPACE}${NC}"
echo -e "${YELLOW}⚠️  Esta ação é IRREVERSÍVEL!${NC}\n"

read -p "$(echo -e ${YELLOW}Digite o nome do namespace para confirmar: ${NC})" confirm

if [[ "$confirm" != "$NAMESPACE" ]]; then
    echo -e "${RED}❌ Confirmação incorreta. Operação cancelada.${NC}"
    exit 1
fi

echo -e "\n${BLUE}🔄 Iniciando reset do PostgreSQL...${NC}\n"

# 1. Deletar StatefulSet
echo -e "${YELLOW}1/7${NC} ${CYAN}Deletando StatefulSet...${NC}"
kubectl delete statefulset postgres -n "$NAMESPACE" --ignore-not-found=true
echo -e "${GREEN}✓ StatefulSet deletado${NC}\n"

# 2. Deletar PVC
echo -e "${YELLOW}2/7${NC} ${CYAN}Deletando PersistentVolumeClaim...${NC}"
kubectl delete pvc postgres-pvc -n "$NAMESPACE" --ignore-not-found=true
echo -e "${GREEN}✓ PVC deletado${NC}\n"

# 3. Deletar PV
echo -e "${YELLOW}3/7${NC} ${CYAN}Deletando PersistentVolume...${NC}"
PV_NAME=$(kubectl get pv -o json | jq -r ".items[] | select(.spec.claimRef.namespace==\"$NAMESPACE\" and .spec.claimRef.name==\"postgres-pvc\") | .metadata.name" 2>/dev/null || echo "")
if [[ -n "$PV_NAME" ]]; then
    kubectl delete pv "$PV_NAME" --ignore-not-found=true
    echo -e "${GREEN}✓ PV $PV_NAME deletado${NC}\n"
else
    echo -e "${YELLOW}ℹ️  Nenhum PV encontrado (ok se for hostPath)${NC}\n"
fi

# 4. Deletar Service
echo -e "${YELLOW}4/7${NC} ${CYAN}Deletando Service...${NC}"
kubectl delete service postgres-service -n "$NAMESPACE" --ignore-not-found=true
echo -e "${GREEN}✓ Service deletado${NC}\n"

# 5. Limpar dados na VPS
echo -e "${YELLOW}5/7${NC} ${CYAN}Limpando dados persistidos na VPS...${NC}"
echo -e "${YELLOW}⚠️  Conecte na VPS e execute:${NC}"
echo -e "${GREEN}ssh root@SEU_IP_VPS${NC}"
echo -e "${GREEN}sudo rm -rf /data/postgresql/${NAMESPACE}${NC}"
echo -e "${GREEN}sudo mkdir -p /data/postgresql/${NAMESPACE}${NC}"
echo -e "${GREEN}sudo chmod 700 /data/postgresql/${NAMESPACE}${NC}"
echo -e "${GREEN}exit${NC}\n"

read -p "$(echo -e ${YELLOW}Pressione ENTER após executar os comandos acima na VPS...${NC})"

# 6. Recriar PostgreSQL
echo -e "\n${YELLOW}6/7${NC} ${CYAN}Recriando PostgreSQL...${NC}"
if [[ -f "kubernetes/postgres.yaml" ]]; then
    kubectl apply -f kubernetes/postgres.yaml
    echo -e "${GREEN}✓ PostgreSQL recriado${NC}\n"
else
    echo -e "${RED}❌ Erro: kubernetes/postgres.yaml não encontrado${NC}"
    exit 1
fi

# 7. Aguardar PostgreSQL ficar pronto
echo -e "${YELLOW}7/7${NC} ${CYAN}Aguardando PostgreSQL ficar pronto...${NC}"
kubectl wait --for=condition=ready pod -l app=postgres -n "$NAMESPACE" --timeout=120s

echo -e "\n${GREEN}✅ PostgreSQL resetado com sucesso!${NC}\n"

# Verificar
echo -e "${BLUE}🔍 Verificando...${NC}"
kubectl get pods -n "$NAMESPACE" -l app=postgres

echo -e "\n${BLUE}📝 Próximos passos:${NC}"
echo -e "1. Verificar logs: ${GREEN}kubectl logs postgres-0 -n $NAMESPACE${NC}"
echo -e "2. Testar conexão: ${GREEN}kubectl exec postgres-0 -n $NAMESPACE -- psql -U \$DB_USER -d \$DB_NAME -c 'SELECT current_user;'${NC}"
echo -e "3. Executar migrations: ${GREEN}kubectl apply -f kubernetes/migration-job.yaml${NC}\n"
