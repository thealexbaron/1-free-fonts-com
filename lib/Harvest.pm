package Harvest;
use Moose;
use namespace::autoclean;

use Catalyst::Runtime 5.80;

# Set flags and add plugins for the application.
#
# Note that ORDERING IS IMPORTANT here as plugins are initialized in order,
# therefore you almost certainly want to keep ConfigLoader at the head of the
# list if you're using it.
#
#         -Debug: activates the debug mode for very useful log messages
#   ConfigLoader: will load the configuration from a Config::General file in the
#                 application's home directory
# Static::Simple: will serve static files from the application's root
#                 directory

use Catalyst qw/

    ConfigLoader
    Static::Simple
    Authentication
    Session
    Session::Store::FastMmap
    Session::State::Cookie
    Cache
    Unicode::Encoding
    Snippets
    Captcha
/;

extends 'Catalyst';

our $VERSION = '0.01';

# Configure the application.
#
# Note that settings in harvest.conf (or other external
# configuration file that you set up manually) take precedence
# over this when using ConfigLoader. Thus configuration
# details given here can function as a default configuration,
# with an external configuration file acting as an override for
# local deployment.

__PACKAGE__->config(
    name => 'Harvest',
    encoding => 'UTF-8',
    # Disable deprecated behavior needed by old applications
    disable_component_resolution_regex_fallback => 1,
    default_view => 'TT',
    'View::TT' => {
        INCLUDE_PATH => [
            __PACKAGE__->path_to('include'),
            __PACKAGE__->path_to('root'),
            __PACKAGE__->path_to('root', 'render'),
        ],
    },
    'View::JSON' => {
        allow_callback => 1,
        callback_param => 'callback',
    },
    Snippets => {
        use_session_id => 1,
    },
    authentication => {
        default_realm => 'users',
        realms => {
            #auto_update_user => 1,
            users => {
                credential => {
                    class => 'Password',
                    password_field => 'password',
                    password_type => 'hashed',
                    password_hash_type => 'SHA-1',
                },
                store => {
                    class => 'DBIx::Class',
                    user_model => 'DB::User',
                    use_userdata_from_session => 1,
                    role_relation => 'roles',
                    role_field => 'name',
                },
            },
        },
    },
);

__PACKAGE__->config->{ 'Plugin::Captcha' } = {
    session_name => 'captcha_string',
    new => {
      width => 100,
      height => 50,
      lines => 1,
      gd_font => 'Large',
    },
    create => [qw/normal rect/],
    particle => [60],
    out => {force => 'jpeg'}
};

__PACKAGE__->config(
        'View::Email' => {
            default => {
                content_type => 'text/plain',
                charset => 'utf-8',
		view => 'TT'
            },
            sender => {
                mailer => 'SMTP',
                mailer_args => {

            }
          }
        }
    );

# Start the application
__PACKAGE__->setup();


=head1 NAME

Harvest - Catalyst based application

=head1 SYNOPSIS

    script/harvest_server.pl

=head1 DESCRIPTION

[enter your description here]

=head1 SEE ALSO

L<Harvest::Controller::Root>, L<Catalyst>

=head1 AUTHOR

Catalyst developer

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
