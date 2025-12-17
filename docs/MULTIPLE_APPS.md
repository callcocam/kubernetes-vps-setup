# 🚀 Múltiplos Apps Laravel na Mesma VPS

Guia completo para rodar vários apps Laravel na mesma VPS Kubernetes, cada um com seu próprio domínio e SSL.

## 📋 Índice

1. [Como Funciona](#como-funciona)
2. [Exemplo Prático](#exemplo-prático)
3. [Recursos e Limites](#recursos-e-limites)
4. [Comandos Úteis](#comandos-úteis)
5. [Troubleshooting](#troubleshooting)

---

## Como Funciona

### Arquitetura

```
VPS ({{VPS_IP}})
│
├── 🌐 Ingress Controller Nginx (COMPARTILHADO)
│   ├── {{DOMAIN}} → {{NAMESPACE}}
│   ├── outrodominio.com → meu-outro-app
│   └── terceiro.com → terceiro-app
│
├── 🔒 cert-manager (COMPARTILHADO)
│   ├── SSL para {{DOMAIN}}
│   ├── SSL para outrodominio.com
│   └── SSL para terceiro.com
│
├── 📦 Namespace: {{NAMESPACE}}
│   ├── App: {{REPLICAS}} réplicas
│   ├── PostgreSQL: 1 instância
│   └── Redis: 1 instância
│
├── 📦 Namespace: meu-outro-app
│   ├── App: 2 réplicas
│   ├── PostgreSQL: 1 instância
│   └── Redis: 1 instância
│
└── 📦 Namespace: terceiro-app
    ├── App: 1 réplica
    ├── PostgreSQL: 1 instância
    └── Redis: 1 instância
```

### Vantagens

✅ **Economia**: 1 VPS para múltiplos projetos
✅ **Isolamento**: Cada app em seu namespace separado
✅ **SSL Automático**: Certificado para cada domínio
✅ **Gerenciamento**: Todos no mesmo cluster Kubernetes

### O Que é Compartilhado

- ✅ Ingress Controller (Nginx)
- ✅ cert-manager (SSL)
- ✅ Recursos de CPU/RAM (distribuídos)
- ✅ Espaço em disco

### O Que é Isolado

- ✅ Namespace (isolamento lógico)
- ✅ PostgreSQL (banco dedicado em `/data/postgresql/NAMESPACE/`)
- ✅ Redis (cache dedicado em `/data/redis/NAMESPACE/`)
- ✅ Secrets e ConfigMaps
- ✅ Código da aplicação

> ⚠️ **IMPORTANTE**: Cada app TEM SEU PRÓPRIO diretório de dados na VPS!
> - **ERRADO**: `/data/postgresql` ← Todos os apps compartilham (BUG!)
> - **CORRETO**: `/data/postgresql/siscom`, `/data/postgresql/kb-app`, etc.

---

## ⚠️ Estrutura de Diretórios na VPS (CRÍTICO!)

Cada aplicação **PRECISA** ter seus diretórios isolados:

```bash
# Na VPS, estrutura correta:
/data/
├── postgresql/
│   ├── siscom/       ← Banco do app siscom
│   ├── kb-app/       ← Banco do app kb-app
│   └── fastconverter/ ← Banco do app fastconverter
└── redis/
    ├── siscom/       ← Cache do app siscom
    ├── kb-app/       ← Cache do app kb-app
    └── fastconverter/ ← Cache do app fastconverter
```

**Criar diretórios ANTES de aplicar manifests:**

```bash
# Para cada novo app:
ssh root@SEU_IP_VPS
mkdir -p /data/postgresql/NOME_DO_APP /data/redis/NOME_DO_APP
chmod 700 /data/postgresql/NOME_DO_APP
chmod 755 /data/redis/NOME_DO_APP
exit
```

> 🔴 **Se você NÃO fizer isso, múltiplos apps vão compartilhar o mesmo banco de dados e cache!**

---

## Exemplo Prático

### Cenário

**VPS**: {{VPS_IP}} (8GB RAM, 4 CPUs)

**Apps**:
1. **{{DOMAIN}}** (já rodando)
2. **loja.com** (novo)
3. **blog.dev** (novo)

### App 1: {{DOMAIN}} (já existe)

```bash
kubectl get all -n {{NAMESPACE}}
```

**Recursos alocados**:
- App: {{REPLICAS}} réplicas ({{MEM_REQUEST}}-{{MEM_LIMIT}} cada)
- PostgreSQL: 1Gi
- Redis: 256Mi
- **Total: ~2.5GB RAM**

---

### App 2: loja.com (NOVO)

#### Passo 1: Preparar projeto

```bash
# Clonar ou criar novo projeto Laravel
cd ~/projetos
git clone https://github.com/meu-usuario/minha-loja.git
cd minha-loja

# Copiar kubernetes-vps-setup
cp -r ~/kubernetes-vps-setup .
cd kubernetes-vps-setup
```

#### Passo 2: Executar configurador

```bash
./setup.sh
```

**Respostas**:
```
📦 Nome do projeto: loja
🏢 Namespace: loja-prod                    # ← DIFERENTE do app1
🌐 Domínio: loja.com                       # ← SEU DOMÍNIO
🖥️  IP da VPS: 148.230.78.184              # ← MESMO IP!
🔑 APP_KEY: [ENTER para gerar]
📧 Email: admin@loja.com
🗄️  Database: loja_db                      # ← DIFERENTE
👤 User DB: loja_user                      # ← DIFERENTE
🔐 Senha PostgreSQL: [ENTER para gerar]
🔐 Senha Redis: [ENTER para gerar]
☁️  DigitalOcean Spaces: n
💾 Réplicas: 2
💾 CPU Request/Limit: [ENTER] (padrão)
💾 Memory Request/Limit: [ENTER] (padrão)
```

#### Passo 3: Configurar DNS

No seu provedor de DNS (Cloudflare, etc):

| Tipo | Nome | Valor | Proxy |
|------|------|-------|-------|
| A | @ | 148.230.78.184 | DNS only |
| A | www | 148.230.78.184 | DNS only |

**Verificar DNS**:
```bash
dig loja.com
# Deve retornar: 148.230.78.184
```

#### Passo 4: Configurar GitHub Secrets

```bash
cd ~/projetos/minha-loja
gh auth login

# Configurar secrets
gh secret set APP_KEY --body "base64:sua-chave-aqui"

# KUBE_CONFIG (mesmo da VPS, pode reutilizar)
ssh root@148.230.78.184 'cat /etc/kubernetes/admin.conf' | base64 -w 0 | gh secret set KUBE_CONFIG --body-file -

# Verificar
gh secret list
```

#### Passo 5: Deploy

```bash
# Commit e push para disparar GitHub Actions
git add .
git commit -m "feat: adiciona configuração Kubernetes"
git push origin main

# Acompanhar deploy
gh run watch
```

**OU deploy manual:**

```bash
# Aplicar configurações
kubectl apply -f kubernetes/namespace.yaml
kubectl apply -f kubernetes/secrets.yaml
kubectl apply -f kubernetes/configmap.yaml
kubectl apply -f kubernetes/cert-issuer.yaml
kubectl apply -f kubernetes/postgres.yaml
kubectl apply -f kubernetes/redis.yaml

# Aguardar bancos
kubectl wait --for=condition=ready pod -l app=postgres -n loja-prod --timeout=120s
kubectl wait --for=condition=ready pod -l app=redis -n loja-prod --timeout=120s

# Aplicar app
kubectl apply -f kubernetes/deployment.yaml
kubectl apply -f kubernetes/service.yaml
kubectl apply -f kubernetes/ingress.yaml

# Executar migrations
kubectl apply -f kubernetes/migration-job.yaml
```

#### Passo 6: Verificar

```bash
# Ver pods do novo app
kubectl get pods -n loja-prod

# Ver ingress
kubectl get ingress -n loja-prod

# Ver certificado SSL (pode levar 2-5 min)
kubectl get certificate -n loja-prod

# Ver logs
kubectl logs -f deployment/app -n loja-prod
```

**Saída esperada**:
```
NAME                   READY   STATUS    RESTARTS   AGE
app-xxx                2/2     Running   0          2m
postgres-0             1/1     Running   0          3m
redis-0                1/1     Running   0          3m

NAME          CLASS   HOSTS              ADDRESS   PORTS     AGE
app-ingress   nginx   loja.com,www...              80, 443   3m

NAME      READY   SECRET    AGE
app-tls   True    app-tls   3m
```

#### Passo 7: Testar

```bash
# Testar HTTPS
curl -I https://loja.com

# Abrir no navegador
open https://loja.com
```

---

### App 3: blog.dev (NOVO)

Repita os mesmos passos do App 2, mudando:

```
📦 Nome: blog
🏢 Namespace: blog-prod          # ← DIFERENTE
🌐 Domínio: blog.dev             # ← DIFERENTE
🗄️  Database: blog_db            # ← DIFERENTE
👤 User DB: blog_user            # ← DIFERENTE
💾 Réplicas: 1                   # ← Menos réplicas (app menor)
```

---

## Recursos e Limites

### Capacidade da VPS

**Com 8GB RAM e 4 CPUs você pode rodar:**

| Cenário | Apps | Réplicas/App | Total Pods |
|---------|------|--------------|------------|
| Pequenos | 5-6 apps | 1-2 | ~15 pods |
| Médios | 3-4 apps | 2-3 | ~12 pods |
| Grandes | 2-3 apps | 3-4 | ~10 pods |

### Exemplo de Distribuição

**VPS 8GB RAM:**

| App | Réplicas | RAM/Réplica | PostgreSQL | Redis | Total |
|-----|----------|-------------|------------|-------|-------|
| app1 | 2 | 512Mi | 1Gi | 256Mi | ~2.5Gi |
| app2 | 2 | 512Mi | 1Gi | 256Mi | ~2.5Gi |
| app3 | 1 | 512Mi | 512Mi | 128Mi | ~1.2Gi |
| Sistema | - | - | - | - | ~1Gi |
| **TOTAL** | - | - | - | - | **~7.2Gi** |

### Monitorar Recursos

```bash
# Ver uso do node
kubectl top nodes

# Ver uso de todos os pods
kubectl top pods --all-namespaces

# Ver por namespace
kubectl top pods -n kb-app
kubectl top pods -n loja-prod
kubectl top pods -n blog-prod
```

### Ajustar Recursos

Se um app precisar de mais recursos, edite o deployment:

```bash
kubectl edit deployment app -n loja-prod
```

Ou atualize o arquivo `kubernetes/deployment.yaml` e reaplique:

```yaml
resources:
  requests:
    memory: "512Mi"   # ← Aumentar
    cpu: "250m"
  limits:
    memory: "1Gi"     # ← Aumentar
    cpu: "500m"
```

```bash
kubectl apply -f kubernetes/deployment.yaml
```

---

## Comandos Úteis

### Ver Todos os Apps

```bash
# Listar todos os namespaces
kubectl get namespaces

# Ver todos os ingress
kubectl get ingress --all-namespaces

# Ver todos os certificados
kubectl get certificates --all-namespaces

# Ver todos os pods
kubectl get pods --all-namespaces
```

### Gerenciar App Específico

```bash
# Substituir <namespace> pelo nome do seu app

# Ver tudo do namespace
kubectl get all -n <namespace>

# Ver logs
kubectl logs -f deployment/app -n <namespace>

# Executar comando no pod
kubectl exec -it deployment/app -n <namespace> -- bash

# Ver eventos
kubectl get events -n <namespace> --sort-by='.lastTimestamp'

# Reiniciar deployment
kubectl rollout restart deployment/app -n <namespace>

# Ver histórico de deploys
kubectl rollout history deployment/app -n <namespace>

# Rollback (se necessário)
kubectl rollout undo deployment/app -n <namespace>
```

### Migrations por App

```bash
# App 1
kubectl exec -it deployment/app -n kb-app -- php artisan migrate

# App 2
kubectl exec -it deployment/app -n loja-prod -- php artisan migrate

# App 3
kubectl exec -it deployment/app -n blog-prod -- php artisan migrate
```

### Limpar Namespace (CUIDADO!)

```bash
# Deletar TUDO de um app (IRREVERSÍVEL!)
kubectl delete namespace <namespace>

# Isso deleta: pods, services, deployments, PVCs, dados do banco!
# Use apenas se quiser remover completamente o app
```

---

## Troubleshooting

### SSL não criado para novo app

```bash
# Ver status do certificado
kubectl describe certificate app-tls -n <namespace>

# Ver challenges
kubectl get challenges -n <namespace>

# Ver logs do cert-manager
kubectl logs -n cert-manager -l app=cert-manager

# Causas comuns:
# 1. DNS não propagou (aguarde 10-30 min)
# 2. Email inválido no cert-issuer.yaml
# 3. Rate limit do Let's Encrypt (max 50 certs/semana)
```

### Pods ficam em "Pending"

```bash
# Ver por que não agendou
kubectl describe pod <pod-name> -n <namespace>

# Causa comum: Falta de recursos
# Solução: Reduzir réplicas ou recursos de outros apps
kubectl scale deployment app --replicas=1 -n <namespace-menos-importante>
```

### Domínio não abre (502/504)

```bash
# 1. Verificar se pods estão rodando
kubectl get pods -n <namespace>

# 2. Ver logs dos pods
kubectl logs deployment/app -n <namespace>

# 3. Verificar ingress
kubectl describe ingress app-ingress -n <namespace>

# 4. Ver logs do ingress controller
kubectl logs -n ingress-nginx -l app.kubernetes.io/component=controller
```

### Banco de dados não conecta

```bash
# Verificar se PostgreSQL está rodando
kubectl get pods -n <namespace> -l app=postgres

# Ver logs do PostgreSQL
kubectl logs postgres-0 -n <namespace>

# Testar conexão manualmente
kubectl exec -it deployment/app -n <namespace> -- php artisan tinker
# No tinker:
DB::connection()->getPdo();
```

### Um app afetando outros (recursos)

```bash
# Ver qual app está consumindo mais
kubectl top pods --all-namespaces --sort-by=memory

# Opções:
# 1. Reduzir réplicas do app problemático
kubectl scale deployment app --replicas=1 -n <namespace>

# 2. Definir limites mais rígidos
kubectl edit deployment app -n <namespace>
# Ajustar resources.limits

# 3. Mover app para outra VPS
```

---

## Resumo Rápido

### Para Adicionar Novo App:

1. ✅ Preparar projeto Laravel
2. ✅ Executar `./setup.sh` com namespace único
3. ✅ Configurar DNS do novo domínio → IP da VPS
4. ✅ Configurar GitHub Secrets
5. ✅ Deploy (`git push` ou `kubectl apply`)
6. ✅ Aguardar SSL (2-5 min)
7. ✅ Testar `https://novo-dominio.com`

### Checklist Antes de Adicionar:

- [ ] VPS tem recursos suficientes?
- [ ] Domínio está configurado e propagado?
- [ ] Namespace é único (não conflita)?
- [ ] GitHub Secrets configurados?
- [ ] Testou localmente antes?

### Limites Recomendados:

- **4GB RAM**: 2-3 apps pequenos
- **8GB RAM**: 3-5 apps médios
- **16GB RAM**: 5-8 apps médios ou 3-4 grandes

---

## Próximos Passos

Depois de ter múltiplos apps rodando:

1. **Monitoramento**: Configure Prometheus + Grafana
2. **Backup**: Automatize backup dos bancos
3. **Logs Centralizados**: Configure ELK ou Loki
4. **Alertas**: Configure alertas de recursos
5. **Upgrade**: Considere mais RAM/CPU se necessário

---

**🎉 Pronto! Agora você pode rodar quantos apps quiser na mesma VPS!**

Cada app com seu domínio, SSL, banco e cache isolados. Tudo gerenciado por Kubernetes! 🚀
