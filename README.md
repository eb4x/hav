```
/opt/puppetlabs/puppet/bin/r10k puppetfile check
/opt/puppetlabs/puppet/bin/r10k puppetfile install
puppet module --modulepath modules list
```

```
puppet lookup --modulepath modules --hiera_config=hiera.yaml --node foreman.maas foreman::initial_admin_password
puppet apply --modulepath modules --noop --graph --graphdir graphs manifests/site.pp
puppet apply --modulepath site-modules:modules --verbose --debug --trace --hiera_config=hiera.yaml manifests/site.pp
```

```
sudo /opt/puppetlabs/bin/puppet apply --modulepath site-modules:modules --hiera_config=hiera.yaml --show_diff manifests/site.pp
pushd /tmp && sudo --non-interactive --set-home --user=puppet /opt/puppetlabs/puppet/bin/r10k deploy environment production --verbose --puppetfile && popd
pushd /tmp && sudo --non-interactive --set-home --user=puppet /opt/puppetlabs/puppet/bin/r10k deploy environment foreman_30 --verbose --puppetfile && popd
sudo /opt/puppetlabs/bin/puppet agent -t --environment=foreman_30 --noop
```

```
dot -Tsvg graphs/expanded_relationships.dot -o graphex.svg
```
