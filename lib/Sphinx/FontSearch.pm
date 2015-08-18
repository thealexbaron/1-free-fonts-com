package Sphinx::FontSearch;

use Moose;
use MooseX::NonMoose;
use Sphinx::Search;
extends 'Sphinx::Search';
use Carp;
use Data::Page;
use Digest::MD5;

=head1 NAME

Sphinx::FontSearch - MooseX::NonMoose-wrapped Sphinx::Search

=head1 DESCRIPTION

Provides Moose BUILD method to allow for initialization of Sphinx::Search
object on Catalyst application startup.

=head1 SYNOPSIS

Need example here.

=head1 ATTRIBUTES

The following attributes are set from the Model::SphinxSearch "args" section of the Catalyst
application configuration file.

If an attribute setting marked "Required" is not provided by the Catalyst application
config file(s) an exception will be thrown.

=over

=item server_info

Required.

See L<Sphinx::Search SetServer method|http://search.cpan.org/perldoc?Sphinx::Search#SetServer>

=item match_mode

Required.

See L<Sphinx::Search SetMatchMode method|http://search.cpan.org/perldoc?Sphinx::Search#SetMatchMode>

=item sort_mode

Required.

See L<Sphinx::Search SetSortMode method|http://search.cpan.org/perldoc?Sphinx::Search#SetSortMode>

=item sort_mode_attr

Required.

Specifies the index attribute upon which to sort search results.

=back

=cut

has 'server_info' => (
    isa => 'HashRef',
    is => 'ro',
    required => 1,
);

has 'match_mode' => (
    isa => 'Str',
    is => 'ro',
    required => 1,
);

has 'sort_mode' => (
    isa => 'Str',
    is => 'ro',
    required => 1,
);

has 'sort_mode_attr' => (
    isa => 'Str',
    is => 'ro',
    required => 1,
);

=head1 METHODS

=cut

=head2 BUILD

Called after instantiation of the Sphinx::Search object to set configuration
attributes.

This has to be done after the Sphinx::Search object is instantiated. From comment
in Sphinx::Search code:

  # These options are supported in the constructor, but not recommended 
  # since there is no validation.  Use the Set* methods instead.

=cut

sub BUILD {
    my ($self, $args) = @_;

    if (my $s = $self->server_info) {
        $self->SetServer(@{ $s }{qw/ host port /});
    }
    if (my $mode = $self->match_mode) {
        $self->SetMatchMode(eval "${mode}()");
    }
    if (my $mode = $self->sort_mode) {
        $self->SetSortMode(eval "${mode}()", $self->sort_mode_attr);
    }
}

=head2 FOREIGNBUILDARGS($class)

Process and return Sphinx::Search's constructor arguments.

Since the Sphinx::Search code includes comments which suggest that options not be passed
to the constructor due to the lack of parameter validation, we arbitrarily pass an
empty list here. This prevents us unintentionally passing parameters that might have
side effects.

=cut

sub FOREIGNBUILDARGS {
    my $class = shift;
    return;
}

=head2 after Query

Modify the call to Sphinx::Search::Query so that we die if $sph->GetLastError
returns a TRUE value.

This will produce a 500 error in response to the request and in Catalyst Debug
mode will produce an error page including a full stacktrace.

=cut

after 'Query' => sub {
    my $self = shift;
    if (my $error = $self->GetLastError) {
        chomp $error;
        confess $error;
    }
};

=head2 build_query

Call Sphinx::Search methods to reset state:

=over

=item ResetFilters

=item ResetGroupBy

=item ResetOverrides

=back

Build and return a Sphinx search command string and call SetFilter
where appropriate.

Return undefined if there is an error.

NB: If filters are set but no search terms are supplied the search
command string may be empty, but this is still valid.

=cut

sub build_query {
    my ($self, $c) = @_;

    my $sphterms = [];

    $self->SetLimits(0, 0, 0)
         ->ResetFilters
         ->ResetGroupBy
         ->ResetOverrides;

    my $sort;

    if ($sort = $c->stash->{sort}) {
        if ($sort eq 'recent') {
            $self->SetSortMode( SPH_SORT_TIME_SEGMENTS, 'create_time' );
        }
        elsif ($sort eq 'popular') {
            $self->SetSortMode( SPH_SORT_ATTR_DESC, 'likes' );
        }
        elsif ($sort eq 'unpopular') {
            $self->SetSortMode( SPH_SORT_ATTR_ASC, 'likes' );
        }
        elsif ($sort eq 'unrated') {
            $self->SetFilter('unrated', [ 1 ]) or warn $self->GetLastError;
        } 
        else {
            my $mode = $self->sort_mode;
            $c->stash->{sort} = 'recent';
            $self->SetSortMode( eval "${mode}()", $self->sort_mode_attr);
        }
    }
    else {
        my $mode = $self->sort_mode;
        $c->stash->{sort} = 'recent';
        $self->SetSortMode( eval "${mode}()", $self->sort_mode_attr);
    }

    my $keyword;
    if ($keyword = $c->stash->{keyword}) {
        $self->sph_qry_add_term_font($sphterms, $keyword);
    }

    my $letter = $c->stash->{letter_only};
    if ($letter) {
        $self->sph_qry_add_term_letter($sphterms, $letter);
    }
    my $lname;
    if ($lname = $c->stash->{last_name}) {
        my $fname = $c->stash->{first_name};
        $self->sph_qry_add_term_author($sphterms, 0, $lname, $fname);
    }

    $self->SetFilter('paid', [ $c->stash->{paid} ]) or warn $self->GetLastError; # paid

    my $category_id = $c->stash->{category_id};

    if ($category_id) {
        $self->sph_qry_set_filter_category($sphterms, $category_id, $c);
        push @$sphterms, '';    # make sure @$sphterms is not empty if
                                # no search terms provided, i.e. search is for
                                # matches on a category with no other criteria.
    }

    return unless @$sphterms || $sort;

    # Join on '|', explicit OR is required to override Sphinx' implicit AND operator
    my $lname = $c->stash->{keyword};
    if($keyword && $lname) {
        return join ' ' => @$sphterms;
    }
    else {
        return join ' | ' => @$sphterms;
    }
}

sub sph_qry_add_term_font {
    my ($self, $sphterms, $keyword) = @_;

    $keyword = scrub_sph_term($keyword);
    push @$sphterms, '@name ' . $keyword;

    return;
}

sub sph_qry_add_term_letter {
    my ($self, $sphterms, $letter) = @_;

    push @$sphterms, '@name ^' . $letter . '*';

    return;
}

sub sph_qry_add_term_author {
    my ($self, $sphterms, $is_userfont, $lname, $fname) = @_;

    my @name_terms;

    my $type;
    if($is_userfont) {
        $type = 'user';
    }
    else {
        $type = 'author';
    }

    $lname = scrub_sph_term($lname);
    push @name_terms, '@' . $type . '_last_name ' . $lname;

    if ($fname) {
        $fname = scrub_sph_term($fname);
        push @name_terms, '@' . $type . '_first_name ' . $fname;
    }

    push @$sphterms, '(' . join(' ' => @name_terms) . ')';

    return;
}

sub sph_qry_set_filter_category {
    my ($self, $sphterms, $category_id, $c) = @_;
    $self->SetFilter('category', [ $category_id ]) or warn $self->GetLastError;

    return;
}

sub scrub_sph_term {
    my ($str) = @_;

    $str =~ tr/+-/ /;
    $str = trim($str);
    $str =~ tr/ //s;

    return $str;
}

sub trim {
    my ($str) = @_;
    s/^\s+//, s/\s+$// for $str;
    return $str;
}

=head2 pager

Return a L<Data::Page> object.

arguments:

$query_string
...

=cut

sub pager {
    my ($self, $query_string, $current_page, $sphinx_index) = @_;

    return $self->{__pager__} if $self->{__pager__};

    # call $self->SetLimits() to set limits to whatever makes sense here
    my $sph_results = $self->SetLimits(0,20)->Query($query_string, $sphinx_index);

    my $total_found = $sph_results->{total_found};

    $current_page ||= 1;

    if (!defined $current_page) {
        die "Can't create pager for non-paged rs";
    }
    elsif ($current_page <= 0) {
        die 'Invalid page number (page-numbers are 1-based)';
    }

    my $entries_per_page = 10;

    my $pager = Data::Page->new(0,);
    $pager->total_entries($total_found);
    $pager->entries_per_page($entries_per_page);
    $pager->current_page($current_page);

    return $self->{__pager__} = $pager;
}


no Moose;
__PACKAGE__->meta->make_immutable;

1;

