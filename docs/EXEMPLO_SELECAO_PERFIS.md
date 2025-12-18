# 🎯 Exemplo Prático: Seleção de Perfis de Recursos

## 📺 Como Funciona o Novo Menu Interativo

Quando você executa `./setup.sh`, agora existe um menu interativo para escolher o perfil de recursos.

---

## 🎬 Exemplo 1: Configurando Produção (Opção 1)

### Executando o Script

```bash
cd /caminho/para/kubernetes-vps-setup
./setup.sh
```

### Fluxo Completo

```
╔════════════════════════════════════════════════════════════════╗
║  🚀 Configurador para Projetos Laravel                        ║
║  Versão 2.0.0 - Dev Local + Produção Kubernetes               ║
╚════════════════════════════════════════════════════════════════╝

═══════════════════════════════════════════════════════════════
  INFORMAÇÕES DO PROJETO
═══════════════════════════════════════════════════════════════

📦 Nome do projeto (ex: meu-app): meu-app-prod
🏢 Namespace Kubernetes (ex: meu-app-prod): meu-app-prod
🌐 Domínio principal (ex: app.exemplo.com): app.exemplo.com

═══════════════════════════════════════════════════════════════
  INFORMAÇÕES DO SERVIDOR VPS
═══════════════════════════════════════════════════════════════

🖥️  IP da VPS: 148.230.78.184

═══════════════════════════════════════════════════════════════
  GITHUB CONTAINER REGISTRY
═══════════════════════════════════════════════════════════════

🐙 Usuário/Organização do GitHub: meu-usuario
📦 Nome do repositório GitHub: meu-app-prod

═══════════════════════════════════════════════════════════════
  CONFIGURAÇÕES DO LARAVEL
═══════════════════════════════════════════════════════════════

🔑 APP_KEY (deixe vazio para gerar automaticamente): 
⏳ Gerando APP_KEY...
✅ APP_KEY gerada: base64:aBc123...xyz

📧 Email do APP (ex: admin@app.exemplo.com): admin@app.exemplo.com

═══════════════════════════════════════════════════════════════
  BANCO DE DADOS
═══════════════════════════════════════════════════════════════

🗄️  Nome do banco de dados: laravel
👤 Usuário do banco de dados: laravel

💡 Deixe vazio para gerar senha automática segura
🔐 Senha do PostgreSQL: 
✅ Senha gerada: xY9mK2pL8qR...

═══════════════════════════════════════════════════════════════
  REDIS
═══════════════════════════════════════════════════════════════

💡 Deixe vazio para gerar senha automática segura
🔐 Senha do Redis: 
✅ Senha gerada: nT4hF7jK1wP...

═══════════════════════════════════════════════════════════════
  ARMAZENAMENTO (OPCIONAL)
═══════════════════════════════════════════════════════════════

☁️  Usar DigitalOcean Spaces/S3? (s/n): n

═══════════════════════════════════════════════════════════════
  RECURSOS (CPU/MEMÓRIA)                    ← 🎯 AQUI COMEÇA O NOVO MENU!
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

Escolha uma opção [1-4]: 1    ← Digite apenas "1" e pressione ENTER

✅ Perfil PRODUÇÃO selecionado

Recursos configurados:
  RAM: 512Mi → 1Gi
  CPU: 500m → 1000m
  Réplicas: 2

═══════════════════════════════════════════════════════════════
  RESUMO DA CONFIGURAÇÃO
═══════════════════════════════════════════════════════════════

Projeto:
  Nome: meu-app-prod
  GitHub: meu-usuario/meu-app-prod
  Namespace: meu-app-prod
  Domínio: app.exemplo.com
  
Recursos:
  CPU: 500m → 1000m
  Memória: 512Mi → 1Gi
  Réplicas: 2

...continuação do script...
```

---

## 🎬 Exemplo 2: Configurando Dev (Opção 2)

```bash
./setup.sh
```

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

Escolha uma opção [1-4]: 2    ← Digite "2" para Dev

✅ Perfil DESENVOLVIMENTO selecionado

Recursos configurados:
  RAM: 256Mi → 512Mi
  CPU: 250m → 500m
  Réplicas: 1
```

---

## 🎬 Exemplo 3: Configurando Test (Opção 3)

```bash
./setup.sh
```

```
Escolha uma opção [1-4]: 3    ← Digite "3" para Test

✅ Perfil TEST selecionado

Recursos configurados:
  RAM: 256Mi → 512Mi
  CPU: 250m → 500m
  Réplicas: 1
```

---

## 🎬 Exemplo 4: Configuração Manual (Opção 4)

Útil quando você quer valores diferentes dos perfis padrão.

```bash
./setup.sh
```

```
Escolha uma opção [1-4]: 4    ← Digite "4" para Manual

⚙️  Configuração MANUAL

💾 Memória mínima (ex: 256Mi, 512Mi): 768Mi
💾 Memória máxima (ex: 512Mi, 1Gi): 1536Mi
⚡ CPU mínima (ex: 250m, 500m): 600m
⚡ CPU máxima (ex: 500m, 1000m): 1200m
📊 Número de réplicas: 3

Recursos configurados:
  RAM: 768Mi → 1536Mi
  CPU: 600m → 1200m
  Réplicas: 3
```

---

## 💡 Casos de Uso para Opção Manual

### Caso 1: Staging Environment

Você quer um ambiente intermediário entre Dev e Prod:

```
Opção: 4 (Manual)

💾 Memória mínima: 384Mi
💾 Memória máxima: 768Mi
⚡ CPU mínima: 350m
⚡ CPU máxima: 750m
📊 Réplicas: 2
```

### Caso 2: App com Processamento Pesado

Sua aplicação processa muitas imagens/vídeos:

```
Opção: 4 (Manual)

💾 Memória mínima: 1Gi
💾 Memória máxima: 2Gi
⚡ CPU mínima: 1000m
⚡ CPU máxima: 2000m
📊 Réplicas: 2
```

### Caso 3: Microserviço Leve (API Simples)

API REST simples com pouco processamento:

```
Opção: 4 (Manual)

💾 Memória mínima: 128Mi
💾 Memória máxima: 256Mi
⚡ CPU mínima: 100m
⚡ CPU máxima: 250m
📊 Réplicas: 1
```

---

## 📊 Tabela Comparativa

| Caso de Uso | Perfil Recomendado | Réplicas | RAM | CPU |
|-------------|-------------------|----------|-----|-----|
| **Produção** | Opção 1 | 2 | 512Mi-1Gi | 500m-1000m |
| **Desenvolvimento** | Opção 2 | 1 | 256Mi-512Mi | 250m-500m |
| **Testes/QA** | Opção 3 | 1 | 256Mi-512Mi | 250m-500m |
| **Staging** | Opção 4 | 2 | 384Mi-768Mi | 350m-750m |
| **API Leve** | Opção 4 | 1 | 128Mi-256Mi | 100m-250m |
| **Processamento Pesado** | Opção 4 | 2 | 1Gi-2Gi | 1000m-2000m |
| **Alta Demanda** | Opção 4 | 3-4 | 512Mi-1Gi | 500m-1000m |

---

## ❓ FAQ

### P: Posso mudar de perfil depois?

**R:** Sim! Basta:
1. Executar `./setup.sh` novamente
2. Escolher novo perfil
3. Aplicar as alterações: `kubectl apply -f kubernetes/deployment.yaml`

### P: O que significa "m" em CPU?

**R:** "m" significa "milicores" ou "milli-CPU".
- 1000m = 1 vCPU completo
- 500m = metade de 1 vCPU
- 250m = 1/4 de 1 vCPU

### P: Como saber se escolhi o perfil certo?

**R:** Monitore após o deploy:

```bash
# Ver uso atual
kubectl top pods -n seu-namespace

# Se CPU ou RAM estiver sempre > 80%, considere aumentar
```

### P: Posso ter 3 apps (prod, dev, test) na mesma VPS?

**R:** Sim! Com VPS de 4 vCPUs e 16GB RAM, você pode rodar:
- 1 Produção (Opção 1)
- 1 Dev (Opção 2)
- 1 Test (Opção 3)

Isso consumirá:
- **CPU:** ~2.8 vCPU (requests), ~5.2 vCPU (limits - pode ultrapassar)
- **RAM:** ~6 GB (requests), ~9 GB (limits)
- **Margem segura:** ✅ Sim, sobra RAM e permite burst de CPU

### P: Opção Manual funciona com valores diferentes do padrão?

**R:** Sim! Você pode usar **qualquer valor** válido do Kubernetes:
- RAM: `128Mi`, `256Mi`, `512Mi`, `1Gi`, `2Gi`, etc.
- CPU: `100m`, `250m`, `500m`, `1000m`, `2000m`, etc.
- Réplicas: `1`, `2`, `3`, `4`, etc.

---

## ✅ Resumo

| Vantagem | Descrição |
|----------|-----------|
| **⚡ Rápido** | Apenas 1 clique - digite o número |
| **🎯 Otimizado** | Valores testados para VPS 4 vCPU/16GB |
| **🔄 Consistente** | Mesmos perfis para todos os projetos |
| **⚙️ Flexível** | Opção Manual para casos específicos |
| **📖 Documentado** | Cada perfil explicado claramente |

**Próximo passo:** Leia [RESOURCE_ALLOCATION.md](RESOURCE_ALLOCATION.md) para detalhes sobre cada perfil.
