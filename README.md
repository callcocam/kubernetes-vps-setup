# 🚀 Kubernetes VPS Setup - Deploy Laravel Automatizado

**Um comando para gerar tudo. Outro para rodar. Simples assim.**

---

## ⚡ Como Usar

### Desenvolvimento Local

```bash
# 1. Gerar configurações
./setup.sh

# 2. Inicializar
cd seu-projeto/.dev
./init.sh

# Pronto! → http://localhost:8000
```

### Produção (VPS)

```bash
# 1. Preparar VPS uma vez (ver docs/DEPLOY_VPS.md)

# 2. Configurar GitHub Secrets
cd seu-projeto
../kubernetes-vps-setup/setup-github-secrets.sh

# 3. Push para deploy automático
git push origin main
```

---

## 📚 Documentação

| Documento | Quando usar |
|-----------|-------------|
| [QUICK_START.md](docs/QUICK_START.md) | Deploy em 30 minutos |
| [DEPLOY_VPS.md](docs/DEPLOY_VPS.md) | Guia completo passo a passo |
| [DEPLOY_LOCAL_K8S.md](docs/DEPLOY_LOCAL_K8S.md) | Desenvolvimento com Minikube |
| [MULTIPLE_APPS.md](docs/MULTIPLE_APPS.md) | Várias apps na mesma VPS |
| [TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md) | Resolver problemas |
| [GITHUB_REGISTRY_SECRETS.md](docs/GITHUB_REGISTRY_SECRETS.md) | GitHub Container Registry |

**Ver tudo:** [docs/INDEX.md](docs/INDEX.md)

---

## 🎯 O que faz?

**`setup.sh`** gera automaticamente:
- ✅ Ambiente dev local (Docker Compose + init.sh)
- ✅ Configurações Kubernetes (10 arquivos YAML)
- ✅ CI/CD (GitHub Actions)
- ✅ SSL automático (Let's Encrypt)
- ✅ PostgreSQL + Redis
- ✅ Documentação personalizada

**`setup-github-secrets.sh`** configura:
- ✅ APP_KEY (Laravel)
- ✅ KUBE_CONFIG (acesso ao cluster)
- ✅ GHCR_TOKEN (opcional, geralmente automático)

---

## 📦 Requisitos

**Local:** Docker + Docker Compose  
**Produção:** VPS com Kubernetes (ver [DEPLOY_VPS.md](docs/DEPLOY_VPS.md))  
**GitHub Secrets:** GitHub CLI (`gh`)

---

## 🗂️ Estrutura

```
kubernetes-vps-setup/
├── setup.sh                    ← Gerador principal
├── setup-github-secrets.sh     ← Configurar GitHub Secrets
├── templates/                  ← 15 templates
└── docs/                       ← 9 documentos
```

---

## 🆘 Problemas?

1. [docs/TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md)
2. `docker compose logs` (local) ou `kubectl logs` (produção)
3. Revise a documentação

---

**MIT License** · Deploy Laravel em Kubernetes de forma simples
