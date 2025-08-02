<?php

declare(strict_types=1);

use PhpCsFixer\Fixer\Basic\PsrAutoloadingFixer;
use PhpCsFixer\Fixer\CastNotation\NoUnsetCastFixer;
use PhpCsFixer\Fixer\ControlStructure\YodaStyleFixer;
use PhpCsFixer\Fixer\Import\FullyQualifiedStrictTypesFixer;
use PhpCsFixer\Fixer\Import\NoUnusedImportsFixer;
use PhpCsFixer\Fixer\Import\OrderedImportsFixer;
use PhpCsFixer\Fixer\LanguageConstruct\NullableTypeDeclarationFixer;
use PhpCsFixer\Fixer\NamespaceNotation\CleanNamespaceFixer;
use PhpCsFixer\Fixer\Operator\NotOperatorWithSuccessorSpaceFixer;
use PhpCsFixer\Fixer\Phpdoc\NoBlankLinesAfterPhpdocFixer;
use PhpCsFixer\Fixer\Phpdoc\PhpdocAlignFixer;
use PhpCsFixer\Fixer\Phpdoc\PhpdocLineSpanFixer;
use PhpCsFixer\Fixer\Phpdoc\PhpdocSummaryFixer;
use PhpCsFixer\Fixer\Phpdoc\PhpdocToCommentFixer;
use PhpCsFixer\Fixer\PhpUnit\PhpUnitInternalClassFixer;
use PhpCsFixer\Fixer\PhpUnit\PhpUnitMethodCasingFixer;
use PhpCsFixer\Fixer\PhpUnit\PhpUnitTestClassRequiresCoversFixer;
use PhpCsFixer\Fixer\Strict\DeclareStrictTypesFixer;
use PhpCsFixer\Fixer\Strict\StrictComparisonFixer;
use PhpCsFixer\Fixer\StringNotation\SimpleToComplexStringVariableFixer;
use Symplify\EasyCodingStandard\Config\ECSConfig;

return ECSConfig::configure()
    ->withPaths([__DIR__ . '/src', __DIR__ . '/tests'])
    ->withParallel()
    ->withCache('.ecs_cache')
    ->withEditorConfig()
    ->withRootFiles()
    ->withRules([
        DeclareStrictTypesFixer::class,
        OrderedImportsFixer::class,
        NoUnusedImportsFixer::class,
        StrictComparisonFixer::class,
        CleanNamespaceFixer::class,
        NoUnsetCastFixer::class,
        SimpleToComplexStringVariableFixer::class,
        PsrAutoloadingFixer::class,
        FullyQualifiedStrictTypesFixer::class,
    ])
    ->withPreparedSets(
        psr12: true,
        common: true,
        cleanCode: true,
    )
    ->withSkip([
        __DIR__ . '/src/Shared/Infrastructure/Persistence/Doctrine/ORMRepository.php',
        PhpUnitTestClassRequiresCoversFixer::class => ['*Test.php'],
        PhpUnitInternalClassFixer::class => ['*Test.php'],
        PhpUnitMethodCasingFixer::class => ['*Test.php'],
        NotOperatorWithSuccessorSpaceFixer::class,
        PhpdocToCommentFixer::class,
        PhpdocSummaryFixer::class,
        PhpdocLineSpanFixer::class,
        NoBlankLinesAfterPhpdocFixer::class,
    ])
    ->withConfiguredRule(
        NullableTypeDeclarationFixer::class, [
            'syntax' => 'union',
        ]
    )
    ->withConfiguredRule(PhpdocAlignFixer::class, [
        'align' => 'left',
        'tags' => [
            'method',
            'param',
            'property',
            'return',
            'throws',
            'type',
            'var',
        ],
    ])
    ->withConfiguredRule(YodaStyleFixer::class, [
        'equal' => true,
        'identical' => true,
        'less_and_greater' => true,
    ])
    ->withPhpCsFixerSets(
        symfony: true,
        php84Migration: true,
    )
;
