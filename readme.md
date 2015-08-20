1-free-fonts.com
===============
# these must be run as sudo
`apt-get install carton`
`apt-get install libgd-gd2-perl`
`apt-get install imagemagick --fix-missing`
`apt-get install libgd-dev`
`apt-get install memcached`
`apt-get install libcache-memcached-perl`
`cpan Cache::Memcached::libmemcached`

# as regular user
`carton install`

# installing sphinx
`add-apt-repository ppa:builds/sphinxsearch-rel22`
`apt-get update`
`apt-get install sphinxsearch`
`indexer --all`
`/etc/init.d/sphinxsearch start`
`ln -s conf/sphinx.conf /etc/sphinxsearch/sphinx.conf`

# setup upstart script
`ln -s /home/alexb/1-free-fonts.com/conf/upstart.conf /etc/init/1-free-fonts.conf`

`ln -s /home/alexb/1-free-fonts.com/conf/fastcgi_params.catalyst /etc/nginx/fastcgi_params.catalyst`