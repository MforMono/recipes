<?php

declare(strict_types=1);

use Symfony\Component\DependencyInjection\Loader\Configurator\ContainerConfigurator;

return static function (ContainerConfigurator $containerConfigurator): void {
    if ('dev' === $containerConfigurator->env() || 'test' === $containerConfigurator->env()) {
        # See full configuration: https://symfony.com/bundles/ZenstruckFoundryBundle/current/index.html#full-default-bundle-configuration
        $containerConfigurator->extension('zenstruck_foundry', [
            'auto_refresh_proxies' => true,
        ]);
    }
};
