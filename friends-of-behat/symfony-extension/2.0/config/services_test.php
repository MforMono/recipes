<?php

declare(strict_types=1);

use App\Tests\Mock\HttpFoundation\MockRequestStack;
use App\Tests\Behat\Client\ApiPlatformClient;
use App\Tests\Behat\Client\RequestFactory;
use Behat\Behat\Context\Context;
use FriendsOfBehat\PageObjectExtension\Page\SymfonyPageInterface;
use Symfony\Component\DependencyInjection\Loader\Configurator\ContainerConfigurator;
use Symfony\Component\HttpFoundation\Session\SessionFactoryInterface;

use function Symfony\Component\DependencyInjection\Loader\Configurator\service;

return static function (ContainerConfigurator $containerConfigurator): void {
    $containerConfigurator->parameters()
        ->set('locale', 'en_US')
    ;

    $services = $containerConfigurator->services()
        ->defaults()
        ->autowire()
        ->autoconfigure()
    ;

    $services->load('App\\Tests\\Behat\\', __DIR__.'/../tests/Behat/');
};
