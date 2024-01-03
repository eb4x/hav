class profile::ruby (
  String $version = '2.7',
) {

  # There was code in place to handle ruby version 2.7 until foreman 3.2
  # https://github.com/theforeman/puppet-foreman/commit/95f2b4d8b5f7ec9dc865188ba21321a234fcfbae
  package { 'ruby':
    ensure      => $version,
    enable_only => true,
    provider    => 'dnfmodule',
  }

}
