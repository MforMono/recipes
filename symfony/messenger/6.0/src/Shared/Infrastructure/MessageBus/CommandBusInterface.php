<?php

declare(strict_types=1);

namespace App\Shared\Infrastructure\MessageBus;

use Symfony\Component\Messenger\Envelope;

interface CommandBusInterface
{
    /**
     * @param Envelope|object $command
     */
    public function __invoke($command): mixed;
}
