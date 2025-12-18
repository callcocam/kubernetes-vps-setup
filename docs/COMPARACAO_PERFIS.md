# 📊 Comparação Visual dos Perfis de Recursos

## 🎯 Guia Rápido de Decisão

```
┌─────────────────────────────────────────────────────────────┐
│  Que tipo de ambiente você está configurando?              │
└─────────────────────────────────────────────────────────────┘
                            │
            ┌───────────────┼───────────────┐
            │               │               │
            ▼               ▼               ▼
      
   🚀 PRODUÇÃO      🛠️ DESENVOLVIMENTO    🧪 TEST/QA
   
   App em produção   Desenvolver código   Testes automáticos
   Tráfego real      Local/temporário     CI/CD, staging
   Alta disponib.    Sem redundância      Sem redundância
   
   Opção 1           Opção 2              Opção 3
```

---

## 📊 Comparação Detalhada

### 🚀 Perfil 1: Produção

```yaml
replicas: 2
resources:
  requests:
    memory: "512Mi"    # Garantido
    cpu: "500m"        # Garantido (0.5 vCPU)
  limits:
    memory: "1Gi"      # Máximo
    cpu: "1000m"       # Máximo (1 vCPU)
```

**✅ Quando usar:**
- Site/app em produção
- Precisa de alta disponibilidade (2 réplicas)
- Tráfego de usuários reais
- SLA importante

**📊 Consumo Total (com PostgreSQL + Redis):**
- CPU Request: ~1.35 vCPU
- CPU Limit: ~2.7 vCPU
- RAM Request: ~1.6 GB
- RAM Limit: ~3.2 GB

**💰 % da VPS (4 vCPUs, 16GB):**
- CPU: 34% (request) → 67% (limit)
- RAM: 10% (request) → 20% (limit)

---

### 🛠️ Perfil 2: Desenvolvimento

```yaml
replicas: 1
resources:
  requests:
    memory: "256Mi"    # Garantido
    cpu: "250m"        # Garantido (0.25 vCPU)
  limits:
    memory: "512Mi"    # Máximo
    cpu: "500m"        # Máximo (0.5 vCPU)
```

**✅ Quando usar:**
- Ambiente de desenvolvimento
- Testar features antes de ir pra produção
- Não precisa de redundância
- Poucos usuários simultâneos

**📊 Consumo Total (com PostgreSQL + Redis):**
- CPU Request: ~0.4 vCPU
- CPU Limit: ~0.85 vCPU
- RAM Request: ~576 MB
- RAM Limit: ~1.1 GB

**💰 % da VPS (4 vCPUs, 16GB):**
- CPU: 10% (request) → 21% (limit)
- RAM: 3.5% (request) → 6.8% (limit)

---

### 🧪 Perfil 3: Test

```yaml
replicas: 1
resources:
  requests:
    memory: "256Mi"    # Garantido
    cpu: "250m"        # Garantido (0.25 vCPU)
  limits:
    memory: "512Mi"    # Máximo
    cpu: "500m"        # Máximo (0.5 vCPU)
```

**✅ Quando usar:**
- Testes automatizados (PHPUnit, etc)
- Ambiente de homologação/staging
- QA antes de deploy em produção
- CI/CD pipelines

**📊 Consumo Total (com PostgreSQL + Redis):**
- CPU Request: ~0.4 vCPU
- CPU Limit: ~0.85 vCPU
- RAM Request: ~576 MB
- RAM Limit: ~1.1 GB

**💰 % da VPS (4 vCPUs, 16GB):**
- CPU: 10% (request) → 21% (limit)
- RAM: 3.5% (request) → 6.8% (limit)

---

### ⚙️ Perfil 4: Manual

```yaml
replicas: ???      # Você define
resources:
  requests:
    memory: "???"  # Você define
    cpu: "???"     # Você define
  limits:
    memory: "???" # Você define
    cpu: "???"    # Você define
```

**✅ Quando usar:**
- Necessidades específicas não cobertas pelos perfis
- App com características únicas
- Otimização avançada
- Experimentos

**💡 Exemplos de casos:**
- Staging: 384Mi-768Mi RAM, 350m-750m CPU, 2 réplicas
- API leve: 128Mi-256Mi RAM, 100m-250m CPU, 1 réplica
- Processamento pesado: 1Gi-2Gi RAM, 1000m-2000m CPU, 2 réplicas

---

## 🎯 Cenário Completo: 3 Apps na Mesma VPS

### Configuração Recomendada

| App | Perfil | Réplicas | RAM Request | RAM Limit | CPU Request | CPU Limit |
|-----|--------|----------|-------------|-----------|-------------|-----------|
| **Produção** | 1 🚀 | 2 | 512Mi | 1Gi | 500m | 1000m |
| **Dev** | 2 🛠️ | 1 | 256Mi | 512Mi | 250m | 500m |
| **Test** | 3 🧪 | 1 | 256Mi | 512Mi | 250m | 500m |

### Consumo Total na VPS

```
┌──────────────────────────────────────────────────────────────┐
│  VPS: 4 vCPUs | 16 GB RAM                                    │
├──────────────────────────────────────────────────────────────┤
│                                                              │
│  CPU (Requests):                                             │
│  ████████████████████████░░░░░░░░░░ 70% (2.8 / 4 vCPU)     │
│                                                              │
│  CPU (Limits):                                               │
│  ████████████████████████████████ 130% (5.2 / 4 vCPU) *OK   │
│                                                              │
│  RAM (Requests):                                             │
│  ███████████░░░░░░░░░░░░░░░░░░░░░ 37% (6 / 16 GB)          │
│                                                              │
│  RAM (Limits):                                               │
│  ████████████████░░░░░░░░░░░░░░░░ 56% (9 / 16 GB)          │
│                                                              │
└──────────────────────────────────────────────────────────────┘

✅ Margem de segurança: RAM com 44% livre (7GB)
✅ CPU pode fazer burst além de 100% (comportamento normal do K8s)
```

---

## 💡 Dicas de Escolha

### Escolha Produção (1) se:
- ✅ É o site/app principal da empresa
- ✅ Precisa estar sempre disponível
- ✅ Tem tráfego de usuários reais
- ✅ Downtime custa dinheiro/reputação

### Escolha Dev (2) se:
- ✅ É ambiente de desenvolvimento
- ✅ Poucos desenvolvedores acessam
- ✅ Pode ficar offline sem problemas
- ✅ Usado para testar código novo

### Escolha Test (3) se:
- ✅ Roda testes automatizados
- ✅ Ambiente de staging/homologação
- ✅ QA valida features aqui
- ✅ Não é acessado por usuários finais

### Escolha Manual (4) se:
- ✅ App tem necessidades muito específicas
- ✅ Precisa de mais recursos que Produção
- ✅ Quer experimentar configurações
- ✅ Tem conhecimento avançado de K8s

---

## 📈 Quando Escalar/Reduzir

### Sinais para AUMENTAR recursos:

```bash
# Verificar uso atual
kubectl top pods -n seu-namespace

# Se você vê:
NAME                   CPU     MEMORY
app-7d8f9c8b-abc12     800m    950Mi   ← 80% do limit de CPU
app-7d8f9c8b-def34     750m    900Mi   ← 90% do limit de RAM
```

**Ação:** Re-execute `./setup.sh` e escolha:
- Produção → Manual com valores maiores
- Dev/Test → Produção

### Sinais para REDUZIR recursos:

```bash
kubectl top pods -n seu-namespace

# Se você vê:
NAME                   CPU     MEMORY
app-7d8f9c8b-abc12     50m     100Mi   ← Apenas 10% de uso
```

**Ação:** Re-execute `./setup.sh` e escolha:
- Produção → Dev (se não precisa de 2 réplicas)
- Manual com valores menores

---

## 🎓 Entendendo Request vs Limit

### Request (Garantido)
```
┌────────────┐
│  Request   │  ← Kubernetes GARANTE que você terá isso
│  512Mi     │     Seu pod nunca vai ter menos que isso
└────────────┘
```

### Limit (Máximo)
```
┌────────────┐
│   Limit    │  ← Kubernetes PERMITE até isso
│    1Gi     │     Seu pod pode crescer até esse valor
└────────────┘     Se ultrapassar, pod é morto (OOMKilled)
```

### Exemplo Visual

```
RAM Request: 512Mi          RAM Limit: 1Gi
      │                           │
      ▼                           ▼
      ┌───────────────────────────┐
      │░░░░░░░░░░░│               │
      │ Garantido │  Pode crescer │
      │   512Mi   │  até 1Gi      │
      └───────────────────────────┘
      
Se usar > 1Gi → Pod é reiniciado (OOMKilled)
```

---

## ✅ Checklist Final

Antes de fazer deploy:

- [ ] Escolhi o perfil correto para meu caso de uso
- [ ] Entendo a diferença entre Request e Limit
- [ ] Sei que CPU limits > 100% é normal
- [ ] Vou monitorar com `kubectl top pods`
- [ ] Posso re-configurar depois se necessário

**Pronto para começar?** Execute `./setup.sh` e escolha seu perfil! 🚀
