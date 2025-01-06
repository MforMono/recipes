<?php

declare(strict_types=1);

use Behat\Config\Config;
use Behat\Config\Extension;
use Behat\Config\Filter\TagFilter;
use Behat\Config\Formatter\PrettyFormatter;
use Behat\Config\Profile;
use Behat\MinkExtension\ServiceContainer\MinkExtension;
use Behat\Testwork\Output\Printer\Factory\OutputFactory;
use FriendsOfBehat\SymfonyExtension\ServiceContainer\SymfonyExtension;

$profile = (new Profile('default'))
    ->withFormatter(
        (new PrettyFormatter(paths: false))
            ->withOutputVerbosity(OutputFactory::VERBOSITY_VERBOSE)
    )
    ->withFilter(new TagFilter('~@todo'))

    # Extensions
    ->withExtension(new Extension(SymfonyExtension::class, [
        'bootstrap' => 'tests/bootstrap.php',
    ]))
;

return (new Config())
    ->import('config/behat/suites.php')
    ->withProfile($profile)
;
