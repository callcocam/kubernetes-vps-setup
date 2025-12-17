# 📚 Documentação - {{PROJECT_NAME}}

Esta pasta contém toda a documentação para configurar e fazer deploy do projeto **{{PROJECT_NAME}}** no Kubernetes.

## ℹ️ Configuração do Projeto

- **Projeto**: {{PROJECT_NAME}}
- **Namespace**: {{NAMESPACE}}
- **Domínio**: {{DOMAIN}}
- **VPS**: {{VPS_IP}}
- **GitHub**: {{GITHUB_REPO}}

## 🎯 Comece Aqui

**Primeira vez?** → [INDEX.md](INDEX.md) - Guia de navegação completo

**Quer deploy rápido?** → [QUICK_START.md](QUICK_START.md) - 30 minutos do zero ao deploy

## 📖 Documentação Disponível

### Para Iniciantes
- **[INDEX.md](INDEX.md)** - Guia de navegação e escolha do seu caminho
- **[QUICK_START.md](QUICK_START.md)** - Deploy em 30 minutos
- **[SETUP_README.md](SETUP_README.md)** - Visão geral do configurador

### Guias Completos
- **[DEPLOY_VPS.md](DEPLOY_VPS.md)** - Guia completo simplificado (PARTE 1: VPS + PARTE 2: Laravel)
- **[DEPLOY_VPS_ADVANCED.md](DEPLOY_VPS_ADVANCED.md)** - Referência técnica detalhada com YAMLs completos
- **[DEV_LOCAL.md](DEV_LOCAL.md)** - Ambiente de desenvolvimento local

### Referências
- **[FILE_STRUCTURE.md](FILE_STRUCTURE.md)** - Estrutura de arquivos gerados explicada
- **[MULTIPLE_APPS.md](MULTIPLE_APPS.md)** - Rodar múltiplos apps Laravel na mesma VPS
- **[EXAMPLES.md](EXAMPLES.md)** - Exemplos de casos de uso reais
- **[SUMMARY.md](SUMMARY.md)** - Resumo da estrutura completa

## 🚀 Fluxo Recomendado

```
1. Leia INDEX.md → Escolha seu caminho
2. Configure VPS → DEPLOY_VPS.md (Parte 1) - apenas uma vez
3. Execute ./setup.sh → Gera arquivos automaticamente
4. Deploy rápido → QUICK_START.md
5. Múltiplos apps? → MULTIPLE_APPS.md
```

## 💡 Dica

Esta documentação foi copiada automaticamente pelo `setup.sh`. Se precisar da versão mais atualizada, ela está em `kubernetes-vps-setup/docs/`.
