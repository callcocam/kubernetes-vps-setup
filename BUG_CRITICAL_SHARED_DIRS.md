# 🔴 BUG CRÍTICO CORRIGIDO: Diretórios PostgreSQL/Redis Compartilhados

**Data:** 17/12/2025  
**Severidade:** 🔴🔴🔴 **CRÍTICO**  
**Status:** ✅ **CORRIGIDO** em templates  
**Afeta:** Projetos com múltiplos apps na mesma VPS

---

## ⚠️ O Problema

### Bug Descoberto
Todos os aplicativos deployados na mesma VPS estavam usando os **MESMOS diretórios** para dados:
- `/data/postgresql` ← **TODOS** os apps!
- `/data/redis` ← **TODOS** os apps!

### Impacto Real Observado

**VPS com 3 apps:**
- siscom
- kb-app  
- fastconverter

**Todos compartilhando:**
- ❌ Mesmo banco de dados PostgreSQL
- ❌ Mesmo cache Redis
- ❌ Dados misturados entre apps
- ❌ Migrations de um app afetando outros
- ❌ Usuários/senhas conflitantes

### Por Que Isso Aconteceu?

**Arquivo:** `templates/postgres.yaml.stub` (linha 13)
```yaml
# ANTES (ERRADO):
hostPath:
  path: /data/postgresql  ← FIXO! Todos usam o mesmo!
```

**Arquivo:** `templates/redis.yaml.stub` (linha 13)
```yaml
# ANTES (ERRADO):
hostPath:
  path: /data/redis  ← FIXO! Todos usam o mesmo!
```

---

## ✅ Correção Aplicada

### Templates Atualizados

**postgres.yaml.stub:**
```yaml
# DEPOIS (CORRETO):
hostPath:
  path: /data/postgresql/{{NAMESPACE}}  ← Isolado por app!
```

**redis.yaml.stub:**
```yaml
# DEPOIS (CORRETO):
hostPath:
  path: /data/redis/{{NAMESPACE}}  ← Isolado por app!
```

### Resultado
Agora cada app tem seus próprios diretórios:
```
/data/
├── postgresql/
│   ├── siscom/       ← Isolado
│   ├── kb-app/       ← Isolado
│   └── fastconverter/ ← Isolado
└── redis/
    ├── siscom/       ← Isolado
    ├── kb-app/       ← Isolado
    └── fastconverter/ ← Isolado
```

---

## 📋 Arquivos Modificados

### 1. Templates
- ✅ `templates/postgres.yaml.stub` - Linha 13
- ✅ `templates/redis.yaml.stub` - Linha 13

### 2. Scripts
- ✅ `setup.sh` - Comandos de criação de diretórios
- ✅ `reset-postgres.sh` - Path correto por namespace

### 3. Documentação
- ✅ `docs/QUICK_START.md` - Comandos atualizados
- ✅ `docs/TROUBLESHOOTING.md` - Bug #4 adicionado
- ✅ `docs/MULTIPLE_APPS.md` - Seção crítica de isolamento

---

## 🚨 Migração para Projetos Existentes

### Você Já Tem Apps Deployados?

Se você deployou apps ANTES dessa correção, **PRECISA MIGRAR**!

#### Passo 1: Verificar se está afetado

```bash
# Ver paths atuais
kubectl get pv | grep postgres
kubectl describe pv postgres-pv-siscom | grep Path

# Se mostrar apenas "/data/postgresql" → AFETADO!
# Se mostrar "/data/postgresql/siscom" → OK!
```

#### Passo 2: Criar novos diretórios na VPS

```bash
ssh root@SEU_IP_VPS

# Para cada app existente:
mkdir -p /data/postgresql/siscom /data/redis/siscom
mkdir -p /data/postgresql/kb-app /data/redis/kb-app
mkdir -p /data/postgresql/fastconverter /data/redis/fastconverter

chmod 700 /data/postgresql/*
chmod 755 /data/redis/*

exit
```

#### Passo 3: Atualizar manifests de cada app

**Para cada app, editar `kubernetes/postgres.yaml`:**

```yaml
# ANTES:
  hostPath:
    path: /data/postgresql

# DEPOIS:
  hostPath:
    path: /data/postgresql/siscom  # ← Usar nome do seu app!
```

**E `kubernetes/redis.yaml`:**

```yaml
# ANTES:
  hostPath:
    path: /data/redis

# DEPOIS:
  hostPath:
    path: /data/redis/siscom  # ← Usar nome do seu app!
```

#### Passo 4: Fazer backup (OPCIONAL mas recomendado)

```bash
# Na VPS, fazer backup antes de migrar
ssh root@SEU_IP_VPS

# Se /data/postgresql tem dados importantes:
cp -r /data/postgresql /data/postgresql.backup
cp -r /data/redis /data/redis.backup

exit
```

#### Passo 5: Reset e recriar (POR APP)

**⚠️ Fazer 1 app por vez!**

```bash
# 1. Deletar recursos do app
kubectl delete statefulset postgres redis -n siscom
kubectl delete pvc postgres-pvc redis-pvc -n siscom

# 2. Aplicar manifests atualizados
kubectl apply -f kubernetes/postgres.yaml
kubectl apply -f kubernetes/redis.yaml

# 3. Aguardar ficar pronto
kubectl wait --for=condition=ready pod -l app=postgres -n siscom --timeout=120s
kubectl wait --for=condition=ready pod -l app=redis -n siscom --timeout=120s

# 4. Executar migrations
kubectl delete job migration -n siscom --ignore-not-found=true
kubectl apply -f kubernetes/migration-job.yaml

# 5. Verificar
kubectl get pods -n siscom
```

#### Passo 6: Repetir para outros apps

```bash
# kb-app
kubectl delete statefulset postgres redis -n kb-app
kubectl delete pvc postgres-pvc redis-pvc -n kb-app
kubectl apply -f kubernetes/postgres.yaml
kubectl apply -f kubernetes/redis.yaml
# ... migrations ...

# fastconverter
kubectl delete statefulset postgres redis -n fastconverter
kubectl delete pvc postgres-pvc redis-pvc -n fastconverter
kubectl apply -f kubernetes/postgres.yaml
kubectl apply -f kubernetes/redis.yaml
# ... migrations ...
```

---

## 🎯 Para Novos Projetos

### Boa Notícia!

✅ **Se você usar o template ATUAL, já está correto!**

Ao executar `./setup.sh`, os arquivos gerados já terão:
- `path: /data/postgresql/{{NAMESPACE}}`
- `path: /data/redis/{{NAMESPACE}}`

### Comandos Corretos

```bash
# O setup.sh agora mostra:
mkdir -p /data/postgresql/meu-app /data/redis/meu-app
chmod 700 /data/postgresql/meu-app
chmod 755 /data/redis/meu-app
```

---

## 📊 Resumo de Impacto

### Antes da Correção
```
❌ siscom, kb-app, fastconverter → /data/postgresql (MESMO!)
❌ Conflito total de dados
❌ Migrations conflitantes
❌ Usuários sobrescrevendo uns aos outros
```

### Depois da Correção
```
✅ siscom → /data/postgresql/siscom
✅ kb-app → /data/postgresql/kb-app
✅ fastconverter → /data/postgresql/fastconverter
✅ Cada app isolado
✅ Sem conflitos
```

---

## ✅ Checklist de Validação

Para cada app, verificar:

```bash
# 1. PV aponta para path correto?
kubectl describe pv postgres-pv-siscom | grep Path
# Esperado: /data/postgresql/siscom

# 2. Diretório existe na VPS?
ssh root@SEU_IP_VPS ls -la /data/postgresql/
# Deve listar: siscom/ kb-app/ fastconverter/

# 3. Pods rodando?
kubectl get pods -n siscom
# postgres-0: Running
# redis-0: Running

# 4. Migrations OK?
kubectl logs job/migration -n siscom
# Sem erros de autenticação
```

---

## 🔮 Prevenção Futura

### Adicionado aos Templates
- ✅ Paths isolados por padrão
- ✅ Documentação clara em MULTIPLE_APPS.md
- ✅ Aviso crítico sobre isolamento

### Adicionado à Documentação
- ✅ TROUBLESHOOTING.md → Bug #4
- ✅ MULTIPLE_APPS.md → Seção de isolamento
- ✅ Este documento (BUG_CRITICAL_SHARED_DIRS.md)

### Scripts Atualizados
- ✅ setup.sh → Comandos corretos
- ✅ reset-postgres.sh → Path por namespace

---

## 📞 Suporte

**Se você encontrar problemas ao migrar:**

1. Verifique logs: `kubectl logs postgres-0 -n seu-app`
2. Consulte: [TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md) - Bug #4
3. Use script: `./reset-postgres.sh seu-namespace`

---

**Descoberto por:** Análise de ambiente real (siscom, kb-app, fastconverter)  
**Corrigido em:** 17/12/2025  
**Commit:** TBD  
**Status:** ✅ Templates corrigidos, migração documentada
