#!/bin/bash
set -e

echo "------------------------------------------------------------"
echo " Laravel Entrypoint — Bootstrapping Application"
echo "------------------------------------------------------------"

# ---------------------------------------------------------------------------
# 1. Wait for MySQL to be reachable
# ---------------------------------------------------------------------------
echo "[1/6] Waiting for MySQL at ${DB_HOST}:${DB_PORT}..."
until php -r "
  \$conn = @new mysqli('${DB_HOST}', '${DB_USERNAME}', '${DB_PASSWORD}', '${DB_DATABASE}', ${DB_PORT});
  if (\$conn->connect_error) { exit(1); }
  exit(0);
" 2>/dev/null; do
  echo "      MySQL not ready — retrying in 3s..."
  sleep 3
done
echo "      MySQL is up."

# ---------------------------------------------------------------------------
# 2. Wait for Redis to be reachable
# ---------------------------------------------------------------------------
echo "[2/6] Waiting for Redis at ${REDIS_HOST}:${REDIS_PORT}..."
until php -r "
  \$redis = @fsockopen('${REDIS_HOST}', ${REDIS_PORT}, \$errno, \$errstr, 3);
  if (!\$redis) { exit(1); }
  fclose(\$redis);
  exit(0);
" 2>/dev/null; do
  echo "      Redis not ready — retrying in 3s..."
  sleep 3
done
echo "      Redis is up."

# ---------------------------------------------------------------------------
# 3. Generate APP_KEY if not set
# ---------------------------------------------------------------------------
echo "[3/6] Checking APP_KEY..."
if [ -z "${APP_KEY}" ] || [ "${APP_KEY}" = "SomeRandomString" ]; then
  echo "      APP_KEY not set — generating..."
  php artisan key:generate --force
else
  echo "      APP_KEY is set."
fi

# ---------------------------------------------------------------------------
# 4. Run database migrations
# ---------------------------------------------------------------------------
echo "[4/6] Running migrations..."
php artisan migrate --force --no-interaction
echo "      Migrations done."

# ---------------------------------------------------------------------------
# 5. Storage link & permissions
# ---------------------------------------------------------------------------
echo "[5/6] Setting up storage..."
php artisan storage:link --force 2>/dev/null || true
chmod -R 775 storage bootstrap/cache
echo "      Storage ready."

# ---------------------------------------------------------------------------
# 6. Optimize (config, routes, views)
# ---------------------------------------------------------------------------
echo "[6/6] Caching config / routes / views..."
php artisan config:cache
php artisan route:cache
php artisan view:cache
echo "      Cache warmed."

echo "------------------------------------------------------------"
echo " Bootstrap complete — handing off to Supervisor"
echo "------------------------------------------------------------"

# Hand off to the CMD (supervisord) — exec replaces this shell
# so supervisord becomes PID 1
exec "$@"