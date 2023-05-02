```
r10k puppetfile check
r10k puppetfile install
```

```
puppet module --modulepath modules list
puppet lookup --modulepath modules --hiera_config=hiera.yaml --node foreman.maas foreman::initial_admin_password
puppet apply --modulepath modules --noop --graph --graphdir graphs manifests/site.pp 
puppet apply --modulepath site-modules:modules --verbose --debug --trace --hiera_config=hiera.yaml manifests/site.pp

sudo /opt/puppetlabs/bin/puppet apply --modulepath site-modules:modules --hiera_config=hiera.yaml manifests/site.pp
```

```
dot -Tsvg graphs/expanded_relationships.dot -o graphex.svg
```
