<?php

declare(strict_types=1);

use App\Declaration\Shared\Domain\Enum\StateDeclarationEnum;
use App\Declaration\Shared\Infrastructure\Persistence\Doctrine\ORM\Entity\Declaration;
use Symfony\Component\DependencyInjection\Loader\Configurator\ContainerConfigurator;

return static function (ContainerConfigurator $containerConfigurator): void {
    $containerConfigurator->extension('framework', [
        'workflows' => [

        ],
    ]);
};
