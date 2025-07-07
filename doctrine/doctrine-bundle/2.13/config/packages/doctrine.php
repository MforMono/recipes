<?php

declare(strict_types=1);

use Symfony\Component\DependencyInjection\Loader\Configurator\ContainerConfigurator;

return static function (ContainerConfigurator $containerConfigurator): void {
    $containerConfigurator->extension('doctrine', [
        'dbal' => [
            'url' => '%env(resolve:DATABASE_URL)%',
            'profiling_collect_backtrace' => '%kernel.debug%',
            'use_savepoints' => true,

            # IMPORTANT: You MUST configure your server version,
            # either here or in the DATABASE_URL env var (see .env file)
            # 'server_version' => '16',
        ],
        'orm' => [
            'auto_generate_proxy_classes' => true,
            'enable_lazy_ghost_objects' => true,
            'report_fields_where_declared' => true,
            'validate_xml_mapping' => true,
            'naming_strategy' => 'doctrine.orm.naming_strategy.underscore_number_aware',
            'identity_generation_preferences' => [
                'Doctrine\DBAL\Platforms\PostgreSQLPlatform' => 'identity',
            ],
            'auto_mapping' => true,
            'controller_resolver' => [
                'auto_mapping' => false,
            ],
            'mappings' => [
                'Example' => [
                    'is_bundle' => false,
                    'type' => 'attribute',
                    'dir' => '%kernel.project_dir%/src/ExampleContext/Infrastructure/Persistence/Doctrine/ORM/Entity',
                    'prefix' => 'App\ExampleContext\Infrastructure\Persistence\Doctrine\ORM\Entity',
                    'alias' => 'Example',
                ],
            ],
        ],
    ]);

    if ('test' === $containerConfigurator->env()) {
        $containerConfigurator->extension('doctrine', [
            'dbal' => [
                # "TEST_TOKEN" is typically set by ParaTest
                'dbname_suffix' => '_test%env(default::TEST_TOKEN)%',
            ],
        ]);
    }

    if ('prod' === $containerConfigurator->env()) {
        $containerConfigurator->extension('doctrine', [
            'orm' => [
                'auto_generate_proxy_classes' => false,
                'proxy_dir' => '%kernel.build_dir%/doctrine/orm/Proxies',
                'query_cache_driver' => [
                    'type' => 'pool',
                    'pool' => 'doctrine.system_cache_pool',
                ],
                'result_cache_driver' => [
                    'type' => 'pool',
                    'pool' => 'doctrine.result_cache_pool',
                ],
            ],
        ]);

        $containerConfigurator->extension('framework', [
            'cache' => [
                'pools' => [
                    'doctrine.result_cache_pool' => [
                        'adapter' => 'cache.app',
                    ],
                    'doctrine.system_cache_pool' => [
                        'adapter' => 'cache.system',
                    ],
                ],
            ],
        ]);
    }
};
