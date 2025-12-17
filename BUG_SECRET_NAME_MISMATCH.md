# 🐛 Bug Corrigido: Inconsistência no Nome do Secret

**Data:** 17/12/2025  
**Severidade:** 🟡 Médio  
**Status:** ✅ **CORRIGIDO**  
**Afeta:** Configuração de GitHub Secrets

---

## ⚠️ O Problema

### Bug Descoberto
Inconsistência no nome do secret do Kubernetes entre diferentes arquivos:

**setup-github-secrets.sh:**
```bash
gh secret set KUBECONFIG  # ← SEM underscore
```

**deploy.yml.stub:**
```yaml
echo "${{ secrets.KUBE_CONFIG }}"  # ← COM underscore
```

**setup.sh:**
```bash
gh secret set KUBE_CONFIG  # ← COM underscore
```

### Impacto
- GitHub Actions falha: "Secret KUBE_CONFIG not found"
- Ou o contrário: "Secret KUBECONFIG not found"
- Confusão ao configurar secrets
- Deploy não funciona

---

## ✅ Correção Aplicada

### Padronização

**Nome oficial:** `KUBE_CONFIG` (com underscore)

### Arquivo Corrigido

**setup-github-secrets.sh:**
```bash
# ANTES:
gh secret set KUBECONFIG -b"$KUBECONFIG_BASE64"

# DEPOIS:
gh secret set KUBE_CONFIG -b"$KUBE_CONFIG_BASE64"
```

---

## 📋 Verificação

### Checar Nome do Secret

```bash
# Listar secrets do repositório
gh secret list

# Deve aparecer:
# KUBE_CONFIG  ← CORRETO (com underscore)
# APP_KEY

# Se aparecer KUBECONFIG (sem underscore) → INCORRETO!
```

### Corrigir Secret Existente

```bash
# 1. Deletar secret antigo (se existir)
gh secret delete KUBECONFIG

# 2. Criar com nome correto
kubectl config view --flatten --minify | base64 -w 0 | gh secret set KUBE_CONFIG --body-file -

# 3. Verificar
gh secret list
# Deve mostrar: KUBE_CONFIG ✓
```

---

## 🎯 Padronização Final

### Todos os Arquivos Usam `KUBE_CONFIG`

- ✅ `setup.sh` → `gh secret set KUBE_CONFIG`
- ✅ `setup-github-secrets.sh` → `gh secret set KUBE_CONFIG`
- ✅ `.github/workflows/deploy.yml.stub` → `secrets.KUBE_CONFIG`
- ✅ Documentação → `KUBE_CONFIG`

### Nome Correto
```
KUBE_CONFIG  ← Use sempre este! (com underscore)
```

---

## 📊 Resumo

### Antes
```
❌ setup-github-secrets.sh → KUBECONFIG (sem _)
❌ deploy.yml              → KUBE_CONFIG (com _)
❌ setup.sh                → KUBE_CONFIG (com _)
❌ INCONSISTENTE!
```

### Depois
```
✅ setup-github-secrets.sh → KUBE_CONFIG (com _)
✅ deploy.yml              → KUBE_CONFIG (com _)
✅ setup.sh                → KUBE_CONFIG (com _)
✅ CONSISTENTE!
```

---

## ✅ Checklist

Para cada repositório, verificar:

```bash
# 1. Listar secrets
gh secret list

# 2. Deve aparecer KUBE_CONFIG (não KUBECONFIG)
# Se aparecer errado:
gh secret delete KUBECONFIG
kubectl config view --flatten --minify | base64 -w 0 | gh secret set KUBE_CONFIG --body-file -

# 3. Testar workflow
gh workflow run deploy.yml
gh run watch
```

---

**Descoberto por:** Revisão de código  
**Corrigido em:** 17/12/2025  
**Arquivo modificado:** `setup-github-secrets.sh`  
**Documentado em:** `TROUBLESHOOTING.md` - Bug #5  
**Status:** ✅ Padronizado em todos os arquivos
