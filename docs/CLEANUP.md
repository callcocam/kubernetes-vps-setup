# 🧹 Limpeza e Remoção

> Comandos para remover imagens Docker e apps Kubernetes

---

## 🗑️ Remover App do Kubernetes

### Deletar Namespace Completo (Remove Tudo)

```bash
# VPS ou Minikube - deleta TUDO do projeto
kubectl delete namespace {{NAMESPACE}}
```

**Isso remove:**
- ✅ Deployment (pods da aplicação)
- ✅ StatefulSets (PostgreSQL, Redis)
- ✅ Services
- ✅ Ingress
- ✅ ConfigMaps
- ✅ Secrets
- ✅ **DADOS do banco** (PostgreSQL e Redis)

⚠️ **Atenção**: Dados serão **perdidos permanentemente**!

---

### Remover Recursos Específicos (Manter Dados)

```bash
# Remover apenas a aplicação (mantém PostgreSQL e Redis)
kubectl delete deployment app -n {{NAMESPACE}}

# Remover serviços
kubectl delete service app-service -n {{NAMESPACE}}
kubectl delete ingress app-ingress -n {{NAMESPACE}}

# Verificar o que sobrou
kubectl get all -n {{NAMESPACE}}
```

---

## 🐳 Remover Imagens Docker

### Imagens Locais (Docker Desktop/Docker Engine)

```bash
# Listar imagens do projeto
docker images | grep {{GITHUB_REPO_NAME}}

# Remover imagem específica
docker rmi {{GITHUB_REPO}}:latest

# Remover todas as versões (tags)
docker rmi $(docker images {{GITHUB_REPO}} -q)

# Forçar remoção (se houver containers usando)
docker rmi -f {{GITHUB_REPO}}:latest
```

---

### Imagens no Minikube

```bash
# Listar imagens no Minikube
minikube image ls | grep {{GITHUB_REPO_NAME}}

# Remover imagem do Minikube
minikube image rm {{GITHUB_REPO}}:latest

# Remover imagem Docker local E do Minikube
docker rmi {{GITHUB_REPO}}:latest
minikube image rm {{GITHUB_REPO}}:latest
```

---

## 🔄 Limpeza Completa (Docker + Kubernetes)

```bash
# 1. Deletar namespace Kubernetes
kubectl delete namespace {{NAMESPACE}}

# 2. Remover imagem do Minikube
minikube image rm {{GITHUB_REPO}}:latest

# 3. Remover imagem Docker local
docker rmi {{GITHUB_REPO}}:latest

# 4. Verificar limpeza
kubectl get namespaces | grep {{NAMESPACE}}
docker images | grep {{GITHUB_REPO_NAME}}
minikube image ls | grep {{GITHUB_REPO_NAME}}
```

---

## 🗄️ Limpeza de Dados na VPS

### Remover Diretórios de Dados (PostgreSQL e Redis)

```bash
# Conectar na VPS
ssh root@{{VPS_IP}}

# CUIDADO: Remove dados permanentemente!
rm -rf /data/postgresql/{{NAMESPACE}}
rm -rf /data/redis/{{NAMESPACE}}

# Verificar remoção
ls -la /data/postgresql/
ls -la /data/redis/

exit
```

---

## 🔍 Verificar Recursos Restantes

### Kubernetes

```bash
# Verificar se namespace foi deletado
kubectl get namespaces | grep {{NAMESPACE}}

# Listar todos os recursos (se namespace ainda existir)
kubectl get all -n {{NAMESPACE}}

# Verificar PersistentVolumeClaims
kubectl get pvc -n {{NAMESPACE}}
```

### Docker

```bash
# Verificar imagens restantes
docker images | grep {{GITHUB_REPO_NAME}}

# Verificar containers parados
docker ps -a | grep {{GITHUB_REPO_NAME}}

# Remover containers parados
docker rm $(docker ps -a | grep {{GITHUB_REPO_NAME}} | awk '{print $1}')
```

---

## 🆘 Solução de Problemas

### Namespace não deleta (fica em "Terminating")

```bash
# Forçar deleção do namespace
kubectl delete namespace {{NAMESPACE}} --force --grace-period=0

# Se ainda não deletar, remover finalizers
kubectl get namespace {{NAMESPACE}} -o json | \
  jq '.spec.finalizers = []' | \
  kubectl replace --raw "/api/v1/namespaces/{{NAMESPACE}}/finalize" -f -
```

### Imagem Docker não remove (em uso)

```bash
# Ver containers usando a imagem
docker ps -a --filter ancestor={{GITHUB_REPO}}:latest

# Parar e remover containers
docker stop $(docker ps -a --filter ancestor={{GITHUB_REPO}}:latest -q)
docker rm $(docker ps -a --filter ancestor={{GITHUB_REPO}}:latest -q)

# Agora remover imagem
docker rmi {{GITHUB_REPO}}:latest
```

---

## 📋 Checklist de Limpeza

**Kubernetes:**
- [ ] Namespace deletado: `kubectl get ns | grep {{NAMESPACE}}`
- [ ] Nenhum pod restante: `kubectl get pods -n {{NAMESPACE}}`
- [ ] Nenhum PVC restante: `kubectl get pvc -n {{NAMESPACE}}`

**Docker:**
- [ ] Imagem local removida: `docker images | grep {{GITHUB_REPO_NAME}}`
- [ ] Imagem Minikube removida: `minikube image ls | grep {{GITHUB_REPO_NAME}}`
- [ ] Containers removidos: `docker ps -a | grep {{GITHUB_REPO_NAME}}`

**VPS (se aplicável):**
- [ ] Diretórios de dados removidos
- [ ] Verificado: `ssh root@{{VPS_IP}} "ls /data/postgresql/"`

---

**✅ Pronto!** Projeto completamente removido.
