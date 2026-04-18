#!/bin/bash

echo "Clearing caches"
php artisan migrate
php artisan optimize:clear
php artisan optimize
php artisan package:discover --ansi

