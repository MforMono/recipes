MforMono Recipes
================

Custom `Symfony Flex`_ recipes repository for PHP projects maintained by
`Alex Balmes`_.

This is **not** an official Symfony repository. It contains customized recipes
with project-specific conventions (code style, configuration format, etc.).

Upstream Sources
----------------

Recipes in this repository are based on and synchronized with:

* `schranz-php-recipes/symfony-recipes-php`_ — PHP-based recipes (main)
* `schranz-php-recipes/symfony-recipes-php-contrib`_ — PHP-based recipes (contrib)

These upstream repositories provide Symfony Flex recipes using PHP configuration
files instead of YAML, which aligns with the configuration approach used in
MforMono projects.

Local customizations (such as Yoda conditions, additional configuration options,
or project-specific defaults) are maintained on top of the upstream recipes and
upgraded via a 3-way merge workflow.

Usage
-----

Add this repository to your project's ``composer.json``:

.. code-block:: json

    {
        "extra": {
            "symfony": {
                "endpoint": [
                    "https://raw.githubusercontent.com/MforMono/recipes/flex/main/index.json",
                    "https://raw.githubusercontent.com/schranz-php-recipes/symfony-recipes-php/flex/main/index.json",
                    "https://raw.githubusercontent.com/schranz-php-recipes/symfony-recipes-php-contrib/flex/main/index.json",
                    "flex://defaults"
                ]
            }
        }
    }

Structure
---------

Recipes follow the standard ``vendor/package/version/`` directory structure::

    symfony/
        framework-bundle/
            7.2/
                config/
                manifest.json
    zenstruck/
        foundry/
            2.0/
                config/
                manifest.json

Each recipe contains a ``manifest.json`` and optional configuration files. See
the `Symfony Flex recipe documentation`_ for the full reference on manifest
options and configurators.

Upgrading Recipes
-----------------

An `AWF`_ workflow automates the synchronization of local recipes with upstream
versions. It uses a 3-way merge strategy (via ``git merge-file``) to apply
upstream changes while preserving local customizations.

Run the upgrade workflow:

.. code-block:: bash

    awf run .awf/workflows/upgrade-recipes.yaml

Available options:

+------------------+---------+--------------------------------------------------+
| Option           | Default | Description                                      |
+==================+=========+==================================================+
| ``dry_run``      | false   | Preview changes without applying them            |
+------------------+---------+--------------------------------------------------+
| ``skip_compare`` | false   | Skip the upstream comparison phase               |
+------------------+---------+--------------------------------------------------+
| ``keep_tmp``     | false   | Preserve temporary files for debugging           |
+------------------+---------+--------------------------------------------------+

Example with options:

.. code-block:: bash

    awf run .awf/workflows/upgrade-recipes.yaml --set dry_run=true --set keep_tmp=true

The workflow executes the following phases:

1. **Compare** — Detects differences between local and upstream recipes
2. **Download** — Shallow-clones both upstream repositories (main + contrib)
   and merges them into a single cache (main takes priority over contrib)
3. **Collect** — Discovers all local packages to process
4. **Upgrade** — For each package, runs a 3-way merge per missing upstream
   version: uses the highest common version as merge base, the upstream version
   as "theirs", and the local version as "ours"
5. **Report** — Generates a consolidated upgrade report in ``.upgrade-report/``
6. **Cleanup** — Removes the temporary upstream cache

When merge conflicts occur, they are reported with standard conflict markers
and listed in the upgrade report for manual resolution.

TODO
----

+------------------------------------+--------+-----------------------------------------------------------------------+
| Task                               | Status | Description                                                           |
+====================================+========+=======================================================================+
| Sylius\\TwigHooks                  | ✗      | Add a recipe                                                          |
+------------------------------------+--------+-----------------------------------------------------------------------+

.. _`Symfony Flex`: https://github.com/symfony/flex
.. _`Alex Balmes`: https://alex.balmes.co
.. _`schranz-php-recipes/symfony-recipes-php`: https://github.com/schranz-php-recipes/symfony-recipes-php
.. _`schranz-php-recipes/symfony-recipes-php-contrib`: https://github.com/schranz-php-recipes/symfony-recipes-php-contrib
.. _`Symfony Flex recipe documentation`: https://github.com/symfony/recipes/blob/flex/main/README.rst
.. _`AWF`: https://github.com/awf-project/cli
