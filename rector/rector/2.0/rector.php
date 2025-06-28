<?php

declare(strict_types=1);

use Rector\Set\ValueObject\LevelSetList;
use Rector\Set\ValueObject\SetList;
use Rector\Config\RectorConfig;
use Rector\Symfony\Set\SymfonySetList;

return static function (RectorConfig $rectorConfig): void {
    $rectorConfig->parallel();

    $rectorConfig->paths([
        __DIR__.'/src',
        __DIR__.'/tests',
    ]);

    $rectorConfig->sets([
        LevelSetList::UP_TO_PHP_84,

        SetList::BEHAT_ANNOTATIONS_TO_ATTRIBUTES,
        SetList::CODE_QUALITY,
        
        SymfonySetList::SYMFONY_73,
    ]);
};
