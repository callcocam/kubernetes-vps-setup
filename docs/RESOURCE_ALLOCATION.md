# 🎯 Guia de Alocação de Recursos para VPS

## 📊 Recursos da Sua VPS

**Servidor:** srv1103343.hstgr.cloud  
**Localização:** São Paulo, Brasil  
**Sistema:** Ubuntu 24.04 LTS

| Recurso | Capacidade |
|---------|-----------|
| **vCPUs** | 4 núcleos |
| **RAM** | 16 GB |
| **Disco** | 200 GB |
| **IPv4** | 148.230.78.184 |
| **IPv6** | 2a02:4780:14:3373::1 |

---

## ⭐ NOVO: Seleção Rápida de Perfis

Agora você pode escolher entre **4 perfis pré-configurados** ao executar `./setup.sh`:

### 🎯 Perfis Disponíveis

| Perfil | Réplicas | RAM | CPU | Quando Usar |
|--------|----------|-----|-----|-------------|
| **🚀 Produção** | 2 | 512Mi → 1Gi | 500m → 1000m | Apps em produção com tráfego real |
| **🛠️ Dev** | 1 | 256Mi → 512Mi | 250m → 500m | Ambiente de desenvolvimento |
| **🧪 Test** | 1 | 256Mi → 512Mi | 250m → 500m | Testes automatizados e QA |
| **⚙️ Manual** | Custom | Custom | Custom | Configuração personalizada |

**Vantagens:**
- ✅ Configuração em **1 clique** - apenas digite o número
- ✅ Valores otimizados para VPS com 4 vCPUs / 16GB RAM
- ✅ Consistência entre ambientes
- ✅ Ainda pode customizar via opção Manual

---

## 🎯 Planejamento para 3 Aplicações

Com 4 vCPUs e 16 GB de RAM, você pode rodar confortavelmente 3 aplicações Laravel:

- **Produção** (maior prioridade) → 50% dos recursos
- **Dev** (desenvolvimento) → 25% dos recursos  
- **Test** (testes) → 25% dos recursos

### 🔄 Considerações Importantes

**Recursos Compartilhados (já rodando no cluster):**
- Ingress Controller (Nginx): ~200Mi RAM, ~100m CPU
- cert-manager: ~100Mi RAM, ~50m CPU
- Sistema Operacional: ~2GB RAM
- Overhead Kubernetes: ~1GB RAM

**Recursos Disponíveis para Apps:**
- RAM utilizável: ~12.5 GB
- CPU utilizável: ~3.7 vCPUs

---

## 🚀 PRODUÇÃO - Configuração Recomendada

### Características
✅ Alta disponibilidade (2 réplicas)  
✅ Recursos generosos para tráfego real  
✅ Auto-scaling preparado  

### Configuração no setup.sh

Quando rodar `./setup.sh` para o app de **produção**, use:

```bash
💾 Memória mínima: 512Mi
💾 Memória máxima: 1Gi
⚡ CPU mínima: 500m
⚡ CPU máxima: 1000m
📊 Número de réplicas: 2
```

### Recursos Consumidos

| Componente | Réplicas | CPU Request | CPU Limit | Memory Request | Memory Limit |
|------------|----------|-------------|-----------|----------------|--------------|
| **Laravel App** | 2 | 500m × 2 = 1 vCPU | 1000m × 2 = 2 vCPU | 512Mi × 2 = 1GB | 1Gi × 2 = 2GB |
| **PostgreSQL** | 1 | 250m | 500m | 512Mi | 1Gi |
| **Redis** | 1 | 100m | 200m | 128Mi | 256Mi |
| **Total Produção** | - | **~1.35 vCPU** | **~2.7 vCPU** | **~1.6 GB** | **~3.2 GB** |

### Namespace

```bash
Namespace: meu-app-prod
```

---

## 🛠️ DEV - Configuração Recomendada

### Características
✅ Ambiente para desenvolvimento  
✅ 1 réplica (sem necessidade de HA)  
✅ Recursos moderados  

### Configuração no setup.sh

Quando rodar `./setup.sh` para o app de **dev**, use:

```bash
💾 Memória mínima: 256Mi
💾 Memória máxima: 512Mi
⚡ CPU mínima: 250m
⚡ CPU máxima: 500m
📊 Número de réplicas: 1
```

### Recursos Consumidos

| Componente | Réplicas | CPU Request | CPU Limit | Memory Request | Memory Limit |
|------------|----------|-------------|-----------|----------------|--------------|
| **Laravel App** | 1 | 250m | 500m | 256Mi | 512Mi |
| **PostgreSQL** | 1 | 100m | 250m | 256Mi | 512Mi |
| **Redis** | 1 | 50m | 100m | 64Mi | 128Mi |
| **Total Dev** | - | **~0.4 vCPU** | **~0.85 vCPU** | **~576 MB** | **~1.1 GB** |

### Namespace

```bash
Namespace: meu-app-dev
```

---

## 🧪 TEST - Configuração Recomendada

### Características
✅ Ambiente para testes automatizados  
✅ 1 réplica  
✅ Recursos similares ao Dev  

### Configuração no setup.sh

Quando rodar `./setup.sh` para o app de **test**, use:

```bash
💾 Memória mínima: 256Mi
💾 Memória máxima: 512Mi
⚡ CPU mínima: 250m
⚡ CPU máxima: 500m
📊 Número de réplicas: 1
```

### Recursos Consumidos

| Componente | Réplicas | CPU Request | CPU Limit | Memory Request | Memory Limit |
|------------|----------|-------------|-----------|----------------|--------------|
| **Laravel App** | 1 | 250m | 500m | 256Mi | 512Mi |
| **PostgreSQL** | 1 | 100m | 250m | 256Mi | 512Mi |
| **Redis** | 1 | 50m | 100m | 64Mi | 128Mi |
| **Total Test** | - | **~0.4 vCPU** | **~0.85 vCPU** | **~576 MB** | **~1.1 GB** |

### Namespace

```bash
Namespace: meu-app-test
```

---

## 📊 Resumo Total de Recursos

### Uso Total (Request)

| Ambiente | CPU Request | Memory Request |
|----------|-------------|----------------|
| **Produção** | 1.35 vCPU | 1.6 GB |
| **Dev** | 0.4 vCPU | 576 MB |
| **Test** | 0.4 vCPU | 576 MB |
| **Infraestrutura** | 0.15 vCPU | 300 MB |
| **Sistema/Overhead** | 0.5 vCPU | 3 GB |
| **TOTAL** | **~2.8 vCPU** | **~6 GB** |

### Uso Total (Limits)

| Ambiente | CPU Limit | Memory Limit |
|----------|-----------|--------------|
| **Produção** | 2.7 vCPU | 3.2 GB |
| **Dev** | 0.85 vCPU | 1.1 GB |
| **Test** | 0.85 vCPU | 1.1 GB |
| **Infraestrutura** | 0.35 vCPU | 500 MB |
| **Sistema/Overhead** | 0.5 vCPU | 3 GB |
| **TOTAL** | **~5.2 vCPU** | **~9 GB** |

### 💡 Análise

✅ **CPU:** Requests em ~70% (2.8/4), Limits em ~130% (5.2/4)  
✅ **Memória:** Requests em ~37% (6/16), Limits em ~56% (9/16)  

**Status:** ✅ **Configuração saudável!**

- Você tem boa margem de segurança na memória
- CPU limits podem ultrapassar 100% (é normal em Kubernetes)
- Requests garantem recursos mínimos sem contenção
- Sistema pode escalar bursts de CPU quando necessário

---

## 🚀 Como Aplicar as Configurações

### Modo Rápido: Seleção de Perfil (NOVO! ⭐)

O `setup.sh` agora oferece 4 opções pré-configuradas:

```bash
cd /caminho/para/kubernetes-vps-setup
./setup.sh
```

Quando chegar na seção de recursos, você verá:

```
═══════════════════════════════════════════════════════════════
  RECURSOS (CPU/MEMÓRIA)
═══════════════════════════════════════════════════════════════

💡 Escolha um perfil de recursos ou configure manualmente:

1) 🚀 Produção - Alta disponibilidade
   └─ 2 réplicas | RAM: 512Mi-1Gi | CPU: 500m-1000m
   └─ Recomendado para apps em produção com tráfego real

2) 🛠️  Desenvolvimento - Recursos moderados
   └─ 1 réplica | RAM: 256Mi-512Mi | CPU: 250m-500m
   └─ Para ambiente de desenvolvimento

3) 🧪 Test - Recursos moderados
   └─ 1 réplica | RAM: 256Mi-512Mi | CPU: 250m-500m
   └─ Para testes automatizados e homologação

4) ⚙️  Manual - Configuração customizada
   └─ Você define todos os valores

Escolha uma opção [1-4]:
```

**Basta digitar o número e pressionar ENTER!**

---

### Exemplo Completo: Configurar os 3 Ambientes

#### Passo 1: Configurar Produção (Opção 1)

```bash
./setup.sh
```

Preencha:
```
📦 Nome do projeto: meu-app-prod
🏢 Namespace: meu-app-prod
🌐 Domínio: app.exemplo.com
🖥️  IP da VPS: 148.230.78.184
🐙 Usuário GitHub: seu-usuario
📦 Repositório: meu-app-prod

# Quando chegar em recursos:
Escolha uma opção [1-4]: 1    ← Digite 1 para Produção

✅ Perfil PRODUÇÃO selecionado
```

#### Passo 2: Configurar Dev (Opção 2)

```bash
./setup.sh
```

Preencha:
```
📦 Nome do projeto: meu-app-dev
🏢 Namespace: meu-app-dev
🌐 Domínio: dev.exemplo.com
🖥️  IP da VPS: 148.230.78.184

# Quando chegar em recursos:
Escolha uma opção [1-4]: 2    ← Digite 2 para Dev

✅ Perfil DESENVOLVIMENTO selecionado
```

#### Passo 3: Configurar Test (Opção 3)

```bash
./setup.sh
```

Preencha:
```
📦 Nome do projeto: meu-app-test
🏢 Namespace: meu-app-test
🌐 Domínio: test.exemplo.com
🖥️  IP da VPS: 148.230.78.184

# Quando chegar em recursos:
Escolha uma opção [1-4]: 3    ← Digite 3 para Test

✅ Perfil TEST selecionado
```

---

### Modo Manual (Opção 4)

Se você quiser valores customizados diferentes dos perfis:

```bash
./setup.sh
```

Quando chegar em recursos:
```
Escolha uma opção [1-4]: 4    ← Digite 4 para Manual

⚙️  Configuração MANUAL

💾 Memória mínima (ex: 256Mi, 512Mi): 1Gi
💾 Memória máxima (ex: 512Mi, 1Gi): 2Gi
⚡ CPU mínima (ex: 250m, 500m): 750m
⚡ CPU máxima (ex: 500m, 1000m): 1500m
📊 Número de réplicas: 3
```

---

### Modo Antigo (Ainda Funciona)

Quando rodar `./setup.sh` para o app de **produção**, use:

```bash
💾 Memória mínima: 512Mi
💾 Memória máxima: 1Gi
⚡ CPU mínima: 500m
⚡ CPU máxima: 1000m
📊 Número de réplicas: 2
```

---

## 📈 Monitoramento de Recursos

### Ver uso atual de recursos

```bash
# Por namespace
kubectl top nodes
kubectl top pods -n meu-app-prod
kubectl top pods -n meu-app-dev
kubectl top pods -n meu-app-test

# Todos os namespaces
kubectl top pods --all-namespaces
```

### Ver recursos alocados

```bash
# Ver requests e limits configurados
kubectl describe deployment app -n meu-app-prod | grep -A 5 "Limits:"
```

### Verificar saúde geral

```bash
# Ver consumo do node
kubectl describe node

# Ver pods com problemas de recursos
kubectl get pods --all-namespaces | grep -E '(OOMKilled|Evicted)'
```

---

## ⚠️ Problemas Comuns e Soluções

### 1. Pod com status "OOMKilled" (Falta de memória)

**Sintoma:** Pod reinicia constantemente

```bash
kubectl get pods -n meu-app-prod
# NAME                   READY   STATUS      RESTARTS
# app-7d8f9c8b-abc12     0/1     OOMKilled   5
```

**Solução:** Aumentar memory limit no deployment.yaml

```yaml
resources:
  limits:
    memory: "1Gi"  # Era 512Mi, aumentar para 1Gi
```

### 2. CPU Throttling (App lento)

**Sintoma:** App lento mesmo com pouco uso

```bash
# Verificar throttling
kubectl top pods -n meu-app-prod
```

**Solução:** Aumentar CPU limit

```yaml
resources:
  limits:
    cpu: "1000m"  # Era 500m, aumentar
```

### 3. Pods em "Pending" (Recursos insuficientes)

**Sintoma:** Pod não consegue ser agendado

```bash
kubectl describe pod app-xxx -n meu-app-prod
# Events: 0/1 nodes are available: insufficient memory
```

**Solução:**
1. Reduzir requests de outros apps
2. Remover um ambiente (dev ou test temporariamente)
3. Adicionar mais recursos ao servidor

---

## 📚 Referências

- [Kubernetes Resource Management](https://kubernetes.io/docs/concepts/configuration/manage-resources-containers/)
- [Resource Quotas](https://kubernetes.io/docs/concepts/policy/resource-quotas/)
- [Quality of Service (QoS)](https://kubernetes.io/docs/tasks/configure-pod-container/quality-service-pod/)

---

## 💡 Dicas Extras

### Quando aumentar recursos de Produção?

Monitore métricas por 1 semana:
- **CPU > 80%** consistentemente → aumentar CPU
- **Memória > 80%** → aumentar memory
- **Latência alta** → adicionar mais réplicas

### Otimizações de Custo

Se você NÃO usar todos os 3 ambientes ao mesmo tempo:

**Opção 1:** Apagar Test quando não usar
```bash
kubectl delete namespace meu-app-test
```

**Opção 2:** Escalar Dev para 0 réplicas
```bash
kubectl scale deployment app --replicas=0 -n meu-app-dev
```

**Opção 3:** Usar mesma VPS para dev local (sem Kubernetes)
- Dev roda no Docker Compose local
- Apenas Prod e Test no Kubernetes

---

## ✅ Checklist de Configuração

- [ ] Executar `./setup.sh` para ambiente de **Produção**
  - [ ] Escolher opção **1** (Produção) no menu de recursos
  - [ ] Namespace: `meu-app-prod`
  - [ ] Domínio: `app.exemplo.com`
  
- [ ] Executar `./setup.sh` para ambiente de **Dev**
  - [ ] Escolher opção **2** (Desenvolvimento) no menu de recursos
  - [ ] Namespace: `meu-app-dev`
  - [ ] Domínio: `dev.exemplo.com`
  
- [ ] Executar `./setup.sh` para ambiente de **Test**
  - [ ] Escolher opção **3** (Test) no menu de recursos
  - [ ] Namespace: `meu-app-test`
  - [ ] Domínio: `test.exemplo.com`
  
- [ ] Verificar que todos os pods estão rodando: `kubectl get pods --all-namespaces`
- [ ] Confirmar uso de recursos: `kubectl top nodes`
- [ ] Testar acesso aos domínios de cada ambiente
- [ ] Configurar monitoramento/alertas (opcional)

---

## 🎯 Comparação Rápida dos Perfis

| Característica | 🚀 Produção | 🛠️ Dev | 🧪 Test | ⚙️ Manual |
|----------------|-------------|---------|---------|-----------|
| **Réplicas** | 2 | 1 | 1 | Você escolhe |
| **RAM (Request)** | 512Mi | 256Mi | 256Mi | Você escolhe |
| **RAM (Limit)** | 1Gi | 512Mi | 512Mi | Você escolhe |
| **CPU (Request)** | 500m | 250m | 250m | Você escolhe |
| **CPU (Limit)** | 1000m | 500m | 500m | Você escolhe |
| **Alta Disponibilidade** | ✅ Sim | ❌ Não | ❌ Não | Depende |
| **Uso Total CPU** | ~1.35 vCPU | ~0.4 vCPU | ~0.4 vCPU | - |
| **Uso Total RAM** | ~1.6 GB | ~576 MB | ~576 MB | - |
| **Quando Usar** | Produção real | Desenvolvimento | Testes/QA | Casos especiais |

### 💡 Dica: Quando Usar Manual?

Use a opção **Manual (4)** quando:
- Você tem requisitos específicos não cobertos pelos perfis
- Quer experimentar diferentes configurações
- Precisa de mais recursos que o perfil Produção
- Está otimizando para um caso de uso específico

Exemplos:
```bash
# App com muito processamento de imagem
Opção 4 → CPU: 1000m-2000m, RAM: 1Gi-2Gi, Réplicas: 2

# Microserviço leve (API simples)
Opção 4 → CPU: 100m-250m, RAM: 128Mi-256Mi, Réplicas: 1

# Staging (entre dev e prod)
Opção 4 → CPU: 350m-750m, RAM: 384Mi-768Mi, Réplicas: 2
```

---

**Data:** Dezembro 2025  
**Versão:** 1.0
