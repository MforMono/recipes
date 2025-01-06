<?php

declare(strict_types=1);

use App\Account\Common\Account\Application\Operation\Write\Edit\AccountWasEdited;
use App\Account\Common\Contract\Application\Operation\Write\Edit\ContractWasEdited;
use App\Account\Common\Organization\Application\Operation\Write\Edit\OrganizationWasEdited;
use App\Declaration\Common\Declaration\Application\Operation\Write\SendStatusToERP;
use App\Declaration\Common\Statement\Application\Operation\Write\Add\SendStatementToERP;
use App\Shared\Application\Operation\SendEmail\SendEmail;
use App\Security\Shared\Application\Operation\SendEmail\SendAuthCode;
use App\Declaration\Setup\RemoteEvent\AllowChangesOnDeclaration;
use App\Declaration\Setup\RemoteEvent\CancelDeclaration;
use App\Declaration\Setup\RemoteEvent\CompleteDeclaration;
use App\Declaration\Setup\RemoteEvent\CreateDeclarationContract;
use App\Declaration\Setup\RemoteEvent\CloseDeclarationContract;
use App\Declaration\Setup\RemoteEvent\OpenDeclarationContract;
use App\Declaration\Setup\RemoteEvent\RequestChangesOnDeclaration;
use App\Account\Setup\Application\RemoteEvent\ImportContractFromCode;
use Symfony\Component\DependencyInjection\Loader\Configurator\ContainerConfigurator;

return static function (ContainerConfigurator $containerConfigurator): void {
    $containerConfigurator->extension('framework', [
        'messenger' => [
            'default_bus' => 'command.bus',
            'failure_transport' => 'failed',
            'transports' => [
                'failed' => [
                    'dsn' => '%env(MESSENGER_TRANSPORT_DSN)%',
                    'options' => [
                        'exchange' => [
                            'name' => 'exchange_failed',
                            'type' => 'direct',
                        ],
                        'queues' => [
                            'failed' => 'failed',
                        ],
                    ],
                ],
            ],
            'routing'  => [
            ],
            'buses' => [
                'command.bus' => null,
                'query.bus' => null,
                'event.bus' => [
                    'default_middleware' => 'allow_no_handlers',
                ],
            ],
        ],
    ]);

    if ('test' === $containerConfigurator->env()) {
        $containerConfigurator->extension('framework', [
            'messenger' => [
                'transports' => [
                    # replace with your transport name here (e.g., my_transport: 'in-memory://')
                    # For more Messenger testing tools, see https://github.com/zenstruck/messenger-test
                    'async' => 'in-memory://',
                ],
            ],
        ]);
    }
};
