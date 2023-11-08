class profile::foreman_proxy (
  Hash $dhcp_classes = {},
) {

  include ::foreman_proxy
  include ::foreman_proxy::plugin::discovery

  create_resources('dhcp::dhcp_class', $dhcp_classes)

  # temporary fix, https://github.com/theforeman/puppet-foreman_proxy/pull/719
  User[$foreman_proxy::user]
  -> Class['foreman_proxy::proxydhcp']

}
