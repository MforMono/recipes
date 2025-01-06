<?php

declare(strict_types=1);

use Symfony\Component\DependencyInjection\Loader\Configurator\ContainerConfigurator;
use function Symfony\Component\DependencyInjection\Loader\Configurator\env;

return static function (ContainerConfigurator $containerConfigurator): void {
    $containerConfigurator->extension('framework', [
        'router' => [
            # Configure how to generate URLs in non-HTTP contexts, such as CLI commands.
            # See https://symfony.com/doc/current/routing.html#generating-urls-in-commands
            'default_uri' => env('APP_DEFAULT_URI'),
        ],
    ]);

    $containerConfigurator->extension('framework', [
        'router' => [
            'strict_requirements' => null,
        ],
    ]);
};
