<?php

declare(strict_types=1);

$finder = (new TwigCsFixer\File\Finder())
    ->in('templates');

$config = (new TwigCsFixer\Config\Config)
    ->setFinder($finder);

# Extensions

# Token parsers

return $config;

