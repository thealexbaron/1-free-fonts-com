package Harvest::Controller::Render::SearchResult;
use Moose;
use namespace::autoclean;

use Digest::MD5;
use POSIX;

use JSON;

BEGIN {extends 'Catalyst::Controller'; }

=head1 NAME

Harvest::Controller::Render::SearchResult - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut


=head2 index

=cut

sub index :Path :Args(0) {
    my ( $self, $c ) = @_;

    $c->stash->{paid} = 0;

    # This must be looked at and implemented for $c
    #decode_params($c->stash, 'iso-8859-1');
    
    my $sph = $c->model('SphinxSearch');

    my $category = $c->stash->{category};
    if ($category) {
        my $category_id = get_category_id($c, $category);
        $c->stash(category_id => $category_id);
    }

    my $sph_query_string = $sph->build_query($c);

    my ($sph_results, $pgr);

    if (defined $sph_query_string) {

        $sph->Query($sph_query_string, $c->config->{sphinx_index});
        $pgr = $sph->pager($sph_query_string, $c->stash->{pg}, $c->config->{sphinx_index});
        $pgr = create_custom_pager($c, $pgr);

        my $offset = ( $pgr->entries_per_page * ( $pgr->current_page - 1 ) );

        #$pgr = create_pager($c, $sph, $sph_query_string, $c->config->{sphinx_index});

        if ($pgr) {
            $sph_results = $sph->SetLimits($offset, $pgr->entries_per_page)
                               ->Query($sph_query_string, $c->config->{sphinx_index});
        }

        if ($sph_results->{error}) {
            my $err = $sph->GetLastError;
            $c->log->warn("sphinx error: $err") if $err;
        }
    }

    # paid fonts
    $c->stash->{paid} = 1;
    $c->stash->{sph_results} = $sph_results;

    my $paid_query_string = $sph->build_query($c);
    if (defined $paid_query_string) {

	my $sph_count_results = $sph->SetLimits(0,1)->Query($paid_query_string, $c->config->{sphinx_index});
	my $total_found = $sph_count_results->{total_found};

	my $random_number = int(rand($total_found));
	
	$random_number = $random_number - 1;

	if ($random_number > 1000) {
		$random_number = 100;
	}
	elsif ($random_number <= 0) {
		$random_number = 1;
	}

	my $sph_results = $sph->SetLimits($random_number, 2)->Query($sph_query_string, $c->config->{sphinx_index});

	my $documents = get_rows_from_sql($c, $sph_results);

	$c->stash->{paid_fonts} = $documents;

        if ($sph_results->{error}) {
            my $err = $sph->GetLastError;
            $c->log->warn("sphinx error: $err") if $err;
        }
    }


    populate_stash(
        $c, 
        $sph_results, 
        $pgr
    );
}

sub create_custom_pager {
    my ($c, $pgr) = @_;

	(my $base_path = $c->req->path_info) =~ s|/pg/[0-9]+$||;

    if (my $pg = $c->stash->{pg}) {
        if ($pg =~ /^[0-9]+$/) {
            $c->stash->{pg} = 0 + $pg;  # forcing numeric context removes leading zeros
        }
        else {
            $c->stash->{pg} = 1;
        }
    }
    else {
        $c->stash->{pg} = 1;
    }

    $pgr->{urlbase} = $base_path;
        
    $pgr->{max_pages} = 10;
	$pgr->{max_pages} = ($pgr->{max_pages} / 2);
	$pgr->{highest_page} = $pgr->current_page + $pgr->{max_pages};

	if($pgr->{highest_page} > $pgr->last_page) {
		$pgr->{highest_page} = $pgr->last_page;
	}

	$pgr->{lowest_page} = $pgr->current_page - $pgr->{max_pages};
	if($pgr->{lowest_page} < 1) {
		$pgr->{lowest_page} = 1;
	}

    return $pgr;
}

sub get_category_id {
    my  ($c, $category_name) = @_;

    $category_name =~ tr/+/ /;

    my $cache_key = "category_id:${category_name}";
    $cache_key = Digest::MD5::md5_hex($cache_key);
    $c->stash->{get_category_id_cache_key} = $cache_key;
    my $category_id = $c->cache->get($cache_key);

    unless ($category_id) {
        my $model = $c->model('DB');
        my $category = $model->resultset('Category')->search(
            { name => $category_name },
        )->single;
        if ($category) {
            $category_id = $category->id;
        }
        $c->cache->set($cache_key, $category_id, 5000);
    }

    return $category_id;
}

sub populate_stash {
    my ($c, $sph_results, $pgr) = @_;

    my $vars;

    my $stash = $c->stash;

    my $author = join ' ', grep defined(), map $stash->{$_}, qw/ first_name last_name /;

    #$author =~ s/(\S+)/\u\L$1/g;

    # McLean, etc.
    #$author =~ s/\b(mc)([a-zA-Z]+)/ucfirst(lc($1)) . ucfirst(lc($2))/ie;

    if ($sph_results->{total_found}) {
        my $documents = get_rows_from_sql($c, $sph_results);

	my $count = 0;
	foreach my $document (@$documents) {
		$documents->[$count]{url} = "/fonts/download/$document->{id}/$document->{web_name}.zip";
		$count++;
	}
	my $json_results = encode_json $documents;
        my $quotes_fmtd = create_result_blocks($c, $documents);
        my $displaynum = $sph_results->{total_found} || 0;
        my $author_info = get_author_info($c);
        my $category = $c->stash->{category} || '';
        my $category_info;
        if ($category) {
            $category_info = get_category_info($c, $category);
        }
        1 while $displaynum =~ s/(^\d+)(\d{3})/$1,$2/g;
        $c->stash(
			pgr => $pgr,
            result_block => $quotes_fmtd,
	    json_results => $json_results,
			#Pagination => ($pgr->get_navi_html)[0],
            display_total_entries => $displaynum,
            total_entries => $sph_results->{total_found} || 0,
            entries_per_page => $pgr->{entries_per_page} || 0,
            keyword => $c->stash->{keyword} || undef,
            category => $c->stash->{category} || undef,
            Author => $author,
            author_detail => $c->stash->{last_name} && 1,
            author_info => $author_info,
            category_info => $category_info,
        );
    }
    elsif($c->stash->{is_search_authors}) {
        my $search_author = search_author($c);
        my %search_author = %$search_author;
        $c->stash(
            %search_author,
            no_results      => 1,
            keyword         => $c->stash->{keyword} || '',
            category        => $c->stash->{category} || '',
            author          => $author || '',
            keyword_param   => $c->stash->{keyword} || '',
        );
    }

    return;
}

sub get_category_info {
    my ($c, $category) = @_;

    my $cache_key = "category_info::${category}";
    $cache_key = Digest::MD5::md5_hex($cache_key);

    my $result = $c->cache->get($cache_key);

    unless ($result) {
        my $schema = $c->model('DB');
        $result = $schema->resultset('Category')->search(
            {
                name => $category,
            },
            {
                result_class => 'DBIx::Class::ResultClass::HashRefInflator',
            }
        )->single;

        $c->cache->set($cache_key, $result, 5000);
    }

    return $result;
}

sub search_author {
    my ( $c ) = @_;
    my $cache = $c->cache;

    # First grab author possibilities.
    my $keyword = $c->stash->{author};

    my @split_keywords;
    if ($keyword) {
        @split_keywords = split /\+/, $keyword;
    }

    my ($search_last_name,$search_first_name,$where_author,@execute_author);

    # If there is more than one keyword, search the last name as the 
    # last word of the string, and the first name as whatever is left.
    #
    # If the string only has one word, search the last name with that
    # string.


    my $query;

    if (@split_keywords > 1) {
        $search_last_name = pop @split_keywords;
        $search_first_name = join " ", @split_keywords;
        $query = {
            last_name => $search_last_name,
            first_name => $search_first_name,
        };
    }
    else {
        $search_last_name = $split_keywords[0];
        $query = { last_name => $search_last_name };
    }

    my $schema = $c->model('DB');
    my $author_result = $schema->resultset('Author')->search(
        $query,
        {
            result_class => 'DBIx::Class::ResultClass::HashRefInflator',
            select => [qw(
                first_name
                last_name
				id
            )],
        }
    );

    my (@exact_match_data, $exact_match, @partial_match,$partial_match);
    while (my $result = $author_result->next) {
        my $original_first_name = $result->{first_name};
        my $original_last_name = $result->{last_name};
        my $clean_first_name = clean($result->{first_name});
        my $clean_last_name = clean($result->{last_name});
        my $clean_keyword = clean($keyword);
        $clean_keyword =~ tr/+/ /;
        my $clean_keyword_lastname = (split ' ', $clean_keyword)[-1];

        # Exact match
        if( ($clean_keyword eq "$clean_first_name $clean_last_name") || (!$clean_first_name && $clean_keyword eq $clean_last_name) ) {
            my $url_original_first_name = $original_first_name;
            my $url_original_last_name = $original_last_name;
            $url_original_first_name =~ tr/ /+/;
            $url_original_last_name =~ tr/ /+/;
            push(@exact_match_data,
                {
                    first_name => $original_first_name,
                    last_name  => $original_last_name,
                    url_last_name => $url_original_last_name,
                    url_first_name => $url_original_first_name,
                }
            );

            $exact_match = 1;

            my $action = '/quotes/author/author_full_name_only';
            $clean_first_name =~ tr/ /+/;
            my $uri = $c->uri_for_action($action, ucfirst($clean_first_name) || '', ucfirst($clean_last_name) || '');

            $c->response->redirect($uri, 302);

            last;
        }

        # Mike suggested adding a check for first letter and last name to increase
        # relevance of suggestions.

        # Matched last names.

        # TODO: These should be sorted by
        #   A) Number of quotes per author.
        #   B) Number of ratings per author.
        #
        #   But first, we need to normalize the Author DB
        #   for maximum efficiency.

        elsif ($clean_keyword_lastname eq $clean_last_name) {
            my $url_original_first_name = $original_first_name;
            my $url_original_last_name = $original_last_name;
            $url_original_first_name =~ tr/ /+/;
            $url_original_last_name =~ tr/ /+/;
            push @partial_match,
            {
                first_name => $original_first_name,
                last_name  => $original_last_name,
                url_last_name => $url_original_last_name,
                url_first_name => $url_original_first_name,
                id => $result->{id}
            };
            $partial_match = 1;
        }
    }
    # End of author match.

    my $no_author_results;
    if(!$partial_match && !$exact_match) {
        $no_author_results = 1;
    }

    my $vars = {
        partial_match => \@partial_match,
        exact_match_data => \@exact_match_data,
        exact_match => $exact_match,
        show_authors => 1,
        no_authors => $no_author_results
    };

    return $vars;
}

sub clean {
    my $str = shift;
    tr/ //s, tr/.//d, tr/,//d for $str;
    return lc $str;
}

sub get_rows_from_sql {
	my ($c, $sph_results) = @_;
	my $cache = $c->cache;

	my $keybase = 'documentblock';

	my @docid = map $_->{doc}, @{ $sph_results->{matches} };
	my %row = map @$_, grep defined $_->[1], map { [ $_, $cache->get("${keybase}:$_") ] } @docid;
	# my %row; # disable cache 

	my @need_doc = grep !$row{$_}, @docid;

	my $schema = $c->model('DB');

	if (@need_doc) {
		my $cat_result = $schema->resultset('Font')->search(
			{ 'me.id' => { -in => [ @need_doc ] } },
			{
				result_class => 'DBIx::Class::ResultClass::HashRefInflator',
				join => [
					'nlike_dislike',
					{ category_font => 'category' }
				],
				select => [qw(
					me.id
					me.web_name
					category.name
					nlike_dislike.nlike
					nlike_dislike.ndislike
					me.image_url
					me.buy_url
					me.sku
					)],
				as => [qw(
					id
					web_name
					cat_name
					nlike
					ndislike
					image_url
					buy_url
					sku
					)],
				order_by => [qw/me.id category.name/],
			}
		);

		my $author_result;
		if ($c->stash->{is_userquote}) {

			$c->stash->{user_search_verified} = 1;

			$author_result = $schema->resultset('Font')->search(
				{
					'me.id' => { -in => [ @need_doc ] }
				},
				{
					result_class => 'DBIx::Class::ResultClass::HashRefInflator',
					join => [ 'user' ],
					select => [qw(
						me.id
						user.id
						user.firstname
						user.lastname
						user.uid
						)],
					as => [qw(
						id
						first_name
						last_name
						username
						)],
				}
			);
		}
		else {
			$author_result = $schema->resultset('Font')->search(
				{
					'me.id' => { -in => [ @need_doc ] }
				},
				{
					result_class => 'DBIx::Class::ResultClass::HashRefInflator',
					join => [ 'author' ],
					select => [qw(
						me.id
						author.id
						author.first_name
						author.last_name
						)],
					as => [qw(
						meid
						id
						first_name
						last_name
						)],
				}
			);
		}


		my $ld_result = $schema->resultset('Font')->search(
			{
				'me.id' => { -in => [ @need_doc ] }
			},
			{
				result_class => 'DBIx::Class::ResultClass::HashRefInflator',
				join => 'nlike_dislike',
				'+select' => [qw( nlike_dislike.nlike nlike_dislike.ndislike )],
				'+as' => [qw( nlike ndislike )],
			}
		);

		my %doc_cat;
		while (my $doc = $cat_result->next) {
			if (defined $doc->{cat_name}) {
				push @{ $doc_cat{$doc->{id}} }, $doc->{cat_name};
			}
		}

		my %doc_author;
		while (my $doc = $author_result->next) {
			if (defined $doc->{cat_name}) {
				push @{ $doc_cat{$doc->{id}} }, $doc->{cat_name};
			}
			my %author_info = (
				id => $doc->{id}, 
				first_name => $doc->{first_name}, 
				last_name => $doc->{last_name},
				username => $doc->{username},
			);
			$doc_author{$doc->{meid}} = \%author_info;
		}

		while (my $doc = $ld_result->next) {
			defined($doc->{nlike}) || ($doc->{nlike} = 0);
			defined($doc->{ndislike}) || ($doc->{ndislike} = 0);
			if (!defined $doc->{source} || lc $doc->{source} eq 'unknown') {
				$doc->{source} = '';
			}
			$doc->{categories} = $doc_cat{$doc->{id}} || [];
			$doc->{author} = $doc_author{$doc->{id}};

			$row{$doc->{id}} = $doc;
			my $key = join ':', $keybase, $doc->{id};
			$cache->set($key, $doc, 20000);
		}
	}

	my %doc_favorite;

	my @rows;
	for my $id (@docid) {
		push @rows, $row{$id};
	}

	return \@rows;
}

sub create_result_blocks {
    my ($c, $fonts) = @_;

    my @blocks;

    #$c->stash->{MAIN} = $fonts;

    for my $font (@$fonts) {
        my $data = {
            id => $font->{id},
            name => $font->{name},
            first_name => $font->{author_first_name},
            last_name => $font->{author_last_name},
            description => $font->{description},
	    web_name => $font->{web_name},
            source => $font->{source},
            nlike => $font->{nlike},
            ndislike => $font->{ndislike},
            author => $font->{author},
	    categories => $font->{categories},
	    favorite => $font->{favorite},
            title => $font->{title}
        };

        push @blocks, $data;
    }

    return \@blocks;
}

sub get_author_info {
    my ($c) = @_;
    my $cache = $c->cache;

    my $last_name = $c->stash->{Author_Last_Name};

    return unless $last_name;

    my $first_name = $c->stash->{Author_First_Name};

    if (!$first_name) {
        $first_name = q/'=', ['', undef]/;
    }
    else {
        $first_name = $first_name;
    }

    my $cache_key = "get_author_info:${first_name}${last_name}";
    $cache_key = Digest::MD5::md5_hex($cache_key);
    $c->stash->{get_author_info_cache_key} = $cache_key;
    my $result = $cache->get($cache_key);

    unless ($result) {
        my $schema = $c->model('DB');
        $result = $schema->resultset('Author')->search(
            {
                first_name => $first_name,
                last_name  => $last_name
            },
            {
                result_class => 'DBIx::Class::ResultClass::HashRefInflator',
            }
        )->single;

        # workaround for Template::Plugin::Date (we should
        # use Template::Plugin::TimeDate instead)
        $result->{$_} .= ' 00:00:00' for qw( birth death );

        $cache->set($cache_key, $result, 5000);
    }

    return $result;
}


=head1 AUTHOR

A clever guy

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
