
class lemonldap::rpm {
    include epel

    yumrepo { "lemonldap":
        name => "lemonldap",
        descr => "lemondlap",
        baseurl => "http://lemonldap-ng.org/rpm/",
        enabled => "1",
        gpgcheck=>"0",
        require=>Yumrepo["epel"]
    }

    package { "lemonldap-ng": ensure => "latest", require => Yumrepo["lemonldap"] }
    
    #TODO: maybe use an augeas puppet forge module?
    #http://projects.puppetlabs.com/projects/1/wiki/puppet_augeas
    #package { "augeas": ensure => "latest", require => Yumrepo["epel"] }
    #package { "ruby-augeas": ensure => "latest", require => Yumrepo["epel"] }
    
    #TODO: only do if x64..
    #http://lemonldap-ng.org/documentation/latest/installrpm
    #
    #If you install packages on 64bits system, create those symbolic links:
    #ln -s /usr/lib/perl5/vendor_perl/5.8.8/Lemonldap /usr/lib64/perl5/
    #ln -s /usr/lib/perl5/vendor_perl/5.8.8/auto/Lemonldap /usr/lib64/perl5/auto/
    #restart apache!
    exec { "lemonldap-x64":
        command => "/bin/ln -s /usr/lib/perl5/vendor_perl/5.8.8/Lemonldap /usr/lib64/perl5/ ; /bin/ln -s /usr/lib/perl5/vendor_perl/5.8.8/auto/Lemonldap /usr/lib64/perl5/auto/",
        refreshonly => true,
    }
    
}
