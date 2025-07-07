<?php

declare(strict_types=1);

use Symfony\Component\DependencyInjection\Loader\Configurator\ContainerConfigurator;

return static function (ContainerConfigurator $containerConfigurator): void {
    $containerConfigurator->import('@SyliusBootstrapAdminUiBundle/config/app.php');

    $containerConfigurator->extension('sylius_twig_hooks', [
        'hooks' => [
            'sylius_admin.base#stylesheets' => [
                // Disabling Symfony UX stylesheets
                'symfony_ux' => [
                    'enabled' => false,
                ],
            ],
            
            'sylius_admin.base#javascripts' => [
                // Disabling Stimulus App        
                'symfony_ux' => [
                    'enabled' => false,
                ],
            ],
        ],    
    ]);
};