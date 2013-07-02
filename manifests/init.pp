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
# $ipaddress = $::ipaddress
#   the ipaddress to set for the auth/manager etc server
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
# the simplest usage is to add the following to the intended auth server
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
                    $test1host='test1',
                    $test2host='test2',
                    $ipaddress=$::ipaddress,
){
    if ($domain == 'UNSET') {
        fail('please set the cookie $domain')
    }

#TODO: consider changing this to allow the user to over-ride the installation mech
# eg $package = rpm, deb, tgz, cpan, git, rather than assuming based on OS
#TODO: see http://jenkner.org/blog/2013/03/27/use-osfamily-instead-of-operatingsystem/ for facter < 1.6.1
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
    #install lemonldap
    class { "lemonldap::${package}": }
    
    #add the built in vhostnames to the hosts file
    #TODO: i wonder if we can export these to client boxes too
    host { "${authhost}.${domain}":
        ip => $ipaddress,
        host_aliases => [ "${authhost}"]
    }
    host { "${managerhost}.${domain}":
        ip => $ipaddress,
        host_aliases => [ "${managerhost}"]
    }
    host { "${reloadhost}.${domain}":
        ip => $ipaddress,
        host_aliases => [ "${reloadhost}"]
    }
    host { "${test1host}.${domain}":
        ip => $ipaddress,
        host_aliases => [ "${test1host}"]
    }
    host { "${test2host}.${domain}":
        ip => $ipaddress,
        host_aliases => [ "${test2host}"]
    }
    
    #TODO: work out how to allow the use of user specified templates - these are just the basic default
    
    #sed -i 's/example\.com/ow2.org/g' /etc/lemonldap-ng/* /var/lib/lemonldap-ng/conf/lmConf-1 /var/lib/lemonldap-ng/test/index.pl
    #do the apache conf files using augeas - i'll need to find a better way to do this..
    exec { "hack-lemonldap-conf":
        command => "/bin/sed -i 's/example\.com/${domain}/g' /var/lib/lemonldap-ng/conf/lmConf-1 /var/lib/lemonldap-ng/test/index.pl",
        #refreshonly => true,
    }
        
    #now need to customise the /etc/httpd/conf.d/z-lemonldap* files to use the desired hostnames
    file { "/etc/httpd/conf.d/z-lemonldap-ng-handler.conf": ensure => "absent" }
    file { "/etc/httpd/conf.d/z-lemonldap-ng-manager.conf": ensure => "absent" }
    file { "/etc/httpd/conf.d/z-lemonldap-ng-portal.conf": ensure => "absent" }
    file { "/etc/httpd/conf.d/z-lemonldap-ng-test.conf": ensure => "absent" }

    file { "/etc/httpd/conf.d/lemonldap-ng-handler.conf": ensure => "present", source => '/etc/lemonldap-ng/handler-apache2.conf' }
    file { "/etc/httpd/conf.d/lemonldap-ng-manager.conf": ensure => "present", source => '/etc/lemonldap-ng/manager-apache2.conf' }
    file { "/etc/httpd/conf.d/lemonldap-ng-portal.conf": ensure => "present", source => '/etc/lemonldap-ng/portal-apache2.conf' }
    file { "/etc/httpd/conf.d/lemonldap-ng-test.conf": ensure => "present", source => '/etc/lemonldap-ng/test-apache2.conf' }

    #trying to use augeas
    #Package["ruby-augeas"] -> Augeas <| |>    

    #TODO: need to uncomment a #NameVirtualHost *:80 (augeas isn't great at that)
    file { "/etc/httpd/conf.d/name-virtual-host.conf": ensure => "present", content => 'NameVirtualHost *:80' }    
    
    augeas { "lemonldap-handler":
      context => "/files/etc/httpd/conf.d/lemonldap-ng-handler.conf",
      changes => [
        "set VirtualHost/*[self::directive='ServerName']/arg ${reloadhost}.${domain}",
        "set *[self::directive='ErrorDocument']/*[self::arg='http://auth.example.com/?lmError=403'] http://${authhost}.${domain}/?lmError=403",
        "set *[self::directive='ErrorDocument']/*[self::arg='http://auth.example.com/?lmError=500'] http://${authhost}.${domain}/?lmError=500",
        "set *[self::directive='ErrorDocument']/*[self::arg='http://auth.example.com/?lmError=503'] http://${authhost}.${domain}/?lmError=503",
      ],
      require => File["/etc/httpd/conf.d/lemonldap-ng-handler.conf"],
    }    
    augeas { "lemonldap-manager":
      context => "/files/etc/httpd/conf.d/lemonldap-ng-manager.conf",
      changes => [
        "set VirtualHost/*[self::directive='ServerName']/arg ${managerhost}.${domain}",
        "set *[self::directive='ErrorDocument']/*[self::arg='http://auth.example.com/?lmError=403'] http://${authhost}.${domain}/?lmError=403",
        "set *[self::directive='ErrorDocument']/*[self::arg='http://auth.example.com/?lmError=500'] http://${authhost}.${domain}/?lmError=500",
        "set *[self::directive='ErrorDocument']/*[self::arg='http://auth.example.com/?lmError=503'] http://${authhost}.${domain}/?lmError=503",
      ],
      require => File["/etc/httpd/conf.d/lemonldap-ng-manager.conf"],
    }    
    augeas { "lemonldap-portal":
      context => "/files/etc/httpd/conf.d/lemonldap-ng-portal.conf",
      changes => [
        "set VirtualHost/*[self::directive='ServerName']/arg ${authhost}.${domain}",
        "set *[self::directive='ErrorDocument']/*[self::arg='http://auth.example.com/?lmError=403'] http://${authhost}.${domain}/?lmError=403",
        "set *[self::directive='ErrorDocument']/*[self::arg='http://auth.example.com/?lmError=500'] http://${authhost}.${domain}/?lmError=500",
        "set *[self::directive='ErrorDocument']/*[self::arg='http://auth.example.com/?lmError=503'] http://${authhost}.${domain}/?lmError=503",
      ],
      require => File["/etc/httpd/conf.d/lemonldap-ng-portal.conf"],
    }    
    augeas { "lemonldap-test":
      context => "/files/etc/httpd/conf.d/lemonldap-ng-test.conf",
      changes => [
        "set VirtualHost/*[self::directive='ServerName']/arg ${test1host}.${domain}",
        "set VirtualHost/*[self::directive='ServerAlias']/arg ${test2host}.${domain}",
        "set *[self::directive='ErrorDocument']/*[self::arg='http://auth.example.com/?lmError=403'] http://${authhost}.${domain}/?lmError=403",
        "set *[self::directive='ErrorDocument']/*[self::arg='http://auth.example.com/?lmError=500'] http://${authhost}.${domain}/?lmError=500",
        "set *[self::directive='ErrorDocument']/*[self::arg='http://auth.example.com/?lmError=503'] http://${authhost}.${domain}/?lmError=503",
      ],
      require => File["/etc/httpd/conf.d/lemonldap-ng-test.conf"],
    }    
    #TODO: need to bounce apache
    
    #open the firewall for the web
    #https://forge.puppetlabs.com/arusso/iptables
    #TODO: move out to be optional
iptables::rule { 'allow web browsers':
    comment          => 'let the web shine in',
    priority         => '100',
    protocol => 'tcp',    
    destination_port => '80,443',
    action            => 'ACCEPT',
  }   
    
    #TODO: obviusly this needs to move out to be optional..
    #https://forge.puppetlabs.com/spiette/selinux
    #turn off selinux and the firewall
    class { 'selinux':
      mode => 'permissive'
    }
        
   # We want to make sure that Apache is running.
   service { "apache":
      name => $::osfamily ? { redhat => 'httpd', default => 'apache'},
      ensure => running,
      hasstatus => true,
      hasrestart => true,
      #require => Package["apache2"],
   }    
    #restart apache!
    exec { "reload-apache":
        command => "/usr/sbin/apachectl graceful",
        refreshonly => true,
    }
  }
  
    
  
}


