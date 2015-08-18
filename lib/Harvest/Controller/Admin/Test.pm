package Harvest::Controller::Admin::Test;
use Moose;
use namespace::autoclean;

BEGIN {extends 'Catalyst::Controller'; }

=head1 NAME

Harvest::Controller::Admin::Test - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut

=head2 index

=cut

sub index :Path :Args(0) {
    my ( $self, $c ) = @_;

}

=head2 showpaths

Dump chained action paths.

=cut

sub showpaths :Local :Args() {
    my ( $self, $c, $match ) = @_;

    my $remote_addr = $c->req->address;
    my $addrs = $c->config->{always_allow};
    $addrs = ref $addrs ? $addrs : [ $addrs ];
    my $allowed;
    for my $addr (@$addrs) {
        if ($addr eq $remote_addr) {
            $allowed = 1;
            last;
        }
    }
    $allowed or $c->detach('default');

    if ($match) {
        if ($match =~ tr.a-zA-Z0-9_/..c) {
            $match = '';
        }
    }

    my $paths = Util::Chains::mylist( $c->dispatcher->dispatch_type('Chained') );

    my @show;

    if (defined $match && length $match) {
        @show = grep { CORE::index($_->[0], $match) > -1 } @$paths;
    }
    else {
        @show = @$paths;
    }
    $paths = [ map {+ { path => $_->[0], endpoint => $_->[1] } } @show ];

    $c->stash(
        search_term => $match,
        paths => $paths,
    );

    #$c->res->content_type('text/plain');
    #$c->res->body($body);
}

=head2 test_unicode_template

Verify that a unicode (utf-8) template produces valid utf-8.

Includes an image for verification.

The text and image include the Russian for "Hello world."

=cut

sub test_unicode_template :Local {
    my ( $self, $c ) = @_;
    my $enc = $c->encoding->name;
    $c->stash(enc => $enc);
}

=head2 test_unicode_db_roundtrip

Present a form with a text input. On submit, insert the input
into the database, fetch the input fromm the database again,
then show a page with the text fetched from the database.

=cut

sub test_unicode_db_roundtrip :Local {
    my ( $self, $c ) = @_;
}

=head2 show_unicode_db_roundtrip_result

Show the result of the db INSERT in utf-8.

=cut

sub show_unicode_db_roundtrip_result :Local {
    my ( $self, $c ) = @_;

    my $text = $c->req->body_parameters->{mytext};
    my $dbg = '';
    $dbg .= sprintf "%02x ", ord $_ for split //, $text;
$c->log->debug("dump of input: $dbg");
$c->log->debug("\e[0m\e[32;1mcalling create on next line\e[0m");
    if ($text) {
        $c->model('DB::CatTest')->create({ testtext => $text });
    }

    my $rs = $c->model('DB::CatTest')->search;

    # get session connection variables for troubleshooting:
    my $dbh = $c->model('DB::CatTest')->result_source->storage->dbh;
    my $sth = $dbh->prepare("SHOW VARIABLES LIKE '%character_set%'");
    $sth->execute;
    my $vars;
    while (my @row = $sth->fetchrow_array) {
        push @$vars, { name => $row[0], value => $row[1] };
    }
    $c->stash(
        submitted => $text,
        strings => $rs,
        vars => $vars,
    );

$c->log->debug("wrapping up show_unicode_db_roundtrip_result");
    $c->detach;
}

=head2 delete_from_cat_test

Delete rows from cat_test table.

=cut

sub delete_from_cat_test :Local {
    my ( $self, $c ) = @_;

    $c->model('DB::CatTest')->search->delete;
    # This shouldn't be required, but if we don't do it Cat tries to render a template
    # named for this action.
    $c->stash(template => 'admin/test/show_unicode_db_roundtrip_result.tt');
    $c->detach('show_unicode_db_roundtrip_result');
}

sub extra_encode_test :Local {
    my ( $self, $c ) = @_;

    my $font_category = 'Måns Grebäck';

    my $model = $c->model('DB::Category');
    my $font_category_id = $model->get_or_create_category_id_by_category_name($c, $font_category);

    warn $font_category_id;

}

=head1 AUTHOR

A clever guy

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;

