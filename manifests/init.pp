# == Class: lemonldap
#
# Install and configure a server to be a lemonldap authentication server
#   installs lemonldap, apache, adds hosts to the hosts file, sets up the apache vhosts
#
# === Parameters
#
# Document parameters here.
#
# $domain = 'example.com'
#   the default domain the sso cookie is applied to
#
# $authhost = 'auth'
#   the hostname of the sso authentication website
#
# $managerhost = 'manager'
#   the hostname of the sso admin management website
#
# $reloadhost = 'reload'
#   the hostname used to reload the configuration
#
# === Variables
#
# Here you should define a list of variables that this module would require.
#
# [*sample_variable*]
#   Explanation of how this variable affects the funtion of this class and if it
#   has a default. e.g. "The parameter enc_ntp_servers must be set by the
#   External Node Classifier as a comma separated list of hostnames." (Note,
#   global variables should not be used in preference to class parameters  as of
#   Puppet 2.6.)
#
# === Examples
#
#  class { lemonldap:
#    domain => 'fosiki.com'
#  }
#
# === Authors
#
# Sven Dowideit <SvenDowideit@fosiki.com>
#
# === Copyright
#
# Copyright 2013 Sven Dowideit.
#
class lemonldap (   $domain='UNSET',
                    $authhost='auth',
                    $managerhost='manager',
                    $reloadhost='reload',
){
    if ($domain == 'UNSET') {
        fail('please set the cookie $domain')
    }

#TODO: consider changing this to allow the user to over-ride the installation mech
# eg $package = rpm, deb, tgz, cpan, git, rather than assuming based on OS
  case $::osfamily {
    'redhat' : { $package = 'rpm' }
    default  : {  
                  $package = 'UNSUPPORTED'
                  notify { "${module_name}_unsupported":
                    message => "The ${module_name} module is not supported on ${osfamily}",
                    }
               }
  }
  
  if ($package != 'UNSUPPORTED') {
    class { "lemonldap::${package}": }
  }
}


