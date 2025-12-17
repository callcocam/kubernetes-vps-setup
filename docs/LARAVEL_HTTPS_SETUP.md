# 🔧 Configuração Pós-Deploy - Laravel

Após o primeiro deploy, configure estes itens no seu projeto Laravel para garantir que tudo funcione corretamente em produção.

---

## ✅ 1. Configurar TrustProxies (OBRIGATÓRIO)

### Por que?
O Laravel está atrás do Nginx Ingress, então precisa confiar nos headers de proxy para detectar HTTPS corretamente. Sem isso, você terá **Mixed Content Errors** (assets com HTTP em site HTTPS).

### Laravel 11+ (Recomendado)

**Editar:** `bootstrap/app.php`

```php
<?php

use Illuminate\Http\Request;
use Illuminate\Foundation\Application;
use Illuminate\Foundation\Configuration\Exceptions;
use Illuminate\Foundation\Configuration\Middleware;

return Application::configure(basePath: dirname(__DIR__))
    ->withMiddleware(function (Middleware $middleware) {
        // ✅ Confiar em todos os proxies (Kubernetes/Nginx)
        $middleware->trustProxies(at: '*');
    })
    ->withExceptions(function (Exceptions $exceptions) {
        //
    })->create();
```

### Laravel 10 e anteriores

**Editar:** `app/Http/Middleware/TrustProxies.php`

```php
<?php

namespace App\Http\Middleware;

use Illuminate\Http\Middleware\TrustProxies as Middleware;
use Illuminate\Http\Request;

class TrustProxies extends Middleware
{
    /**
     * The trusted proxies for this application.
     *
     * @var array<int, string>|string|null
     */
    protected $proxies = '*'; // ✅ Confiar em todos

    /**
     * The headers that should be used to detect proxies.
     *
     * @var int
     */
    protected $headers =
        Request::HEADER_X_FORWARDED_FOR |
        Request::HEADER_X_FORWARDED_HOST |
        Request::HEADER_X_FORWARDED_PORT |
        Request::HEADER_X_FORWARDED_PROTO |
        Request::HEADER_X_FORWARDED_AWS_ELB;
}
```

---

## ✅ 2. Forçar HTTPS em Produção (RECOMENDADO)

### AppServiceProvider

**Editar:** `app/Providers/AppServiceProvider.php`

```php
<?php

namespace App\Providers;

use Illuminate\Support\ServiceProvider;
use Illuminate\Support\Facades\URL;

class AppServiceProvider extends ServiceProvider
{
    /**
     * Bootstrap any application services.
     */
    public function boot(): void
    {
        // ✅ Forçar HTTPS em produção
        if ($this->app->environment('production')) {
            URL::forceScheme('https');
        }
        
        // Ou forçar sempre exceto em local:
        // if (!$this->app->environment('local')) {
        //     URL::forceScheme('https');
        // }
    }
}
```

---

## ✅ 3. Verificar Variáveis de Ambiente

### ConfigMap deve ter:
```yaml
APP_URL: "https://seu-dominio.com"  # ← HTTPS!
APP_ENV: "production"
APP_DEBUG: "false"
```

### Verificar no pod:
```bash
kubectl exec deployment/app -n seu-namespace -- env | grep -E "APP_URL|APP_ENV|APP_DEBUG"
```

---

## ✅ 4. Configurar Session/Cookie (OPCIONAL mas recomendado)

### Para cookies funcionarem corretamente com HTTPS

**Editar:** `config/session.php`

```php
<?php

return [
    // ...
    
    'secure' => env('SESSION_SECURE_COOKIE', true), // ✅ HTTPS only
    'same_site' => env('SESSION_SAME_SITE_COOKIE', 'lax'),
    
    // ...
];
```

**Adicionar ao ConfigMap:** `kubernetes/configmap.yaml`

```yaml
data:
  # ... outras vars ...
  SESSION_SECURE_COOKIE: "true"
  SESSION_SAME_SITE_COOKIE: "lax"
```

---

## ✅ 5. Deploy das Mudanças

```bash
# 1. Commit
git add .
git commit -m "fix: configure TrustProxies and force HTTPS in production"

# 2. Push (GitHub Actions faz deploy automaticamente)
git push origin main

# 3. Acompanhar
gh run watch

# 4. Verificar (após deploy completar)
curl -I https://seu-dominio.com
# Deve retornar: HTTP/2 200
```

---

## 🔍 Validação Final

### Checklist

```bash
# ✅ 1. APP_URL está com HTTPS?
kubectl exec deployment/app -n seu-namespace -- env | grep APP_URL
# Esperado: APP_URL=https://seu-dominio.com

# ✅ 2. Site carrega sem erros Mixed Content?
# Abrir navegador → F12 → Console
# Não deve ter erros vermelhos de Mixed Content

# ✅ 3. Assets carregam via HTTPS?
# Ver DevTools → Network
# Todos CSS/JS devem ser https://

# ✅ 4. Certificado SSL válido?
curl -I https://seu-dominio.com
# Deve retornar HTTP/2 200

# ✅ 5. Limpar caches
kubectl exec deployment/app -n seu-namespace -- php artisan config:clear
kubectl exec deployment/app -n seu-namespace -- php artisan cache:clear
kubectl exec deployment/app -n seu-namespace -- php artisan route:clear
kubectl exec deployment/app -n seu-namespace -- php artisan view:clear
```

---

## 🐛 Troubleshooting

### Ainda tem Mixed Content?

```bash
# 1. Verificar TrustProxies foi aplicado
kubectl exec deployment/app -n seu-namespace -- cat app/Http/Middleware/TrustProxies.php

# 2. Verificar AppServiceProvider
kubectl exec deployment/app -n seu-namespace -- cat app/Providers/AppServiceProvider.php

# 3. Forçar rebuild
kubectl rollout restart deployment/app -n seu-namespace

# 4. Ver logs
kubectl logs -f deployment/app -n seu-namespace
```

### Assets não carregam?

```bash
# Rebuild assets
# No seu computador (desenvolvimento):
npm run build

# Commit e push
git add public/build
git commit -m "chore: rebuild assets"
git push origin main
```

---

## 📚 Referência

- [Laravel TrustProxies](https://laravel.com/docs/11.x/requests#configuring-trusted-proxies)
- [Laravel HTTPS](https://laravel.com/docs/11.x/urls#forcing-https)
- [MDN Mixed Content](https://developer.mozilla.org/en-US/docs/Web/Security/Mixed_content)

---

## 🎯 Resumo Rápido

**Arquivos para editar:**
1. ✅ `bootstrap/app.php` ou `app/Http/Middleware/TrustProxies.php`
2. ✅ `app/Providers/AppServiceProvider.php`
3. ✅ (Opcional) `config/session.php`

**Comandos:**
```bash
git add .
git commit -m "fix: configure for HTTPS behind proxy"
git push origin main
```

**Pronto!** Seu Laravel agora funciona perfeitamente em Kubernetes com HTTPS! 🚀
