class profile::foreman_proxy (
  Hash $dhcp_classes = {},
) {

  include ::foreman::repo

  include ::foreman_proxy
  include ::foreman_proxy::plugin::discovery

  create_resources('dhcp::dhcp_class', $dhcp_classes)

  Class['foreman::repo']
  -> Class['foreman_proxy::install']

  # fixed in 21.0.0, https://github.com/theforeman/puppet-foreman_proxy/pull/719
  User[$foreman_proxy::user]
  -> Class['foreman_proxy::proxydhcp']

}
