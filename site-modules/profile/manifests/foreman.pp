# https://github.com/theforeman/foreman-installer/blob/develop/config/katello.yaml
# order:
#   - certs
#   - foreman
#   - katello
#   - foreman_proxy
#   - foreman_proxy::plugin::pulp
#   - foreman_proxy_content
#   - puppet

class profile::foreman(
  Hash $settings = {},
  Hash $dhcp_classes = {},
  String $initial_admin_password = 'changeme',
  String $db_password = 'changeme',
) {

  selinux::port { 'tomcat_candlepin_port':
    seltype => 'http_port_t',
    protocol => 'tcp',
    port => 23443,
    before => Service['tomcat'],
  }

  class { '::foreman::repo':
    repo => '3.6',
    before => [
      Class['certs'],
      Class['foreman'],
      Class['foreman::cli'],
      Class['foreman_proxy'],
      Class['katello'],
    ],
  }

  class { '::puppet':
    server                => true,
    server_external_nodes => '',
  }

  class { '::foreman':
    version => 'latest',
    plugin_version => 'latest',
    initial_admin_password => $initial_admin_password,
    db_password => $db_password,
  }

  include ::foreman::cli

  foreman::cli::plugin { 'foreman':
    require => Class['foreman::repo'],
    version => 'latest',
  }
  foreman::cli::plugin { 'foreman_templates':
    require => Class['foreman::repo'],
    version => 'latest',
  }

  include ::foreman::compute::libvirt

  include ::foreman::plugin::discovery
  include ::foreman::plugin::hooks
  include ::foreman::plugin::puppet
  include ::foreman::plugin::templates
  Class['foreman::repo']
  -> Foreman::Plugin <| |>

  $settings.each |$setting, $value| {
    foreman_config_entry { $setting:
      value   => $value,
      require => Class['foreman::database'],
    }
  }

  create_resources('dhcp::dhcp_class', $dhcp_classes)

  class { '::candlepin::repo':
    version => '4.8',
  }

  class { '::katello::repo':
    repo_version => '4.8',
    before => [
      Class['certs'],
      Class['katello'],
      Package['katello-client-bootstrap'],
      Package['katello-debug'],
    ],
  }

  include ::katello
  Class['pulpcore::repo']
  -> Package['postgresql-evr']

  include ::foreman_proxy

  # temporary fix, https://github.com/theforeman/puppet-foreman_proxy/pull/719
  User[$foreman_proxy::user]
  -> Class['foreman_proxy::proxydhcp']

  include ::foreman_proxy::plugin::discovery

  include ::pulpcore::repo
  include ::foreman_proxy_content

  case $::osfamily {
    'RedHat': {
      case $::operatingsystemmajrelease {
        '8': {
          firewalld_service { 'RH Satellite 6':
            ensure  => 'present',
            service => 'RH-Satellite-6',
            zone    => 'public',
          }
        }
        '7': {
          firewalld_service { 'RH Satellite 6 capsule':
            ensure  => 'present',
            service => 'RH-Satellite-6-capsule',
            zone    => 'public',
          }
        }
        default: { }
      }
    }
    default: {
      firewall { '190 foreman accept http/https':
        dport => [80, 443],
        proto => 'tcp',
        #action => 'accept',
      }

      firewall { '191 foreman accept dns':
        dport => 53,
        proto => ['tcp', 'udp'],
        #action => 'accept'
      }

      firewall { '192 foreman accept dhcp server':
        dport => 67,
        proto => 'udp',
        #action => 'accept',
      }

      firewall { '193 foreman accept dhcp client':
        chain => 'OUTPUT',
        dport => 68,
        proto => 'udp',
        #action => 'accept',
      }

      firewall { '194 foreman accept tftp':
        dport => 69,
        proto => 'udp',
        #action => 'accept',
      }

      firewall { '195 foreman accept puppet':
        dport => 8140,
        proto => 'tcp',
        #action => 'accept',
      }

      firewall { '196 foreman accept https_proxy':
        dport => 8443,
        proto => 'tcp',
        #action => 'accept',
      }
    }
  }
}
