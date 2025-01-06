<?php

declare(strict_types=1);

namespace App\Shared\Infrastructure\Mailer;

use League\Flysystem\FilesystemOperator;
use Symfony\Bridge\Twig\Mime\TemplatedEmail;
use Symfony\Component\Mailer\Exception\TransportExceptionInterface;
use Symfony\Component\Mailer\MailerInterface as SymfonyMailerInterface;
use Symfony\Component\Mime\Address;
use Symfony\Component\Mime\Part\DataPart;
use Symfony\Contracts\Translation\TranslatorInterface;

class SymfonyMailer implements MailerInterface
{
    public function __construct(
        private readonly SymfonyMailerInterface $mailer,
        private readonly TranslatorInterface $translator,
        private readonly string $senderEmail,
        private readonly string $senderName,
        private readonly FilesystemOperator $filesystemOperator,
    ) {
    }

    #[\Override]
    public function getSender(): Address
    {
        return new Address($this->senderEmail, $this->senderName);
    }

    #[\Override]
    public function send(Email $email, array|null $files = null): bool
    {
        $mail = (new TemplatedEmail())
            ->from($this->getSender())
            ->to($email->getReceiverEmail())
            ->subject($this->translator->trans(
                $email->getSubject(),
                $email->getParameters(),
                'emails',
            ))
            ->htmlTemplate($email->getHtmlTemplate())
            ->textTemplate($email->getTextTemplate())
            ->context($email->getParameters())
        ;

        if (null !== $files) {
            foreach ($files as $file) {
                $mail->addPart(
                    new DataPart(
                        $this->filesystemOperator->read($file),
                        $file,
                    )
                );
            }
        }

        try {
            $this->mailer->send($mail);
        } catch (TransportExceptionInterface) {
            return false;
        }

        return true;
    }
}
