# 🎯 Guia de Navegação - Kubernetes para Laravel

Bem-vindo ao setup completo de Kubernetes para projetos Laravel! 🚀

## 📚 Documentação Disponível

### 🌟 Para Iniciantes

1. **[⚡ QUICK_START.md](QUICK_START.md)** - **COMECE AQUI!**
   - Deploy em 30 minutos
   - Passo a passo simplificado
   - Comandos prontos para copiar/colar

2. **[📖 README.md](README.md)**
   - Visão geral do projeto
   - Como usar o configurador
   - Personalização de templates

3. **[📁 FILE_STRUCTURE.md](FILE_STRUCTURE.md)**
   - Estrutura de arquivos
   - O que cada arquivo faz
   - Exemplos de customização

4. **[🔄 MULTIPLE_APPS.md](MULTIPLE_APPS.md)** - **Múltiplos Apps na Mesma VPS**
   - Como rodar vários apps Laravel na mesma VPS
   - Cada app com domínio e SSL próprio
   - Exemplos práticos completos
   - Gerenciamento de recursos

### 📘 Documentação Completa

5. **[📚 DEPLOY_VPS.md](DEPLOY_VPS.md)** - **Guia Completo (Simplificado)**
   - **PARTE 1**: Configuração da VPS (faça uma vez)
   - **PARTE 2**: Deploy de projetos Laravel (para cada projeto)
   - Focado em comandos e uso do `setup.sh`
   - Conceitos-chave explicados

6. **[🔬 DEPLOY_VPS_ADVANCED.md](DEPLOY_VPS_ADVANCED.md)** - **Referência Técnica**
   - Todos os YAMLs completos com explicações
   - Detalhes técnicos de cada configuração
   - Para quem quer entender a fundo
   - Troubleshooting detalhado

7. **[� TROUBLESHOOTING.md](TROUBLESHOOTING.md)** - **Problemas Comuns**
   - Bugs conhecidos e soluções
   - Mixed Content, ImagePullBackOff, SSL, etc.
   - Comandos de debug e emergência
   - Checklist de validação

8. **[🔒 LARAVEL_HTTPS_SETUP.md](LARAVEL_HTTPS_SETUP.md)** - **Configurar HTTPS**
   - TrustProxies para Kubernetes
   - Forçar HTTPS em produção
   - Resolver Mixed Content
   - Configuração pós-deploy

9. **[�💼 EXAMPLES.md](EXAMPLES.md)** - **Exemplos de Casos de Uso**
   - Cenários reais de uso
   - Configurações específicas
   - Casos de uso avançados

## 🎯 Escolha seu Caminho

### 🆕 Primeira Vez com Kubernetes?

```
1. Leia: QUICK_START.md
2. Configure VPS: DEPLOY_VPS.md (Parte 1)
3. Execute: ./setup.sh
4. Siga: QUICK_START.md (passos 2-7)
```

### 🚀 Já tem VPS Configurada?

```
1. Execute: ./setup.sh
2. Siga: QUICK_START.md
```

### 🔧 Quer Entender os Detalhes?

```
1. Leia: DEPLOY_VPS.md (simplificado)
2. Aprofunde: DEPLOY_VPS_ADVANCED.md (YAMLs completos)
3. Explore: FILE_STRUCTURE.md
4. Customize: templates/*.stub
```

### 📊 Quer Customizar Templates?

```
1. Leia: README.md (seção Personalização)
2. Veja: FILE_STRUCTURE.md (exemplos)
3. Edite: templates/*.stub
4. Execute: ./setup.sh
```

### 🔄 Quer Rodar Múltiplos Apps?

```
1. Leia: MULTIPLE_APPS.md
2. Configure cada app com namespace único
3. Use o mesmo IP da VPS
4. Cada app terá seu domínio e SSL
```

## 🛠️ Arquivos Principais

| Arquivo | Propósito | Quando Usar |
|---------|-----------|-------------|
| `setup.sh` | 🚀 Configurador automático | Gerar arquivos para novo projeto |
| `QUICK_START.md` | ⚡ Guia rápido | Primeiro deploy (30 min) |
| `MULTIPLE_APPS.md` | 🔄 Múltiplos apps | Rodar vários apps na mesma VPS |
| `README.md` | 📖 Visão geral | Entender o projeto |
| `DEPLOY_VPS.md` | 📚 Guia simplificado | Comandos e fluxo principal |
| `DEPLOY_VPS_ADVANCED.md` | 🔬 Referência técnica | YAMLs completos e detalhes |
| `FILE_STRUCTURE.md` | 📁 Estrutura | Entender arquivos gerados |
| `EXAMPLES.md` | 💼 Casos de uso | Cenários reais e avançados |

## 📂 Estrutura de Pastas

```
kubernetes-vps-setup/
│
├── 📄 INDEX.md              # ← VOCÊ ESTÁ AQUI
├── ⚡ QUICK_START.md        # Início rápido (30 min)
├── 📖 README.md             # Visão geral e uso
├── 📚 DEPLOY_VPS.md         # Guia completo
├── 📁 FILE_STRUCTURE.md     # Estrutura de arquivos
│
├── 🚀 setup.sh              # Script principal
│
├── 📝 templates/            # Templates (*.stub)
│   ├── namespace.yaml.stub
│   ├── secrets.yaml.stub
│   ├── configmap.yaml.stub
│   ├── postgres.yaml.stub
│   ├── redis.yaml.stub
│   ├── deployment.yaml.stub
│   ├── service.yaml.stub
│   ├── ingress.yaml.stub
│   ├── cert-issuer.yaml.stub
│   └── migration-job.yaml.stub
│
├── 🐳 docker/
│   ├── nginx/
│   │   └── default.conf.stub
│   └── supervisor/
│       └── supervisord.conf.stub
│
├── 🤖 .github/
│   └── workflows/
│       └── deploy.yml.stub
│
├── 🐋 Dockerfile.stub
└── 📋 .dockerignore.stub
```

## 🎓 Fluxo Recomendado

### Para Deploy Rápido (Iniciante)

```mermaid
QUICK_START.md → setup.sh → Deploy! 🚀
```

**Tempo**: ~30 minutos

### Para Entendimento Completo

```mermaid
README.md → DEPLOY_VPS.md → FILE_STRUCTURE.md → setup.sh → Deploy! 🚀
```

**Tempo**: ~2 horas (inclui leitura e compreensão)

### Para Customização Avançada

```mermaid
FILE_STRUCTURE.md → Editar templates/ → setup.sh → Deploy! 🚀
```

**Tempo**: Variável

## 📖 Referência Rápida

### Comandos Essenciais

```bash
# Gerar arquivos de configuração
./setup.sh

# Ver pods
kubectl get pods -n seu-namespace

# Ver logs
kubectl logs -f deployment/app -n seu-namespace

# Aplicar configurações
kubectl apply -f kubernetes/

# Executar migrations
kubectl apply -f kubernetes/migration-job.yaml

# Reiniciar app
kubectl rollout restart deployment/app -n seu-namespace
```

### Links Úteis

- **Kubernetes Docs**: https://kubernetes.io/docs/
- **Laravel Docs**: https://laravel.com/docs/
- **GitHub Container Registry**: https://docs.github.com/packages/working-with-a-github-packages-registry/working-with-the-container-registry
- **GitHub Actions**: https://docs.github.com/actions

## 🆘 Problemas?

1. **Consulte**: [DEPLOY_VPS.md](DEPLOY_VPS.md) - Seção 11 (Troubleshooting)
2. **Verifique logs**: `kubectl logs POD_NAME -n NAMESPACE`
3. **Ver eventos**: `kubectl get events -n NAMESPACE --sort-by='.lastTimestamp'`

## 📊 Progresso Sugerido

### ✅ Checklist de Aprendizado

- [ ] Ler QUICK_START.md
- [ ] Entender estrutura (FILE_STRUCTURE.md)
- [ ] Executar setup.sh
- [ ] Fazer primeiro deploy
- [ ] Configurar DNS e SSL
- [ ] Testar aplicação
- [ ] Ler DEPLOY_VPS.md completo
- [ ] Entender troubleshooting
- [ ] Customizar templates
- [ ] Fazer deploy de segundo projeto

### 🎯 Níveis de Conhecimento

**Nível 1 - Iniciante** (QUICK_START.md)
- ✅ Consegue fazer deploy básico
- ✅ Sabe usar setup.sh
- ✅ Consegue ver logs e status

**Nível 2 - Intermediário** (README.md + DEPLOY_VPS.md)
- ✅ Entende arquitetura Kubernetes
- ✅ Consegue fazer troubleshooting
- ✅ Sabe configurar recursos (CPU/RAM)

**Nível 3 - Avançado** (FILE_STRUCTURE.md + customização)
- ✅ Customiza templates
- ✅ Cria novos recursos K8s
- ✅ Otimiza configurações
- ✅ Implementa monitoramento

## 🌟 Próximos Passos

Após dominar o básico:

1. **Backup Automático** - Ver DEPLOY_VPS.md
2. **Monitoramento** - Prometheus + Grafana
3. **Staging Environment** - Namespace separado
4. **Blue/Green Deploy** - Zero-downtime
5. **CDN** - CloudFlare ou similar
6. **Logs Centralizados** - ELK Stack
7. **Autoscaling** - HPA (Horizontal Pod Autoscaler)

## 💡 Dicas

- 📌 **Marque esta página** para referência rápida
- 📖 **Leia os comentários** nos arquivos gerados
- 🧪 **Teste primeiro** em ambiente de staging
- 💾 **Faça backup** antes de mudanças grandes
- 📝 **Documente** suas customizações
- 🤝 **Compartilhe** melhorias com a equipe

## 🎉 Recursos Incluídos

✅ Setup automatizado  
✅ Templates prontos  
✅ CI/CD configurado  
✅ SSL automático  
✅ Banco de dados persistente  
✅ Cache e filas  
✅ Queue workers  
✅ Migrations automáticas  
✅ Zero-downtime deploys  
✅ Documentação completa  

---

## 🚀 Comece Agora!

**Primeira vez?** → [⚡ QUICK_START.md](QUICK_START.md)

**Quer entender tudo?** → [📚 DEPLOY_VPS.md](DEPLOY_VPS.md)

**Já sabe o que fazer?** → `./setup.sh`

---

**Feito com ❤️ para a comunidade Laravel**

Bons deploys! 🎊
