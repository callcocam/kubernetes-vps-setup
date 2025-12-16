# 📁 Estrutura de Arquivos

Este documento mostra a estrutura completa de arquivos após executar o `setup.sh`.

## 🗂️ Estrutura Gerada

```
seu-projeto-laravel/
│
├── kubernetes-vps-setup/           # 📦 Templates e configurador
│   ├── setup.sh                    # 🚀 Script principal
│   ├── README.md                   # 📖 Documentação
│   ├── DEPLOY_VPS.md               # 📚 Guia completo
│   ├── QUICK_START.md              # ⚡ Início rápido
│   │
│   ├── templates/                  # 📝 Templates (stubs)
│   │   ├── namespace.yaml.stub
│   │   ├── secrets.yaml.stub
│   │   ├── configmap.yaml.stub
│   │   ├── postgres.yaml.stub
│   │   ├── redis.yaml.stub
│   │   ├── deployment.yaml.stub
│   │   ├── service.yaml.stub
│   │   ├── ingress.yaml.stub
│   │   ├── cert-issuer.yaml.stub
│   │   └── migration-job.yaml.stub
│   │
│   ├── docker/
│   │   ├── nginx/
│   │   │   └── default.conf.stub
│   │   └── supervisor/
│   │       └── supervisord.conf.stub
│   │
│   ├── .github/
│   │   └── workflows/
│   │       └── deploy.yml.stub
│   │
│   ├── Dockerfile.stub
│   └── .dockerignore.stub
│
├── kubernetes/                     # ✅ GERADO pelo setup.sh
│   ├── namespace.yaml              # 🏢 Namespace do projeto
│   ├── secrets.yaml                # 🔐 Senhas e chaves
│   ├── configmap.yaml              # ⚙️  Configurações
│   ├── postgres.yaml               # 🐘 PostgreSQL
│   ├── redis.yaml                  # 🔴 Redis
│   ├── deployment.yaml             # 🚀 Deployment da app
│   ├── service.yaml                # 🔌 Service interno
│   ├── ingress.yaml                # 🌐 Roteamento HTTP/HTTPS
│   ├── cert-issuer.yaml            # 🔒 Emissor SSL
│   ├── migration-job.yaml          # 🔄 Job de migrations
│   └── .config                     # 📋 Configuração salva
│
├── docker/                         # ✅ GERADO pelo setup.sh
│   ├── nginx/
│   │   └── default.conf            # 🌐 Config Nginx
│   └── supervisor/
│       └── supervisord.conf        # 👷 Config Supervisor
│
├── .github/                        # ✅ GERADO pelo setup.sh
│   └── workflows/
│       └── deploy.yml              # 🤖 CI/CD GitHub Actions
│
├── Dockerfile                      # ✅ GERADO pelo setup.sh
├── .dockerignore                   # ✅ GERADO pelo setup.sh
│
├── app/                            # 📂 Código Laravel
├── config/
├── database/
├── public/
├── resources/
├── routes/
├── storage/
├── tests/
├── vendor/
│
├── .env                            # ⚙️  Ambiente local
├── .env.example
├── artisan
├── composer.json
├── package.json
├── vite.config.js
└── README.md
```

## 📊 Tipos de Arquivos

### 🔵 Templates (`.stub`)

Arquivos template com placeholders `{{VARIAVEL}}`:
- Nunca são modificados
- Usados como base pelo `setup.sh`
- Podem ser customizados conforme necessidade

### 🟢 Arquivos Gerados

Arquivos criados pelo `setup.sh`:
- Substituem `{{VARIAVEL}}` por valores reais
- Prontos para uso
- Podem ser commitados no Git

### 🟡 Arquivos Laravel

Estrutura padrão do Laravel:
- Não são modificados pelo `setup.sh`
- Seu código da aplicação

## 🎯 Pastas Importantes

### `kubernetes/`

Contém **todos** os arquivos de configuração do Kubernetes:

```yaml
kubernetes/
├── namespace.yaml      # Define namespace isolado
├── secrets.yaml        # ⚠️  NÃO commitar se tiver senhas reais!
├── configmap.yaml      # Variáveis de ambiente
├── postgres.yaml       # Banco de dados + volume
├── redis.yaml          # Cache + volume
├── deployment.yaml     # Como rodar a aplicação
├── service.yaml        # Exposição interna
├── ingress.yaml        # Exposição externa (HTTP/HTTPS)
├── cert-issuer.yaml    # SSL automático
└── migration-job.yaml  # Executar migrations
```

### `docker/`

Configurações específicas do container:

```
docker/
├── nginx/
│   └── default.conf       # Web server
└── supervisor/
    └── supervisord.conf   # Gerenciador de processos
```

### `.github/workflows/`

Pipeline de CI/CD:

```
.github/workflows/
└── deploy.yml    # Build automático + Deploy
```

## 🔒 Segurança: O que NÃO commitar

Adicione ao `.gitignore`:

```gitignore
# Kubernetes secrets (se contiver senhas reais)
kubernetes/secrets.yaml
kubernetes/.config

# Ambiente local
.env
.env.*

# Dependências
node_modules/
vendor/
```

## ✅ Checklist: Arquivos Necessários

Antes de fazer deploy, verifique se tem:

**Kubernetes:**
- [ ] `kubernetes/namespace.yaml`
- [ ] `kubernetes/secrets.yaml`
- [ ] `kubernetes/configmap.yaml`
- [ ] `kubernetes/postgres.yaml`
- [ ] `kubernetes/redis.yaml`
- [ ] `kubernetes/deployment.yaml`
- [ ] `kubernetes/service.yaml`
- [ ] `kubernetes/ingress.yaml`
- [ ] `kubernetes/cert-issuer.yaml`
- [ ] `kubernetes/migration-job.yaml`

**Docker:**
- [ ] `Dockerfile`
- [ ] `.dockerignore`
- [ ] `docker/nginx/default.conf`
- [ ] `docker/supervisor/supervisord.conf`

**CI/CD:**
- [ ] `.github/workflows/deploy.yml`

## 🔄 Atualizando Configurações

Se precisar alterar configurações:

### Opção 1: Re-executar setup.sh

```bash
cd kubernetes-vps-setup
./setup.sh
```

> ⚠️ **Cuidado**: Sobrescreve arquivos existentes!

### Opção 2: Editar manualmente

```bash
# Editar arquivo específico
nano kubernetes/deployment.yaml

# Aplicar mudança
kubectl apply -f kubernetes/deployment.yaml
```

### Opção 3: Editar template e re-gerar

```bash
# 1. Editar template
nano kubernetes-vps-setup/templates/deployment.yaml.stub

# 2. Re-executar setup.sh
cd kubernetes-vps-setup
./setup.sh
```

## 📝 Customização de Templates

Variáveis disponíveis nos templates:

| Variável | Exemplo | Onde usar |
|----------|---------|-----------|
| `{{PROJECT_NAME}}` | meu-app | Nomes, labels |
| `{{NAMESPACE}}` | meu-app | Namespace K8s |
| `{{DOMAIN}}` | app.exemplo.com | Ingress, URLs |
| `{{VPS_IP}}` | 203.0.113.10 | Documentação |
| `{{DOCKER_USERNAME}}` | usuario | Imagens Docker |
| `{{DOCKER_IMAGE}}` | usuario/meu-app | Deployment |
| `{{APP_KEY}}` | base64:... | Laravel |
| `{{APP_EMAIL}}` | admin@exemplo.com | Cert-manager |
| `{{DB_NAME}}` | laravel | PostgreSQL |
| `{{DB_USER}}` | laravel | PostgreSQL |
| `{{DB_PASSWORD}}` | senha123 | Secrets |
| `{{REDIS_PASSWORD}}` | senha456 | Secrets |
| `{{MEM_REQUEST}}` | 256Mi | Resources |
| `{{MEM_LIMIT}}` | 512Mi | Resources |
| `{{CPU_REQUEST}}` | 250m | Resources |
| `{{CPU_LIMIT}}` | 500m | Resources |
| `{{REPLICAS}}` | 2 | Deployment |

## 🎨 Exemplo de Customização

### Adicionar novo template

1. **Criar template:**

```bash
nano kubernetes-vps-setup/templates/cronjob.yaml.stub
```

```yaml
apiVersion: batch/v1
kind: CronJob
metadata:
  name: backup
  namespace: {{NAMESPACE}}
spec:
  schedule: "0 2 * * *"
  jobTemplate:
    spec:
      template:
        spec:
          containers:
          - name: backup
            image: {{DOCKER_IMAGE}}:latest
            command: ["php", "artisan", "backup:run"]
          restartPolicy: OnFailure
```

2. **Modificar setup.sh:**

Adicionar após linha de `migration-job.yaml`:

```bash
process_template "$SCRIPT_DIR/templates/cronjob.yaml.stub" "$OUTPUT_DIR/cronjob.yaml"
```

3. **Re-executar:**

```bash
./setup.sh
```

## 🗺️ Fluxo de Arquivos

```
┌─────────────────┐
│   setup.sh      │ ← Você executa
└────────┬────────┘
         │
         ↓
┌─────────────────┐
│   templates/    │ ← Lê templates
│   *.stub        │
└────────┬────────┘
         │
         ↓ (substitui variáveis)
         │
┌─────────────────┐
│   kubernetes/   │ ← Gera arquivos
│   docker/       │   prontos
│   .github/      │
└─────────────────┘
         │
         ↓ (você commita)
         │
┌─────────────────┐
│   GitHub        │ ← Push
└────────┬────────┘
         │
         ↓ (GitHub Actions)
         │
┌─────────────────┐
│   Docker Hub    │ ← Build & Push
└────────┬────────┘
         │
         ↓ (kubectl apply)
         │
┌─────────────────┐
│   Kubernetes    │ ← Deploy
│   VPS           │
└─────────────────┘
```

---

**💡 Dica**: Mantenha os templates (`kubernetes-vps-setup/`) sempre no seu repositório para facilitar novos projetos!
