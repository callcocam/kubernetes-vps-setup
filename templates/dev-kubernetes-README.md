# 📁 .dev/kubernetes/ - Manifests Locais (Minikube)

Este diretório contém os **manifests Kubernetes para ambiente local** (Minikube).

## 🔑 Diferenças entre `.dev/kubernetes/` e `kubernetes/`

| Característica | `.dev/kubernetes/` | `kubernetes/` |
|---|---|---|
| **Imagens** | Local (ex: `callcocam/app:latest`) | GHCR (ex: `ghcr.io/callcocam/app:latest`) |
| **Ambiente** | Minikube (desenvolvimento local) | VPS (produção) |
| **Git** | ❌ Ignorado (`.gitignore`) | ✅ Commitado |
| **SSL** | ❌ Sem cert-issuer | ✅ Com Let's Encrypt |

## 🎯 Como Usar (Minikube)

```bash
# Aplicar todos os manifests
kubectl apply -f .dev/kubernetes/

# Ou aplicar individualmente
kubectl apply -f .dev/kubernetes/namespace.yaml
kubectl apply -f .dev/kubernetes/secrets.yaml
kubectl apply -f .dev/kubernetes/configmap.yaml
kubectl apply -f .dev/kubernetes/postgres.yaml
kubectl apply -f .dev/kubernetes/redis.yaml
kubectl apply -f .dev/kubernetes/deployment.yaml
kubectl apply -f .dev/kubernetes/service.yaml
kubectl apply -f .dev/kubernetes/ingress.yaml

# Executar migrations
kubectl apply -f .dev/kubernetes/migration-job.yaml
```

## ⚠️ IMPORTANTE

**NUNCA** commite arquivos de `.dev/kubernetes/` para o Git!

- Estes arquivos usam imagens **locais** (sem `ghcr.io/`)
- Se você commitar, vai **quebrar o deploy de produção** (VPS)
- O `.gitignore` já está configurado para ignorar `.dev/`

## 🔄 Quando Recriar

Rode `./setup.sh` novamente sempre que:
- Mudar namespace, domínio, ou senhas
- Atualizar configurações (recursos, réplicas)
- Adicionar novos serviços

## 📖 Documentação

Veja [DEPLOY_PROJECT.md](../DEPLOY_PROJECT.md) seção **Minikube** para mais detalhes.
