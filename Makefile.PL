use inc::Module::Install;
name                 'Kappa';
all_from             'lib/Kappa.pm';
readme_from          'lib/Kappa.pm';
readme_markdown_from 'lib/Kappa.pm';
readme_pod_from      'lib/Kappa.pm';
githubmeta;

requires 'SQL::Executor' => '0.14';
requires 'Class::Load';
requires 'Scope::Guard';
recommends 'Class::Load::XS';
requires 'Data::UUID';
requires 'Data::Section::Simple';

tests 't/*.t';
author_tests 'xt';

test_requires 'Test::More';
auto_set_repository;

WriteAll;
