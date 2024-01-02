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
  include ::foreman::cli::templates
  include ::foreman::compute::libvirt
  include ::foreman::plugin::discovery
  include ::foreman::plugin::hooks
  include ::foreman::plugin::templates
  include ::foreman::repo

  Class['foreman::repo']
  -> Class['foreman::install']

  Class['foreman::repo']
  -> Foreman::Plugin <| |>

  Class['foreman::repo']
  -> Foreman::Cli::Plugin <| |>

  create_resources('foreman_config_entry', $settings, { require => Class['foreman::database'] })

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
