
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
}
