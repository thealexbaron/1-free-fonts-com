package Harvest::Controller::Render::List;
use Moose;
use namespace::autoclean;

use Digest::MD5 qw(md5_hex);
use POSIX;

BEGIN {extends 'Catalyst::Controller'; }

=head1 NAME

Harvest::Controller::Render::List - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut


=head2 index

=cut

sub index
    :Expires('+7d')
    :Path
    :Args(0) {
    my ( $self, $c ) = @_;

    my $request_type = $c->stash->{type} || 'author';
    my $letter = $c->stash->{letter};

    my ($names, $alpha_links_base, $letters);

    my $doc_type = $c->stash->{doc_type};

    my $processed_doc_type;

    if($c->stash->{is_user}) {
        $processed_doc_type = 'user' . $doc_type;
    }
    else {
        $processed_doc_type = $doc_type;
    }

    if ($letter && $request_type eq 'author') {
        $alpha_links_base = "/$processed_doc_type/author";
        $names = get_authors($letter, $c);
        $letters = generate_alpha($letter, $alpha_links_base, $c);
    }
    elsif ($request_type eq 'category') {
        $names = get_category($letter, $c);
        $alpha_links_base = "/$processed_doc_type/category";
        $letters = generate_alpha($letter, $alpha_links_base, $c);
    }

    if(lc $request_type eq 'category') {
        $request_type = 'topic';
    }

    $c->stash(
        letters		 => $letters,
        names 		 => $names,
        alpha_links_base => $alpha_links_base,
        type 		 => ucfirst lc $request_type,
        letter 		 => $letter,
    );

    $c->stash->{template} = 'render/list/' . $processed_doc_type . '.tt';
}

# Create alphabetical list of links.
sub generate_alpha {
	#my $requested_letter = uc shift || 'A';
    my ($requested_letter, $alpha_links_base, $c) = @_;

    $requested_letter = $requested_letter || 'A';
    $c->stash->{requested_letter} = $requested_letter;

    my @letters;

    for my $letter ('A'..'Z') {
        push @letters, $letter;
    }

    return \@letters;
}

sub get_authors {
    my ($letter, $c) = @_;

    my $schema = $c->model('DB');
    my $doc_type = $c->stash->{doc_type};
    my $doc_type_id = $c->model('DB::DocType')->get_doc_type_id($c, $doc_type);

    my ($result_source, $cond, %attrs);

    my ($author_result, $total_entries, $pgr);
    if($c->stash->{is_user}) {

        $cond = {
            'font.user'    => { '!=', undef },
            'font.type' => { '=' => $doc_type_id }
        };

        if($letter eq 'All') { }
        else {
            $cond->{'me.lastname'} = { like => "$letter%" };
        }

        %attrs = (
            result_class => 'DBIx::Class::ResultClass::HashRefInflator',
            join => [ 'font' ],
            select => [
                'me.lastname',
                'me.firstname',
                'me.id',
                'me.image',
                { count => 'font.id' },
            ],
            as => [qw(
                last_name
                first_name
                id
                image
                font_count
            )],
            group_by => [qw( me.lastname me.firstname )],
        );
        $result_source = 'User';
    }
    else {
        $cond = {
            'font.type' => { '=' => $doc_type_id }
        };

        if($letter eq 'All') { }
        else {
            $cond->{'me.last_name'} = { like => "$letter%" };
        }

        %attrs = (
                result_class => 'DBIx::Class::ResultClass::HashRefInflator',
                join => {
                    'author',
                    'font',
                },	    
                select => [
                    'me.last_name',
                    'me.first_name',
                    'me.id',
                    'me.image',
                    { count => 'font.id' },
                ],
                as => [qw(
                    last_name
                    first_name
                    id
                    image
                    font_count
                )],
                group_by => [qw/me.last_name me.first_name/],
        );
        $result_source = 'Author';
    }
    $total_entries = $schema->resultset($result_source)->search($cond, \%attrs)->count;
    $pgr = create_pager($c, $total_entries);

    $attrs{page} = $pgr->{current_page};
    $attrs{rows} = $pgr->{entries_per_page};

    $author_result = $schema->resultset($result_source)->search($cond, \%attrs);

    my $page = $pgr->{current_page};

    my $cache_doc_type;
    if($c->stash->{is_user}) {
        $cache_doc_type = 'user' . $doc_type;
    }
    else {
        $cache_doc_type = $doc_type;
    }

    my $cache_key = md5_hex("author_list::${cache_doc_type}::${letter}:::${page}");
    my $results = $c->cache->get($cache_key);

    unless($results) {
        while (my $row = $author_result->next) {

            my $url_firstname = URLize($row->{first_name});
            $url_firstname = "$url_firstname/";
            my $url_lastname = URLize($row->{last_name});

            my $author = {
                first_name 	=> 	$row->{first_name},
                last_name 	=> 	$row->{last_name},
                count			    =>	'(' . $row->{font_count} . ')',
                url_firstname		=>	$url_firstname,
                url_lastname		=>	$url_lastname,
                id                  => $row->{id},
                image                  => $row->{image},
            };

            push @$results, $author;
        }

	$c->cache->set($cache_key, $results, '5000');
    }

    if($results) {
        @$results = sort {
            $a->{last_name} cmp $b->{last_name}
            || $a->{first_name} cmp $b->{first_name}
        } @$results;
    }
        
    $c->stash->{pgr} = $pgr;

    return $results;
}

sub get_category {
    my ($letter, $c) = @_;

    my $schema = $c->model('DB');
    my ($category_result, $total_entries, $pgr);
    my $doc_type = $c->stash->{doc_type};
    my $doc_type_id = $c->model('DB::DocType')->get_doc_type_id($c, $doc_type);

    my $cond = {};

    if($letter eq 'All') { }
    else {
        $cond->{'me.name'} = { like => "$letter%" };
    }
    
    if($c->stash->{is_user}) {
        $cond->{'font.user'} = { '!=', undef };
    }

    $cond->{'font.type'} = { '=' => $doc_type_id };
           
        my %attrs = (
            result_class => 'DBIx::Class::ResultClass::HashRefInflator',
            join => {
                'category_font',
                 'font',
            },	    
            select => [
                'me.name',
                { count => 'font.id' },
            ],
            as => [qw(
                category_name
                font_count
           )],
            group_by => [qw/me.name/],
            order_by => [qw/me.name/],
        );

        $total_entries = $schema->resultset('Category')->search($cond, \%attrs)->count;
        $pgr = create_pager($c, $total_entries);

        $attrs{page} = $pgr->{current_page};
        $attrs{rows} = $pgr->{entries_per_page};

        $category_result = $schema->resultset('Category')->search($cond,\%attrs);

    my $page = $pgr->{current_page};

    my $cache_doc_type;
    if($c->stash->{is_user}) {
        $cache_doc_type = 'user' . $doc_type;
    }
    else {
        $cache_doc_type = $doc_type;
    }

    my $cache_key = md5_hex("category_list::${cache_doc_type}::${letter}::${page}");
    my $results = $c->cache->get($cache_key);

    unless($results) {
        while (my $row = $category_result->next) {

            my $url_category = URLize($row->{category_name});

            my $author = {
                last_name 	=> 	$row->{category_name},
                url_lastname =>	$url_category,
                count => $row->{font_count}
            };

            push @$results, $author;
        }

	    $c->cache->set($cache_key, $results, '5000');
    }

    $c->stash->{pgr} = $pgr;

    return $results;
}

sub URLize {
	my ($name) = @_;

    return '' unless defined $name && length $name;

    # this breaks on words with accented characters
    #$name =~ s/(\w+)/\u\L$1/g;
	$name =~ tr/ /+/;

    $name = lc($name);

	return $name;
}

sub create_pager {
    my ($c, $total_entries) = @_;

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
        
    my %pgr = (
		entries_per_page =>  $c->config->{entries_per_doc_type_page},
		total_entries    =>  $total_entries || 0,
		current_page	 =>  $c->stash->{pg} || 1,
        highest_page     =>  1,
        lowest_page      =>  1,
        offset           =>  0,
		urlbase          =>  $base_path,
		max_pages		 =>  10,
    );

	$pgr{last_page} = ceil($total_entries / $c->config->{entries_per_doc_type_page}) || 1;

	$pgr{max_pages} = ($pgr{max_pages} / 2);
	$pgr{highest_page} = $pgr{current_page} + $pgr{max_pages};

	if($pgr{highest_page} > $pgr{last_page}) {
		$pgr{highest_page} = $pgr{last_page};
	}

	$pgr{lowest_page} = $pgr{current_page} - $pgr{max_pages};
	if($pgr{lowest_page} < 1) {
		$pgr{lowest_page} = 1;
	}

	$pgr{offset} = ( $pgr{entries_per_page} * ( $pgr{current_page} - 1 ) );

    return \%pgr;
}


=head1 AUTHOR

A clever guy

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
