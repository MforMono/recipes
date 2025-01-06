<?php

declare(strict_types=1);

use App\Shared\Infrastructure\Mailer\SymfonyMailer;
use App\Shared\UI\Twig\AdvisorExtension;
use App\Shared\UI\Twig\GoogleTagManagerExtension;
use App\Tests\Mock\Http\Response\MockResponse;
use AsyncAws\S3\S3Client;
use Sylius\Bundle\ResourceBundle\Form\Type\AbstractResourceType;
use Sylius\Resource\Symfony\ExpressionLanguage\RequestVariables;
use Symfony\Component\DependencyInjection\Loader\Configurator\ContainerConfigurator;
use Symfony\Component\Notifier\FlashMessage\BootstrapFlashMessageImportanceMapper;
use Twig\Extra\Intl\IntlExtension;
use Twig\Extra\Html\HtmlExtension;
use function Symfony\Component\DependencyInjection\Loader\Configurator\env;
use function Symfony\Component\DependencyInjection\Loader\Configurator\service;

return static function (ContainerConfigurator $containerConfigurator): void {
    $services = $containerConfigurator->services();

    # default configuration for services in *this* file
    $services->defaults()
        ->autowire()
        ->autoconfigure()
    ;

    # makes classes in src/ available to be used as services
    # this creates a service per class whose id is the fully-qualified class name
    $services
        ->load('App\\', __DIR__.'/../src/')
        ->exclude([
            __DIR__.'/../src/DependencyInjection',
            __DIR__.'/../src/Entity',
            __DIR__.'/../src/Kernel.php',
        ])
    ;

    # add more service definitions when explicit configuration is needed
    # please note that last definitions always *replace* previous ones
    $containerConfigurator->import('services/');
};
