# ⚡ Início Rápido - Deploy Laravel com Kubernetes

Este guia te leva do zero ao deploy em **menos de 30 minutos**!

## 🎯 Pré-requisitos Checklist

Antes de começar, certifique-se de ter:

- [ ] VPS Ubuntu 22.04 com Kubernetes configurado ([PARTE 1 do DEPLOY_VPS.md](DEPLOY_VPS.md))
- [ ] Domínio próprio (ex: exemplo.com)
- [ ] Conta no GitHub (usaremos GitHub Container Registry)
- [ ] kubectl configurado localmente

> 💡 **Primeira vez?** Configure a VPS primeiro seguindo a **PARTE 1** do [DEPLOY_VPS.md](DEPLOY_VPS.md)  
> 📖 **Quer detalhes?** Veja [DEPLOY_VPS_ADVANCED.md](DEPLOY_VPS_ADVANCED.md) para entender cada configuração

---

## 🚀 Passos Rápidos

### 1️⃣ Execute o Configurador (2 minutos)

```bash
cd kubernetes-vps-setup
./setup.sh
```

**Responda as perguntas:**

```
📦 Nome do projeto: {{PROJECT_NAME}}
🏢 Namespace: {{NAMESPACE}}
🌐 Domínio: {{DOMAIN}}
🖥️  IP da VPS: {{VPS_IP}}
🔑 APP_KEY: [ENTER para gerar]
📧 Email: {{APP_EMAIL}}
🗄️  Banco: {{DB_NAME}}
👤 Usuário DB: {{DB_USER}}
🔐 Senha PostgreSQL: [ENTER para gerar]
🔐 Senha Redis: [ENTER para gerar]
☁️  DigitalOcean Spaces: n

🔴 Reverb WebSocket:
  APP_ID: [ENTER para gerar]
  APP_KEY: [ENTER para gerar]
  APP_SECRET: [ENTER para gerar]

⭐ NOVO! Perfil de Recursos:
  1) 🚀 Produção (2 réplicas, alta disponibilidade)
  2) 🛠️  Dev (1 réplica, recursos moderados)
  3) 🧪 Test (1 réplica, testes)
  4) ⚙️  Manual (customizado)
  
Escolha [1-4]: 1    ← Escolha o perfil adequado!
```

💡 **Dica:** Pressione ENTER em todas as senhas/credenciais para gerar automaticamente

✅ **Arquivos criados em**: `kubernetes/`, `docker/`, `.github/workflows/`

---

### 2️⃣ Preparar VPS (3 minutos)

```bash
# Conectar na VPS
ssh root@{{VPS_IP}}

# Criar diretórios para dados (isolados por namespace)
mkdir -p /data/postgresql/{{NAMESPACE}} /data/redis/{{NAMESPACE}}
chmod 700 /data/postgresql/{{NAMESPACE}}
chmod 755 /data/redis/{{NAMESPACE}}

# Verificar se tudo está OK
kubectl get nodes
# Deve mostrar: Ready

exit
```

---

### 3️⃣ Configurar GitHub Secrets (5 minutos)

```bash
# No diretório do projeto
cd ~/{{PROJECT_NAME}}

# Instalar GitHub CLI (se necessário)
# Ubuntu/Debian:
# sudo apt install gh

# Autenticar
gh auth login

# APP_KEY (copie do output do script setup.sh)
gh secret set APP_KEY --body "{{APP_KEY}}"

# KUBE_CONFIG (em base64)
# Pegar o kubeconfig da VPS e converter para base64:
ssh root@{{VPS_IP}} 'cat /etc/kubernetes/admin.conf' | base64 -w 0 | gh secret set KUBE_CONFIG --body-file -

# Verificar
gh secret list

# Deve mostrar:
# APP_KEY
# KUBE_CONFIG
```

---

### 4️⃣ Configurar DNS (5 minutos)

No seu provedor de DNS (Cloudflare, etc):

| Tipo | Nome | Valor | Proxy |
|------|------|-------|-------|
| A | @ | {{VPS_IP}} | DNS only |
| A | * | {{VPS_IP}} | DNS only |

**Testar propagação:**

```bash
dig {{DOMAIN}}
# Deve retornar: {{VPS_IP}}
```

---

### 5️⃣ Deploy! (10 minutos)

```bash
# Commit e push
git add .
git commit -m "feat: Add Kubernetes configuration"
git push origin main

# Acompanhar build
gh run watch

# Ou ver no browser:
# https://github.com/seu-usuario/seu-repo/actions
```

**Enquanto aguarda, aplicar configurações Kubernetes:**

```bash
# Aplicar na ordem:
kubectl apply -f kubernetes/namespace.yaml
kubectl apply -f kubernetes/secrets.yaml
kubectl apply -f kubernetes/configmap.yaml
kubectl apply -f kubernetes/cert-issuer.yaml
kubectl apply -f kubernetes/postgres.yaml
kubectl apply -f kubernetes/redis.yaml

# Aguardar bancos de dados ficarem prontos
kubectl wait --for=condition=ready pod -l app=postgres -n {{NAMESPACE}} --timeout=120s
kubectl wait --for=condition=ready pod -l app=redis -n {{NAMESPACE}} --timeout=120s

# Aplicar aplicação
kubectl apply -f kubernetes/deployment.yaml
kubectl apply -f kubernetes/service.yaml
kubectl apply -f kubernetes/ingress.yaml

# Executar migrations
kubectl apply -f kubernetes/migration-job.yaml
```

---

### 6️⃣ Verificar Deploy (2 minutos)

```bash
# Ver pods
kubectl get pods -n {{NAMESPACE}}

# Ver certificado SSL (pode levar 2-5 minutos)
kubectl get certificate -n {{NAMESPACE}}

# Ver ingress
kubectl get ingress -n {{NAMESPACE}}

# Ver logs
kubectl logs -f deployment/app -n {{NAMESPACE}}
```

**Saída esperada:**

```
NAME                   READY   STATUS    RESTARTS   AGE
app-xxx                2/2     Running   0          2m
postgres-0             1/1     Running   0          3m
redis-0                1/1     Running   0          3m

NAME      READY   SECRET    AGE
app-tls   True    app-tls   3m
```

---

### 7️⃣ Acessar Aplicação (1 minuto)

```bash
# Testar
curl -I https://{{DOMAIN}}

# Ou abrir no navegador
open https://{{DOMAIN}}
```

**✅ Se aparecer com cadeado verde, SUCESSO! 🎉**

---

## 🔄 Próximos Deploys

Muito mais simples:

```bash
# Fazer alterações no código
git add .
git commit -m "feat: Nova funcionalidade"
git push origin main

# Deploy automático via GitHub Actions!
# Acompanhar: gh run watch
```

> 💡 **Importante**: O GitHub Actions possui 2 workflows:
> 1. **Build and Push Docker Image** - Cria a imagem e envia para ghcr.io
> 2. **Deploy to Kubernetes** - Atualiza os pods com a nova imagem
> 
> Ambos devem completar com sucesso (✓) para o deploy funcionar.

---

## 💻 Desenvolvimento Local (Minikube)

### Após Reiniciar a Máquina

Quando você reinicia seu computador, o minikube não inicia automaticamente. Siga estes passos:

```bash
# 1. Iniciar o minikube
minikube start

# 2. Verificar se está rodando
kubectl get nodes
# Deve mostrar: Ready

# 3. Verificar os pods do seu projeto
kubectl get pods -n {{NAMESPACE}}

# 4. Se os pods não estiverem rodando, reaplicar as configurações
kubectl apply -f .dev/kubernetes/

# 5. Aguardar pods ficarem prontos
kubectl wait --for=condition=ready pod -l app=postgres -n {{NAMESPACE}} --timeout=120s
kubectl wait --for=condition=ready pod -l app=redis -n {{NAMESPACE}} --timeout=120s
kubectl wait --for=condition=ready pod -l app={{PROJECT_NAME}} -n {{NAMESPACE}} --timeout=120s
```

### Acessar a Aplicação Local

```bash
# Obter a URL do serviço
minikube service app -n {{NAMESPACE}} --url

# Ou usar port-forward
kubectl port-forward -n {{NAMESPACE}} svc/app 8080:80

# Acessar no navegador
# http://localhost:8080
```

### Verificações Importantes

#### Volumes Compartilhados (Docker Compose + Minikube)

Certifique-se de que os volumes estão configurados corretamente:

```bash
# 1. Verificar volumes do Docker Compose (.dev/)
docker compose -f .dev/docker-compose.yml config | grep -A 5 volumes

# 2. Verificar volumes do Minikube
kubectl get pv  # Persistent Volumes
kubectl get pvc -n {{NAMESPACE}}  # Persistent Volume Claims

# 3. Verificar se os dados estão persistindo
# PostgreSQL:
kubectl exec -it postgres-0 -n {{NAMESPACE}} -- psql -U {{DB_USER}} -d {{DB_NAME}} -c '\dt'

# Redis:
kubectl exec -it redis-0 -n {{NAMESPACE}} -- redis-cli ping

# 4. Verificar montagem dos volumes nos pods
kubectl describe pod postgres-0 -n {{NAMESPACE}} | grep -A 10 Volumes
kubectl describe pod redis-0 -n {{NAMESPACE}} | grep -A 10 Volumes

# 5. Caminho dos volumes no Minikube
minikube ssh
ls -la /data/postgresql/{{NAMESPACE}}
ls -la /data/redis/{{NAMESPACE}}
exit
```

**Problemas comuns com volumes:**

```bash
# Se volumes não existem no Minikube, criar:
minikube ssh
sudo mkdir -p /data/postgresql/{{NAMESPACE}} /data/redis/{{NAMESPACE}}
sudo chmod 700 /data/postgresql/{{NAMESPACE}}
sudo chmod 755 /data/redis/{{NAMESPACE}}
exit

# Reiniciar pods para remontar volumes
kubectl rollout restart statefulset/postgres -n {{NAMESPACE}}
kubectl rollout restart statefulset/redis -n {{NAMESPACE}}

# Verificar se volumes foram montados
kubectl get pods -n {{NAMESPACE}} -w  # Aguardar ficar Running
```

### Comandos Úteis para Desenvolvimento

```bash
# Parar o minikube (liberar recursos)
minikube stop

# Ver status
minikube status

# Acessar dashboard do Kubernetes
minikube dashboard

# Ou rodar dashboard em background (não trava o terminal)
minikube dashboard &

# Ou apenas obter a URL (sem abrir browser)
minikube dashboard --url

# Ver logs em tempo real
kubectl logs -f deployment/app -n {{NAMESPACE}}

# Executar migrations
kubectl exec -it deployment/app -n {{NAMESPACE}} -- php artisan migrate

# Executar comandos no container
kubectl exec -it deployment/app -n {{NAMESPACE}} -- bash

# Rebuild e redeploy (após mudanças no código)
eval $(minikube docker-env)  # Usar Docker do minikube
docker build -t {{PROJECT_NAME}}:dev .
kubectl rollout restart deployment/app -n {{NAMESPACE}}
```

### Limpar Tudo e Recomeçar

```bash
# Deletar todos os recursos do namespace
kubectl delete namespace {{NAMESPACE}}

# Recriar do zero
kubectl apply -f .dev/kubernetes/

# Ou deletar o minikube inteiro
minikube delete
minikube start
```

---

## 🐛 Problemas Comuns

### Pods não iniciam

```bash
# Ver erro
kubectl describe pod POD_NAME -n {{NAMESPACE}}

# Ver logs
kubectl logs POD_NAME -n {{NAMESPACE}}
```

### Certificado SSL não criado

```bash
# Ver status
kubectl describe certificate app-tls -n {{NAMESPACE}}

# Ver challenges
kubectl get challenges -n {{NAMESPACE}}

# Causas comuns:
# - DNS não propagou (aguarde 10-30 min)
# - Porta 80 bloqueada no firewall
# - Email inválido no cert-issuer.yaml
```

### Site não abre (502/504)

```bash
# Ver pods
kubectl get pods -n {{NAMESPACE}}

# Se não estão Running, ver logs:
kubectl logs deployment/app -n {{NAMESPACE}}

# Verificar ingress
kubectl get ingress -n {{NAMESPACE}}
kubectl logs -n ingress-nginx -l app.kubernetes.io/component=controller
```

### GitHub Actions falha

```bash
# Ver erro no GitHub
gh run view --log-failed

# Erros comuns:

# 1. "error loading config file" ou "couldn't get version/kind"
# Causa: KUBE_CONFIG não está em base64 ou está corrompido
# Solução:
ssh root@SEU_IP_VPS 'cat /etc/kubernetes/admin.conf' | base64 -w 0 | gh secret set KUBE_CONFIG --body-file -

# 2. "connection refused" para o cluster
# Causa: IP interno no kubeconfig em vez do público
# Solução: O comando acima já pega o correto

# 3. "ImagePullBackOff"
# Causa: Imagem não foi publicada no GitHub Container Registry
# Solução: Verificar se o workflow "Build and Push Docker Image" rodou com sucesso
gh run list --workflow="Build and Push Docker Image"
```

---

## 📊 Comandos Úteis

```bash
# Ver tudo do namespace
kubectl get all -n {{NAMESPACE}}

# Ver logs em tempo real
kubectl logs -f deployment/app -n {{NAMESPACE}}

# Executar comando no pod
kubectl exec -it deployment/app -n {{NAMESPACE}} -- bash

# Executar migrations
kubectl exec -it deployment/app -n {{NAMESPACE}} -- php artisan migrate

# Reiniciar deployment
kubectl rollout restart deployment/app -n {{NAMESPACE}}

# Ver eventos
kubectl get events -n {{NAMESPACE}} --sort-by='.lastTimestamp'
```

---

## 🎓 Próximos Passos

1. **Configurar Backup Automático** - Ver [DEPLOY_VPS.md](DEPLOY_VPS.md#próximos-passos)
2. **Adicionar Monitoramento** - Prometheus + Grafana
3. **Configurar Staging Environment** - Criar namespace separado
4. **Implementar Blue/Green Deploy** - Zero-downtime garantido
5. **Adicionar CDN** - CloudFlare para assets

---

## 🆘 Precisa de Ajuda?

1. **🐛 Problemas Comuns**: [TROUBLESHOOTING.md](TROUBLESHOOTING.md) - **COMECE AQUI!**
2. **Documentação Completa**: [DEPLOY_VPS.md](DEPLOY_VPS.md)
3. **Troubleshooting Detalhado**: Seção 11 do DEPLOY_VPS.md
4. **Templates e Customização**: [README.md](README.md)

---

## 📝 Resumo dos Tempos

| Etapa | Tempo Estimado |
|-------|----------------|
| 1. Executar configurador | 2 minutos |
| 2. Preparar VPS | 3 minutos |
| 3. GitHub Secrets | 5 minutos |
| 4. Configurar DNS | 5 minutos |
| 5. Deploy | 10 minutos |
| 6. Verificar | 2 minutos |
| 7. Acessar | 1 minuto |
| **TOTAL** | **~28 minutos** |

> 💡 Após primeira vez, próximos deploys levam **menos de 1 minuto** (apenas `git push`)!

---

**🎉 Parabéns! Você tem um setup profissional de Kubernetes para Laravel!**

Deploy automático ✅ | SSL grátis ✅ | Escalável ✅ | Profissional ✅
