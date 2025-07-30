<?php

declare(strict_types=1);

use Rector\Set\ValueObject\SetList;
use Rector\Config\RectorConfig;

return RectorConfig::configure()
    ->withParallel()
    ->withPaths([
        __DIR__ . '/src',
        __DIR__ . '/tests'
    ])
    ->withPhpSets()
    ->withComposerBased(
        twig: true,
        doctrine: true,
        symfony: true,
        phpunit: true
    )
    ->withAttributesSets()
    ->withPreparedSets()
    ->withSets([
        SetList::BEHAT_ANNOTATIONS_TO_ATTRIBUTES,
    ]);

