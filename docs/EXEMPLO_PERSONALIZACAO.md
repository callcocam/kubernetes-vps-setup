# 📝 Exemplo de Personalização da Documentação

Este arquivo mostra como a documentação é personalizada automaticamente pelo `setup.sh`.

## Como Funciona

Quando você executa `./setup.sh` e informa:

```
📦 Nome do projeto: minha-loja
🏢 Namespace: minha-loja
🌐 Domínio: loja.exemplo.com.br
🖥️  IP da VPS: 198.51.100.42
🐙 GitHub: meuusuario/minha-loja-api
```

## Antes (Template Original)

```markdown
# Conectar na VPS
ssh root@203.0.113.10

# Ver pods
kubectl get pods -n meu-app

# Testar aplicação
curl https://app.exemplo.com
```

## Depois (Documentação Personalizada)

```markdown
# Conectar na VPS
ssh root@198.51.100.42

# Ver pods
kubectl get pods -n minha-loja

# Testar aplicação
curl https://loja.exemplo.com.br
```

## Benefícios

✅ **Comandos prontos para copiar/colar** - Não precisa substituir manualmente
✅ **Reduz erros** - Valores corretos desde o início
✅ **Experiência personalizada** - Documentação específica do seu projeto
✅ **Onboarding rápido** - Novos desenvolvedores seguem docs corretas

## Placeholders Substituídos

- `{{PROJECT_NAME}}` → Nome do projeto
- `{{NAMESPACE}}` → Namespace Kubernetes
- `{{DOMAIN}}` → Domínio da aplicação
- `{{VPS_IP}}` → IP do servidor
- `{{GITHUB_REPO}}` → Repositório GitHub
- `{{DB_NAME}}` → Nome do banco de dados
- `{{DB_USER}}` → Usuário do banco
- `{{REPLICAS}}` → Número de réplicas
- `{{MEM_REQUEST}}` → Memória solicitada
- `{{MEM_LIMIT}}` → Limite de memória
- `{{CPU_REQUEST}}` → CPU solicitada
- `{{CPU_LIMIT}}` → Limite de CPU
- `{{APP_EMAIL}}` → Email do app
- `{{APP_KEY}}` → Chave da aplicação

## Arquivos Personalizados

Todos os arquivos em `docs/` são processados:

- ✅ QUICK_START.md
- ✅ MULTIPLE_APPS.md  
- ✅ README.md
- ✅ DEPLOY_VPS.md (se tiver placeholders)
- ✅ E qualquer outro .md na pasta

---

**Resultado**: Documentação 100% pronta para o seu projeto! 🚀
