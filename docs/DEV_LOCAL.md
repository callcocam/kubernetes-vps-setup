# 🛠️ Guia de Desenvolvimento Local

Este guia explica como configurar um ambiente de desenvolvimento local completo usando Docker Compose.

## 🎯 O que está incluído?

- ✅ **PHP 8.4 com Xdebug** - Debug completo no VS Code/PHPStorm
- ✅ **PostgreSQL 16** - Banco de dados com persistência
- ✅ **Redis 7** - Cache, sessões e filas
- ✅ **Nginx** - Servidor web
- ✅ **Queue Worker** - Processa jobs em background
- ✅ **Mailhog** - Captura emails para testes (interface web)
- ✅ **Hot Reload** - Mudanças refletidas instantaneamente

## 🚀 Setup Rápido

### 1. Gerar Arquivos de Desenvolvimento

```bash
cd kubernetes-vps-setup
./setup.sh
# Escolha: [1] Desenvolvimento Local
```

O script gerará:
- `docker-compose.yml`
- `Dockerfile.dev`
- `.env.local`
- `docker/nginx/dev.conf`
- `docker/supervisor/supervisord-dev.conf`
- `docker/php/local.ini`

### 2. Copiar Arquivo .env

```bash
# Copiar .env.local para .env
cp .env.local .env

# Ou se já tem .env, mesclar as configurações
cat .env.local >> .env
```

### 3. Iniciar Containers

```bash
# Subir todos os serviços
docker-compose up -d

# Ver logs
docker-compose logs -f

# Ver logs de um serviço específico
docker-compose logs -f app
```

### 4. Instalar Dependências

```bash
# Entrar no container
docker-compose exec app bash

# Instalar dependências PHP
composer install

# Instalar dependências Node
npm install

# Gerar APP_KEY se necessário
php artisan key:generate

# Executar migrations
php artisan migrate

# Seeders (opcional)
php artisan db:seed
```

## 🌐 Acessar Serviços

| Serviço | URL | Descrição |
|---------|-----|-----------|
| **Aplicação** | http://localhost:8000 | Laravel app |
| **Mailhog** | http://localhost:8025 | Interface de emails |
| **PostgreSQL** | localhost:5432 | Conexão direta ao DB |
| **Redis** | localhost:6379 | Conexão direta ao Redis |

## 🐛 Debugging com Xdebug

### VS Code

1. Instalar extensão **PHP Debug**
2. Criar `.vscode/launch.json`:

```json
{
    "version": "0.2.0",
    "configurations": [
        {
            "name": "Listen for Xdebug",
            "type": "php",
            "request": "launch",
            "port": 9003,
            "pathMappings": {
                "/var/www/html": "${workspaceFolder}"
            }
        }
    ]
}
```

3. Pressionar **F5** para iniciar debug
4. Adicionar breakpoints no código
5. Acessar http://localhost:8000

### PHPStorm

1. **Settings → PHP → Debug**
   - Port: `9003`
   - ✅ Can accept external connections

2. **Settings → PHP → Servers**
   - Name: `Docker`
   - Host: `localhost`
   - Port: `8000`
   - Path mappings: `{project_root} → /var/www/html`

3. Clicar no ícone de telefone 📞 (Start Listening)
4. Adicionar breakpoints
5. Acessar http://localhost:8000

## 📧 Testar Emails

Mailhog captura todos os emails enviados:

1. Acessar http://localhost:8025
2. Enviar email no Laravel:
   ```php
   Mail::to('teste@exemplo.com')->send(new WelcomeEmail());
   ```
3. Ver email na interface do Mailhog

## 🔄 Comandos Úteis

```bash
# Subir serviços
docker-compose up -d

# Parar serviços
docker-compose down

# Parar e remover volumes (CUIDADO: apaga dados!)
docker-compose down -v

# Reconstruir imagens
docker-compose build --no-cache

# Ver status dos containers
docker-compose ps

# Executar comando no container
docker-compose exec app php artisan migrate

# Ver logs em tempo real
docker-compose logs -f

# Entrar no bash do container
docker-compose exec app bash

# Executar testes
docker-compose exec app php artisan test

# Limpar cache
docker-compose exec app php artisan cache:clear
docker-compose exec app php artisan config:clear
docker-compose exec app php artisan route:clear
docker-compose exec app php artisan view:clear

# Acessar PostgreSQL
docker-compose exec postgres psql -U {{DB_USERNAME}} -d {{DB_DATABASE}}

# Acessar Redis CLI
docker-compose exec redis redis-cli -a {{REDIS_PASSWORD}}
```

## 🔧 Customização

### Alterar Portas

Edite `.env`:

```env
APP_PORT=8080        # Aplicação
DB_PORT=5433         # PostgreSQL
REDIS_PORT=6380      # Redis
MAILHOG_WEB_PORT=8026  # Interface Mailhog
```

Recrie os containers:
```bash
docker-compose down
docker-compose up -d
```

### Adicionar Serviço

Edite `docker-compose.yml`:

```yaml
services:
  # ... serviços existentes
  
  minio:
    image: minio/minio:latest
    container_name: {{PROJECT_NAME}}-minio
    ports:
      - "9000:9000"
      - "9001:9001"
    environment:
      MINIO_ROOT_USER: minioadmin
      MINIO_ROOT_PASSWORD: minioadmin
    command: server /data --console-address ":9001"
    networks:
      - {{PROJECT_NAME}}-network
```

## 🧪 Testes

```bash
# Executar todos os testes
docker-compose exec app php artisan test

# Testes com coverage
docker-compose exec app php artisan test --coverage

# Testes específicos
docker-compose exec app php artisan test --filter=ExampleTest

# Pest parallel
docker-compose exec app php artisan test --parallel
```

## 🗄️ Backups Locais

```bash
# Backup do banco de dados
docker-compose exec postgres pg_dump -U {{DB_USERNAME}} {{DB_DATABASE}} > backup.sql

# Restaurar backup
docker-compose exec -T postgres psql -U {{DB_USERNAME}} {{DB_DATABASE}} < backup.sql

# Backup do Redis
docker-compose exec redis redis-cli -a {{REDIS_PASSWORD}} SAVE
docker-compose cp redis:/data/dump.rdb ./redis-backup.rdb
```

## 🔍 Troubleshooting

### Erro: "Port already in use"

```bash
# Ver o que está usando a porta
sudo lsof -i :8000

# Alterar porta no .env
APP_PORT=8001
docker-compose down && docker-compose up -d
```

### Permissões no storage/

```bash
docker-compose exec app chmod -R 777 storage bootstrap/cache
docker-compose exec app chown -R www-data:www-data storage bootstrap/cache
```

### Cache de configuração

```bash
docker-compose exec app php artisan config:clear
docker-compose exec app php artisan cache:clear
docker-compose exec app php artisan view:clear
docker-compose exec app composer dump-autoload
```

### Container não inicia

```bash
# Ver logs detalhados
docker-compose logs app

# Reconstruir do zero
docker-compose down -v
docker-compose build --no-cache
docker-compose up -d
```

## 📊 Monitoramento

### Ver uso de recursos

```bash
# CPU e Memória de todos containers
docker stats

# Específico
docker stats {{PROJECT_NAME}}-app
```

### Logs estruturados

```bash
# Logs com timestamp
docker-compose logs -f --timestamps

# Últimas 100 linhas
docker-compose logs --tail=100 app
```

## 🚀 Deploy para Produção

Quando estiver pronto para produção:

```bash
cd kubernetes-vps-setup
./setup.sh
# Escolha: [2] Produção (Kubernetes)
```

Siga o [DEPLOY_VPS.md](DEPLOY_VPS.md) para deploy em VPS.

## 📚 Próximos Passos

- ✅ Configurar Xdebug no seu editor
- ✅ Testar envio de emails com Mailhog
- ✅ Executar migrations e seeders
- ✅ Rodar testes automatizados
- ✅ Desenvolver novas features
- 🚀 Deploy para produção quando pronto

---

**Dúvidas?** Consulte:
- [QUICK_START.md](QUICK_START.md) - Setup rápido
- [DEPLOY_VPS.md](DEPLOY_VPS.md) - Deploy em produção
- [FILE_STRUCTURE.md](FILE_STRUCTURE.md) - Estrutura de arquivos
