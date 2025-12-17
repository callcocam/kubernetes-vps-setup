# 🐛 Troubleshooting - Problemas Comuns

Este documento lista problemas comuns encontrados durante o deploy e suas soluções.

---

## 🔴 Bug #1: KUBE_CONFIG Inválido - Connection Refused

### Sintomas
```bash
# GitHub Actions falha com:
couldn't get current server API group list: connection refused
dial tcp [::1]:8080: connect: connection refused
```

### Causa
O `KUBE_CONFIG` no GitHub Secrets aponta para `localhost:8080` ao invés do IP público do cluster.

### Solução
```bash
# ❌ ERRADO (aponta para localhost)
cat ~/.kube/config | base64 | gh secret set KUBE_CONFIG --body-file -

# ✅ CORRETO (usa IP público)
kubectl config view --flatten --minify | base64 -w 0 | gh secret set KUBE_CONFIG --body-file -
```

### Prevenção
Sempre use `kubectl config view --flatten --minify` para garantir que o kubeconfig tenha o IP público do servidor.

---

## 🔴 Bug #2: Supervisor Log Directory Missing

### Sintomas
```bash
# Pod em CrashLoopBackOff
# Log do erro:
Error: The directory named as part of the path /var/log/supervisor/supervisord.log does not exist
```

### Causa
O `Dockerfile` não criou o diretório `/var/log/supervisor/` necessário.

### Solução
**Já corrigido no template atual!** Se você tem um Dockerfile antigo, adicione:

```dockerfile
# Configurar Supervisor
COPY docker/supervisor/supervisord.conf /etc/supervisor/conf.d/supervisord.conf

# Criar diretórios necessários
RUN mkdir -p /var/log/supervisor /run/nginx

# Configurar permissões
RUN chown -R www-data:www-data /var/www/html/storage
```

### Prevenção
Use sempre a versão mais recente do template `Dockerfile.stub`.

---

## 🔴 Bug #3: PostgreSQL com Dados Antigos - Authentication Failed

### Sintomas
```bash
# Migration job falha com:
FATAL: password authentication failed for user "meu_usuario"
Role "meu_usuario" does not exist

# PostgreSQL mostra:
PostgreSQL Database directory appears to contain a database; Skipping initialization
```

### Causa
O PostgreSQL foi recriado mas manteve dados antigos no PersistentVolume. Quando o PostgreSQL detecta dados existentes, ele pula a inicialização e não cria o novo usuário/banco.

### Solução Completa
Use o script automatizado:

```bash
# No diretório do projeto
./scripts/reset-postgres.sh meu-namespace
```

Ou manualmente:

```bash
# 1. Deletar tudo do PostgreSQL
kubectl delete statefulset postgres -n meu-app
kubectl delete pvc postgres-pvc -n meu-app
kubectl delete service postgres-service -n meu-app

# 2. Limpar dados na VPS
ssh root@SEU_IP_VPS
sudo rm -rf /data/postgresql
sudo mkdir -p /data/postgresql
sudo chmod 700 /data/postgresql
exit

# 3. Recriar
kubectl apply -f kubernetes/postgres.yaml

# 4. Aguardar ficar pronto
kubectl wait --for=condition=ready pod -l app=postgres -n meu-app --timeout=120s

# 5. Verificar usuário foi criado
kubectl exec postgres-0 -n meu-app -- psql -U seu_usuario -d seu_banco -c "SELECT current_user;"

# 6. Executar migrations
kubectl delete job migration -n meu-app --ignore-not-found=true
kubectl apply -f kubernetes/migration-job.yaml
```

### Prevenção
- Sempre delete o PVC ao recriar o PostgreSQL
- Limpe os dados em `/data/postgresql/` na VPS
- Considere usar scripts de reset automatizados

---

## ⚠️ Pods em ImagePullBackOff

### Sintomas
```bash
kubectl get pods -n meu-app
# NAME                   READY   STATUS             RESTARTS   AGE
# app-xxx                0/1     ImagePullBackOff   0          5m
```

### Causas Comuns

#### 1. Imagem não foi publicada no ghcr.io
```bash
# Verificar workflow GitHub Actions
gh run list --workflow="Build and Push Docker Image"

# Se falhou, verificar logs
gh run view --log-failed
```

#### 2. Permissões incorretas no GitHub
```bash
# Verificar se o pacote é público
# GitHub → Packages → Seu pacote → Package settings → Change visibility → Public

# Ou configurar imagePullSecrets no deployment (para pacotes privados)
```

#### 3. Nome da imagem incorreto
```bash
# Verificar deployment
kubectl describe deployment app -n meu-app | grep Image:

# Deve mostrar: ghcr.io/usuario/projeto:latest
# Se mostrar dockerhub ou outro, corrigir o deployment.yaml
```

### Solução
```bash
# Forçar novo deploy
git commit --allow-empty -m "chore: trigger rebuild"
git push origin main

# Acompanhar
gh run watch
```

---

## ⚠️ Certificado SSL Não Criado

### Sintomas
```bash
kubectl get certificate -n meu-app
# NAME      READY   SECRET    AGE
# app-tls   False   app-tls   10m
```

### Verificar Detalhes
```bash
# Ver status detalhado
kubectl describe certificate app-tls -n meu-app

# Ver challenges
kubectl get challenges -n meu-app
```

### Causas Comuns

#### 1. DNS não propagou
```bash
# Testar resolução DNS
dig seu-dominio.com

# Deve retornar o IP da sua VPS
# Se não retornar, aguarde propagação (10-30min)
```

#### 2. Porta 80 bloqueada
```bash
# Na VPS, verificar firewall
sudo ufw status

# Deve mostrar:
# 80/tcp    ALLOW       Anywhere
# 443/tcp   ALLOW       Anywhere

# Se não tiver, adicionar:
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
```

#### 3. Email inválido no cert-issuer
```bash
# Verificar cert-issuer
kubectl get clusterissuer letsencrypt-prod -o yaml

# Corrigir email se necessário
kubectl edit clusterissuer letsencrypt-prod
```

### Solução
```bash
# Deletar certificado e recriar
kubectl delete certificate app-tls -n meu-app
kubectl apply -f kubernetes/cert-issuer.yaml
kubectl apply -f kubernetes/ingress.yaml

# Aguardar (pode levar 2-5 minutos)
watch kubectl get certificate -n meu-app
```

---

## ⚠️ Site Retorna 502/504

### Sintomas
```bash
curl -I https://seu-dominio.com
# HTTP/2 502
```

### Verificar

```bash
# 1. Pods estão rodando?
kubectl get pods -n meu-app

# 2. Ver logs da aplicação
kubectl logs deployment/app -n meu-app

# 3. Ver logs do ingress
kubectl logs -n ingress-nginx -l app.kubernetes.io/component=controller

# 4. Testar service interno
kubectl run -it --rm debug --image=alpine --restart=Never -n meu-app -- sh
# Dentro do pod:
apk add curl
curl http://app-service
```

### Causas Comuns

#### 1. Aplicação não está rodando
```bash
# Verificar health checks
kubectl describe pod POD_NAME -n meu-app

# Ajustar probes se necessário
```

#### 2. Service apontando para porta errada
```bash
# Verificar service
kubectl get svc app-service -n meu-app -o yaml

# Deve ter:
# ports:
# - port: 80
#   targetPort: 80
```

---

## 📝 Checklist de Debug Geral

Quando algo não funciona, siga esta ordem:

```bash
# 1. Ver status geral
kubectl get all -n meu-app

# 2. Ver eventos recentes
kubectl get events -n meu-app --sort-by='.lastTimestamp' | tail -20

# 3. Logs dos pods
kubectl logs deployment/app -n meu-app --tail=50

# 4. Descrever pod problemático
kubectl describe pod POD_NAME -n meu-app

# 5. Executar shell no pod
kubectl exec -it POD_NAME -n meu-app -- sh

# 6. Ver recursos consumidos
kubectl top pods -n meu-app
kubectl top nodes
```

---

## 🆘 Comandos de Emergência

### Reset Completo da Aplicação
```bash
# Deletar deployment
kubectl delete deployment app -n meu-app

# Recriar
kubectl apply -f kubernetes/deployment.yaml

# Forçar pull de nova imagem
kubectl rollout restart deployment/app -n meu-app
```

### Ver Logs em Tempo Real
```bash
# Todos os pods do deployment
kubectl logs -f deployment/app -n meu-app

# Pod específico
kubectl logs -f POD_NAME -n meu-app

# Container específico
kubectl logs -f POD_NAME -c CONTAINER_NAME -n meu-app
```

### Acessar Pod para Debug
```bash
# Shell interativo
kubectl exec -it deployment/app -n meu-app -- bash

# Executar comando único
kubectl exec deployment/app -n meu-app -- php artisan migrate:status
```

---

## 📚 Referências

- [Kubernetes Debugging Pods](https://kubernetes.io/docs/tasks/debug/debug-application/debug-pods/)
- [GitHub Container Registry](https://docs.github.com/packages/working-with-a-github-packages-registry/working-with-the-container-registry)
- [cert-manager Troubleshooting](https://cert-manager.io/docs/troubleshooting/)

---

**Não achou sua solução?** Abra uma issue com:
- Output de `kubectl get all -n seu-namespace`
- Logs relevantes
- Passos para reproduzir o problema
