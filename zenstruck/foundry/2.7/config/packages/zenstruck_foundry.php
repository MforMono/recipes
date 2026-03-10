<?php

declare(strict_types=1);

use Symfony\Component\DependencyInjection\Loader\Configurator\ContainerConfigurator;

return static function (ContainerConfigurator $containerConfigurator): void {
    if ('dev' === $containerConfigurator->env() || 'test' === $containerConfigurator->env()) {
        # See full configuration: https://symfony.com/bundles/ZenstruckFoundryBundle/current/index.html#full-default-bundle-configuration
        $containerConfigurator->extension('zenstruck_foundry', [
            # Flush only once per call of `PersistentObjectFactory::create()`
            'persistence' => [
                'flush_once' => true,
            ],

            # If you use the `make:factory --test` command, you may need to uncomment the following.
            # See https://symfony.com/bundles/ZenstruckFoundryBundle/current/index.html#generate
            #$services = $containerConfigurator->services();
            #
            #$services
            #    ->load('App\\Tests\\Factory\\', __DIR__.'/../src/tests/Factory/')
            #    ->autowire()
            #    ->autoconfigure()
            #;
        ]);
    }
};
