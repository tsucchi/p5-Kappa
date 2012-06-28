use inc::Module::Install;
name                 'Kappa';
all_from             'lib/Kappa.pm';
readme_from          'lib/Kappa.pm';
readme_markdown_from 'lib/Kappa.pm';
readme_pod_from      'lib/Kappa.pm';
githubmeta;

requires 'SQL::Executor' => '0.11';
requires 'Class::Load';
requires 'Scope::Guard';
recommends 'Class::Load::XS';

tests 't/*.t';
author_tests 'xt';

test_requires 'Test::More';
auto_set_repository;

WriteAll;
