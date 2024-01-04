class profile::foreman_proxy (
  Hash $dhcp_classes = {},
) {

  include profile::ruby

  include ::foreman::repo

  include ::foreman_proxy
  include ::foreman_proxy::plugin::discovery

  create_resources('dhcp::dhcp_class', $dhcp_classes)

  Package['ruby']
  -> Class['foreman::repo']
  -> Class['foreman_proxy::install']

  Class['foreman_proxy::register']
  -> Foreman_config_entry['create_new_host_when_facts_are_uploaded']

  # fixed in 21.0.0, https://github.com/theforeman/puppet-foreman_proxy/pull/719
  User[$foreman_proxy::user]
  -> Class['foreman_proxy::proxydhcp']

}
