<?php

declare(strict_types=1);

use Symfony\Component\DependencyInjection\Loader\Configurator\ContainerConfigurator;

return static function (ContainerConfigurator $containerConfigurator): void {
    $containerConfigurator->extension('webpack_encore', [
        # The path where Encore is building the assets - i.e. Encore.setOutputPath()
        'output_path' => '%kernel.project_dir%/public/build',
        # If multiple builds are defined (as shown below), you can disable the default build:
        # output_path: false

        # Set attributes that will be rendered on all script and link tags
        'script_attributes' => [
            'defer' => true,
            'preload' => true,
            # Uncomment (also under link_attributes) if using Turbo Drive
            # https://turbo.hotwired.dev/handbook/drive#reloading-when-assets-change
            # 'data-turbo-track' => 'reload',
        ],

        # Set attributes that will be rendered on all script and link tags
        'link_attributes' => [
            # Uncomment if using Turbo Drive
            # 'data-turbo-track' => 'reload',
        ],

        # If using Encore.enableIntegrityHashes() and need the crossorigin attribute (default: false, or use 'anonymous' or 'use-credentials')
        # 'crossorigin' => 'anonymous'

        # Preload all rendered script and link tags automatically via the HTTP/2 Link header
        'preload' => true,

        # Throw an exception if the entrypoints.json file is missing or an entry is missing from the data
        'strict_mode' => true,

        # If you have multiple builds:
        #'builds' => [
        #    'frontend' => '%kernel.project_dir%/public/assets/frontend',
        #
        # pass the build name as the 3rd argument to the Twig functions
        # {{ encore_entry_script_tags('entry1', null, 'frontend') }}
        #],
    ]);

    $containerConfigurator->extension('framework', [
        'assets' => [
            'json_manifest_path' => '%kernel.project_dir%/public/build/manifest.json',
        ],
    ]);

    #if ('prod' === $containerConfigurator->env()) {
    #    $containerConfigurator->extension('webpack_encore', [
    #        'cache' => true,
    #    ]);
    #}

    if ('test' === $containerConfigurator->env()) {
        $containerConfigurator->extension('webpack_encore', [
            'strict_mode' => false,
        ]);
    }
};
