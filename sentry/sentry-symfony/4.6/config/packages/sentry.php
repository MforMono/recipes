<?php

declare(strict_types=1);

use Monolog\Processor\PsrLogMessageProcessor;
use Sentry\Exception\FatalErrorException;
use Sentry\State\HubInterface;
use Symfony\Component\DependencyInjection\Loader\Configurator\ContainerConfigurator;

use Symfony\Component\ErrorHandler\Error\FatalError;
use Symfony\Component\HttpKernel\Exception\GoneHttpException;
use Symfony\Component\HttpKernel\Exception\NotFoundHttpException;

return static function (ContainerConfigurator $containerConfigurator): void {
    if ('prod' === $containerConfigurator->env()) {
        $containerConfigurator->extension('sentry', [
            'dsn' => '%env(SENTRY_DSN)%',
            'register_error_listener' => false,
            'register_error_handler' => false,
            'options' => [
                'environment' => '%env(APP_RUNTIME_ENV)%',
                'ignore_exceptions' => [
                    FatalError::class,
                    FatalErrorException::class,
                    NotFoundHttpException::class,
                    GoneHttpException::class,
                ]
            ]
        ]);

        $containerConfigurator->extension('monolog', [
            'handlers' => [
                'sentry' => [
                    'type' => 'sentry',
                    'level' => Monolog\Level::Error->value,
                    'hub_id' => HubInterface::class,
                    'fill_extra_context' => true,
                ],
            ],
        ]);

        $services = $containerConfigurator->services();

        $services
            ->set(PsrLogMessageProcessor::class)
            ->tag('monolog.processor', ['handler' => 'sentry']);
    }
};
