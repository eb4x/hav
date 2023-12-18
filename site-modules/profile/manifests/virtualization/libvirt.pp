class profile::virtualization::libvirt (
  Hash $networks = {},
  Boolean $manage_firewall = true,
) {

  package { 'libvirt':
    ensure => installed,
  }

  $defaults = {
    path => '/etc/libvirt/libvirtd.conf',
    require => Package['libvirt'],
    notify => Service['libvirtd-tcp'],
  }

  $libvirtd_conf_settings = {
    '' => {
      'listen_tls' => '0',
      'listen_tcp' => '1',
      'auth_tcp' => '"none"',
    }
  }

  inifile::create_ini_settings($libvirtd_conf_settings, $defaults)

  service { 'libvirtd-tcp':
    name => 'libvirtd-tcp.socket',
    enable => true,
    ensure => 'running',
    require => Package['libvirt'],
  }

  create_resources('::libvirt::network', $networks)
  # We only want the network creation from libvirt module. But it fails with
  #   Error: Could not find resource 'Service[libvirtd]' in parameter 'require'
  #   (file: modules/libvirt/manifests/network.pp, line: 92)
  # So we declare that here.
  service { 'libvirtd':
    require => Package['libvirt'],
  }

  if $manage_firewall {
    firewalld_custom_service { 'libvirt-gfx':
      ensure => 'present',
      short  => 'Virtual Machine Management (GFX)',
      ports  => [
        {
          'port'     => '5900-5999',
          'protocol' => 'tcp',
        },
      ],
    }

    firewalld_service { 'Virtual Machine Management (GFX)':
      ensure  => 'present',
      service => 'libvirt-gfx',
      zone    => 'public',
    }

    firewalld_service { 'Virtual Machine Management':
      ensure  => $libvirtd_conf_settings['']['listen_tcp'] ? {
        '1' => 'present', '0' => 'absent', default => 'absent'
      },
      service => 'libvirt',
    }

    firewalld_service { 'Virtual Machine Management (TLS)':
      ensure  => $libvirtd_conf_settings['']['listen_tls'] ? {
        '1' => 'present', '0' => 'absent', default => 'absent'
      },
      service => 'libvirt-tls',
    }
  }
}
