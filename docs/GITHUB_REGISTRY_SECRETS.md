# Kubernetes Setup

## ImagePullSecret para GitHub Container Registry

Para permitir que o Kubernetes faça pull das imagens privadas do GitHub Container Registry, você precisa criar um secret com suas credenciais do GitHub.

### 1. Criar um Personal Access Token (PAT) do GitHub

1. Vá para: https://github.com/settings/tokens
2. Clique em "Generate new token" → "Generate new token (classic)"
3. Dê um nome descritivo (ex: "Kubernetes GHCR Pull")
4. Selecione os seguintes scopes:
   - `read:packages` - Baixar imagens do container registry
5. Clique em "Generate token" e **copie o token** (você não poderá vê-lo novamente)

### 2. Criar o Secret no Kubernetes

Execute o seguinte comando substituindo `YOUR_GITHUB_USERNAME` e `YOUR_GITHUB_TOKEN`:

```bash
kubectl create secret docker-registry ghcr-secret \
  --docker-server=ghcr.io \
  --docker-username=YOUR_GITHUB_USERNAME \
  --docker-password=YOUR_GITHUB_TOKEN \
  --docker-email=YOUR_EMAIL \
  -n plannerate
```

**Exemplo:**
```bash
kubectl create secret docker-registry ghcr-secret \
  --docker-server=ghcr.io \
  --docker-username=callcocam \
  --docker-password=ghp_abc123... \
  --docker-email=your@email.com \
  -n plannerate
```

### 3. Verificar se o Secret foi Criado

```bash
kubectl get secret ghcr-secret -n plannerate
```

### 4. Aplicar o Deployment

Agora você pode aplicar o deployment:

```bash
kubectl apply -f kubernetes/deployment.yaml -n plannerate
```

### Verificar se os Pods Estão Rodando

```bash
kubectl get pods -n plannerate
kubectl describe pod -l app=laravel-app -n plannerate
```

## Adicionar o Secret via GitHub Actions

Para adicionar o secret automaticamente pelo CI/CD, você pode usar este step:

```yaml
- name: Create ImagePullSecret
  run: |
    kubectl create secret docker-registry ghcr-secret \
      --docker-server=ghcr.io \
      --docker-username=${{ github.actor }} \
      --docker-password=${{ secrets.GITHUB_TOKEN }} \
      --docker-email=${{ github.actor }}@users.noreply.github.com \
      -n plannerate \
      --dry-run=client -o yaml | kubectl apply -f -
```

Isso cria o secret se não existir, ou o atualiza se já existir.
