class profile::katello (
) {

  Class['foreman::repo']
  -> Class['certs::install', 'foreman_proxy_content', 'katello']

  include ::foreman::cli::katello
  include ::foreman::cli::remote_execution
  include ::foreman::plugin::remote_execution
  include ::foreman::plugin::tasks

  include ::foreman_proxy_content

  #package { 'foreman-proxy-content':
  #  ensure => installed,
  #  require => Class['katello::repo'],
  #  before => Class['foreman_proxy', 'foreman_proxy_content'],
  #}

  include ::katello
  include ::katello::repo

  Class['katello::repo']
  -> Class['certs::install', 'foreman_proxy_content', 'foreman_proxy_content::pub_dir', 'katello']

  include ::pulpcore::repo
  Class['pulpcore::repo']
  -> Package['postgresql-evr']

  include ::candlepin::repo
  Class['candlepin::repo']
  -> Package['katello']

  if $facts['os']['selinux']['enabled'] {
    # Needs fix in candlepin/manifests/artemis.pp
    Selboolean['candlepin_can_bind_activemq_port']
    -> Service['tomcat']

    package { 'katello-selinux':
      ensure => installed,
      require => Class['foreman::repo', 'katello::repo'],
      before => Service['foreman'],
    }
  }

  # XXX Fix pulpcore dependency, maybe fixed in a future release?
  package { 'python3-markuppy':
    ensure => present,
    require => Class['pulpcore::repo'],
    before => Class['pulpcore'],
  }

}
