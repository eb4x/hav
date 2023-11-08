# https://github.com/theforeman/foreman-installer/blob/develop/config/katello.yaml
# order:
#   - certs
#   - foreman
#   - katello
#   - foreman_proxy
#   - foreman_proxy::plugin::pulp
#   - foreman_proxy_content
#   - puppet

class profile::foreman (
  Hash $settings = {},
) {

  include ::foreman
  include ::foreman::cli
  include ::foreman::compute::libvirt
  include ::foreman::plugin::discovery
  include ::foreman::plugin::hooks
  include ::foreman::plugin::templates
  include ::foreman::repo

  Class['foreman::repo']
  -> Class['foreman::install']

  Class['foreman::repo']
  -> Foreman::Plugin <| |>

  class { '::puppet':
    server                => true,
    server_external_nodes => '',
  }

  foreman::cli::plugin { 'foreman':
    require => Class['foreman::repo'],
    version => 'latest',
  }
  foreman::cli::plugin { 'foreman_templates':
    require => Class['foreman::repo'],
    version => 'latest',
  }


  $settings.each |$setting, $value| {
    foreman_config_entry { $setting:
      value   => $value,
      require => Class['foreman::database'],
    }
  }

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
