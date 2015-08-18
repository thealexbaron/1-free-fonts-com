package Harvest::Model::SphinxSearch;

use base 'Catalyst::Model::Factory::PerRequest';

__PACKAGE__->config(class => 'Sphinx::FontSearch');

1;
