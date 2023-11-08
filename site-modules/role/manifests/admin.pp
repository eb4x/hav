class role::admin {
  include profile::foreman
  include profile::foreman_proxy
  include profile::puppetserver
}
