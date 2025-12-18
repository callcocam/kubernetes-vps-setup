# 🔴 Laravel Reverb - WebSocket Server

## 📋 O Que É?

Laravel Reverb é o servidor WebSocket oficial do Laravel para broadcasting em tempo real. Ele substitui soluções como Pusher, Ably ou Socket.io com uma implementação nativa e gratuita.

**Casos de uso:**
- 💬 Chat em tempo real
- 🔔 Notificações instantâneas
- 📊 Dashboards com dados ao vivo
- 🎮 Jogos multiplayer
- 👥 Presença de usuários online
- 📝 Edição colaborativa

---

## ✅ Configuração Automática

O `setup.sh` agora **configura o Reverb automaticamente** em todos os ambientes:

### Durante a Execução do `setup.sh`

```bash
./setup.sh
```

Você verá:

```
═══════════════════════════════════════════════════════════════
  LARAVEL REVERB (WEBSOCKETS)
═══════════════════════════════════════════════════════════════

Laravel Reverb é o servidor WebSocket oficial do Laravel
para broadcasting em tempo real (notificações, chat, etc)

💡 Deixe vazio para gerar credenciais automáticas

🔑 Reverb APP_ID (deixe vazio para gerar): 
✅ APP_ID gerado: 1a2b3c4d5e6f7g8h

🔐 Reverb APP_KEY (deixe vazio para gerar): 
✅ APP_KEY gerado: xY9mK2pL8qR...

🔐 Reverb APP_SECRET (deixe vazio para gerar): 
✅ APP_SECRET gerado: nT4hF7jK1wP...
```

**Recomendação:** Pressione ENTER 3 vezes para gerar credenciais seguras automaticamente.

---

## 🏗️ Arquitetura

### Produção (Kubernetes)

```
┌─────────────────────────────────────────────────┐
│  Pod da Aplicação                               │
│                                                 │
│  ┌──────────────┐      ┌──────────────┐        │
│  │  Container   │      │  Container   │        │
│  │   Laravel    │      │   Reverb     │        │
│  │   (porta 80) │      │  (porta 8080)│        │
│  └──────────────┘      └──────────────┘        │
└─────────────────────────────────────────────────┘
                 │                    │
                 ▼                    ▼
         ┌──────────────────────────────┐
         │       Service                │
         │  porta 80 → app:80           │
         │  porta 8080 → reverb:8080    │
         └──────────────────────────────┘
                       │
                       ▼
              ┌─────────────────┐
              │     Ingress     │
              │  /     → :80    │
              │  /app  → :8080  │
              └─────────────────┘
                       │
                       ▼
               https://app.com
```

**Características:**
- Reverb roda como **sidecar container** no mesmo pod do Laravel
- Compartilha mesmo namespace e variáveis de ambiente
- Acesso via `https://seudominio.com/app` (WebSocket)
- SSL/TLS automático via cert-manager

### Dev Local (Docker Compose)

```
┌─────────────┐    ┌─────────────┐    ┌─────────────┐
│  Container  │    │  Container  │    │  Container  │
│   Laravel   │    │   Reverb    │    │  PostgreSQL │
│   :8000     │    │   :8080     │    │   :5432     │
└─────────────┘    └─────────────┘    └─────────────┘
      │                  │                    │
      └──────────────────┴────────────────────┘
                         │
                  Docker Network
```

**Características:**
- Reverb roda como **container separado**
- Acesso via `http://localhost:8080`
- Sem SSL em desenvolvimento

---

## 🔧 Configuração no Laravel

### 1. Instalar Dependências

No seu projeto Laravel:

```bash
composer require laravel/reverb
php artisan reverb:install
npm install --save-dev laravel-echo pusher-js
```

### 2. Configurar `config/broadcasting.php`

O Reverb já vem configurado por padrão, mas verifique:

```php
'reverb' => [
    'driver' => 'reverb',
    'key' => env('REVERB_APP_KEY'),
    'secret' => env('REVERB_APP_SECRET'),
    'app_id' => env('REVERB_APP_ID'),
    'options' => [
        'host' => env('REVERB_HOST', '0.0.0.0'),
        'port' => env('REVERB_PORT', 8080),
        'scheme' => env('REVERB_SCHEME', 'http'),
        'useTLS' => env('REVERB_SCHEME', 'http') === 'https',
    ],
],
```

### 3. Configurar Frontend (`resources/js/bootstrap.js`)

```javascript
import Echo from 'laravel-echo';
import Pusher from 'pusher-js';

window.Pusher = Pusher;

window.Echo = new Echo({
    broadcaster: 'reverb',
    key: import.meta.env.VITE_REVERB_APP_KEY,
    wsHost: import.meta.env.VITE_REVERB_HOST,
    wsPort: import.meta.env.VITE_REVERB_PORT ?? 80,
    wssPort: import.meta.env.VITE_REVERB_PORT ?? 443,
    forceTLS: (import.meta.env.VITE_REVERB_SCHEME ?? 'https') === 'https',
    enabledTransports: ['ws', 'wss'],
});
```

### 4. Variáveis de Ambiente

Já configurado automaticamente pelo `setup.sh`:

**Produção (Kubernetes):**
```env
BROADCAST_DRIVER=reverb
REVERB_APP_ID=1a2b3c4d5e6f7g8h
REVERB_APP_KEY=xY9mK2pL8qR...
REVERB_APP_SECRET=nT4hF7jK1wP...
REVERB_HOST=localhost
REVERB_PORT=8080
REVERB_SCHEME=http

VITE_REVERB_APP_KEY=xY9mK2pL8qR...
VITE_REVERB_HOST=app.exemplo.com
VITE_REVERB_PORT=443
VITE_REVERB_SCHEME=https
```

**Dev Local:**
```env
BROADCAST_DRIVER=reverb
REVERB_APP_ID=1a2b3c4d5e6f7g8h
REVERB_APP_KEY=xY9mK2pL8qR...
REVERB_APP_SECRET=nT4hF7jK1wP...
REVERB_HOST=reverb
REVERB_PORT=8080
REVERB_SCHEME=http

VITE_REVERB_APP_KEY=xY9mK2pL8qR...
VITE_REVERB_HOST=localhost
VITE_REVERB_PORT=8080
VITE_REVERB_SCHEME=http
```

---

## 📡 Usando o Reverb

### Exemplo 1: Broadcast de Evento

**1. Criar Evento:**

```bash
php artisan make:event MessageSent
```

**2. Implementar Evento (`app/Events/MessageSent.php`):**

```php
<?php

namespace App\Events;

use Illuminate\Broadcasting\Channel;
use Illuminate\Broadcasting\InteractsWithSockets;
use Illuminate\Contracts\Broadcasting\ShouldBroadcast;
use Illuminate\Foundation\Events\Dispatchable;
use Illuminate\Queue\SerializesModels;

class MessageSent implements ShouldBroadcast
{
    use Dispatchable, InteractsWithSockets, SerializesModels;

    public function __construct(
        public string $message,
        public string $username
    ) {}

    public function broadcastOn(): Channel
    {
        return new Channel('chat');
    }
}
```

**3. Disparar Evento:**

```php
use App\Events\MessageSent;

broadcast(new MessageSent('Hello World!', 'João'));
```

**4. Escutar no Frontend:**

```javascript
Echo.channel('chat')
    .listen('MessageSent', (e) => {
        console.log(`${e.username} disse: ${e.message}`);
    });
```

### Exemplo 2: Canal Privado (Autenticado)

**1. Definir Rota de Autorização (`routes/channels.php`):**

```php
Broadcast::channel('user.{id}', function ($user, $id) {
    return (int) $user->id === (int) $id;
});
```

**2. Criar Evento:**

```php
class NotificationSent implements ShouldBroadcast
{
    public function __construct(
        public string $title,
        public int $userId
    ) {}

    public function broadcastOn(): Channel
    {
        return new PrivateChannel('user.' . $this->userId);
    }
}
```

**3. Escutar (Frontend autenticado):**

```javascript
Echo.private(`user.${userId}`)
    .listen('NotificationSent', (e) => {
        alert(`Nova notificação: ${e.title}`);
    });
```

### Exemplo 3: Presença (Quem está online)

**1. Criar Canal de Presença:**

```php
Broadcast::channel('room.{roomId}', function ($user, $roomId) {
    if ($user->canJoinRoom($roomId)) {
        return ['id' => $user->id, 'name' => $user->name];
    }
});
```

**2. Frontend:**

```javascript
Echo.join(`room.1`)
    .here((users) => {
        console.log('Usuários online:', users);
    })
    .joining((user) => {
        console.log(user.name + ' entrou');
    })
    .leaving((user) => {
        console.log(user.name + ' saiu');
    });
```

---

## 🔍 Monitoramento e Debug

### Ver Logs do Reverb (Produção)

```bash
# Logs do container Reverb
kubectl logs -f deployment/app -n seu-namespace -c reverb

# Logs de todos os containers do pod
kubectl logs -f deployment/app -n seu-namespace --all-containers
```

### Ver Logs (Dev Local)

```bash
# Logs do Reverb
docker-compose logs -f reverb

# Logs em tempo real
docker-compose logs -f reverb | grep -i "connection"
```

### Testar Conexão

**Frontend (Console do Browser):**

```javascript
// Verificar se Echo está configurado
console.log(window.Echo);

// Testar conexão
Echo.channel('test')
    .listen('.test-event', (e) => {
        console.log('Evento recebido:', e);
    });
```

**Backend (Tinker):**

```bash
php artisan tinker
```

```php
// Disparar evento de teste
broadcast(new \App\Events\MessageSent('Test', 'System'));
```

---

## 🐛 Troubleshooting

### Erro: "WebSocket connection failed"

**Sintoma:**
```
WebSocket connection to 'wss://app.com/app' failed
```

**Soluções:**

1. **Verificar se Reverb está rodando:**

```bash
# Produção
kubectl get pods -n seu-namespace
kubectl logs deployment/app -n seu-namespace -c reverb

# Dev Local
docker-compose ps reverb
docker-compose logs reverb
```

2. **Verificar Ingress (Produção):**

```bash
kubectl describe ingress app-ingress -n seu-namespace
```

Deve ter a rota `/app` apontando para porta 8080.

3. **Verificar variáveis de ambiente:**

```bash
# Produção
kubectl exec -it deployment/app -n seu-namespace -- env | grep REVERB

# Dev Local
docker-compose exec app env | grep REVERB
```

### Erro: "401 Unauthorized" em Canal Privado

**Causa:** Rota `/broadcasting/auth` não acessível ou CSRF token inválido.

**Solução:**

1. Verificar se está autenticado
2. Verificar CSRF token no frontend
3. Adicionar rota no `routes/web.php`:

```php
Broadcast::routes(['middleware' => ['web', 'auth']]);
```

### Reverb reinicia constantemente (Produção)

```bash
kubectl get pods -n seu-namespace
# NAME                   READY   RESTARTS
# app-7d8f9c8b-abc12     1/2     5
```

**Diagnóstico:**

```bash
kubectl logs deployment/app -n seu-namespace -c reverb
```

**Causas comuns:**
- Variáveis de ambiente faltando
- Porta 8080 já em uso
- Recursos insuficientes

**Solução:** Verificar logs e aumentar recursos se necessário.

---

## 📊 Recursos Alocados

### Produção (Kubernetes)

O container Reverb usa:

```yaml
resources:
  requests:
    memory: "128Mi"
    cpu: "100m"
  limits:
    memory: "256Mi"
    cpu: "250m"
```

**Por perfil de recursos:**

| Perfil | App (Requests) | Reverb (Requests) | Total CPU | Total RAM |
|--------|---------------|-------------------|-----------|-----------|
| **Produção** | 500m | 100m | 600m × 2 = 1.2 vCPU | 1.28 GB |
| **Dev** | 250m | 100m | 350m × 1 = 0.35 vCPU | 384 MB |
| **Test** | 250m | 100m | 350m × 1 = 0.35 vCPU | 384 MB |

### Dev Local

Container separado com compartilhamento de código via volume.

---

## 🎯 Boas Práticas

### 1. Usar Queues para Broadcasting

Em produção, sempre envie broadcasts via queue:

```php
class MessageSent implements ShouldBroadcast, ShouldQueue
{
    use Dispatchable, InteractsWithSockets, SerializesModels;
    
    public $queue = 'broadcasts';
    // ...
}
```

### 2. Limitar Rate de Eventos

```php
public function broadcastOn(): array
{
    return [
        new Channel('chat'),
    ];
}

public function broadcastWith(): array
{
    // Enviar apenas dados necessários
    return [
        'message' => $this->message,
        'time' => now()->toIso8601String(),
    ];
}
```

### 3. Autenticar Canais Sensíveis

Sempre use `PrivateChannel` para dados privados:

```php
return new PrivateChannel('user.' . $this->userId);
```

### 4. Monitorar Conexões

Configure alertas para:
- Número de conexões simultâneas
- Taxa de erro de conexão
- Uso de memória do Reverb

---

## 🔄 Alternativas ao Reverb

Se você precisar de recursos mais avançados:

| Solução | Quando Usar |
|---------|-------------|
| **Pusher** | Escala automática, analytics integrado |
| **Ably** | Presença global, múltiplos protocolos |
| **Socket.io** | Controle total, customização máxima |
| **Soketi** | Open-source, compatível com Pusher |

Para trocar, basta mudar `BROADCAST_DRIVER` no `.env` e ajustar configurações.

---

## 📚 Recursos Adicionais

- [Documentação Oficial do Reverb](https://laravel.com/docs/reverb)
- [Broadcasting no Laravel](https://laravel.com/docs/broadcasting)
- [Laravel Echo](https://github.com/laravel/echo)
- [Exemplo de Chat com Reverb](https://github.com/laravel/reverb-example)

---

## ✅ Checklist de Deploy

- [ ] Reverb instalado: `composer require laravel/reverb`
- [ ] Configuração de broadcasting verificada
- [ ] Frontend configurado com Laravel Echo
- [ ] Variáveis `REVERB_*` configuradas
- [ ] Testado em desenvolvimento local
- [ ] Deploy em produção realizado
- [ ] WebSocket conectando com sucesso
- [ ] Eventos sendo recebidos no frontend
- [ ] Logs do Reverb sem erros
- [ ] Monitoramento configurado

**Pronto!** O Reverb agora está configurado e rodando em todos os ambientes! 🎉
