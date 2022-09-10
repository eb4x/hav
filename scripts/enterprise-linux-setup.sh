#!/usr/bin/env bash

source /etc/os-release
distro_major_version=${VERSION_ID%.*}
distro_minor_version=${VERSION_ID#*.}

pkg_mgr=dnf
puppet_major=6

if [[ $distro_major_version -le "7" ]]; then
  pkg_mgr=yum
  puppet_major=5
fi

sudo $pkg_mgr install -y epel-release git-core vim wget

sudo rpm -Uvh https://yum.puppet.com/puppet${puppet_major}-release-el-${distro_major_version}.noarch.rpm
sudo $pkg_mgr install -y puppet-agent

sudo /opt/puppetlabs/puppet/bin/gem install r10k

sudo mkdir -p /etc/puppetlabs/r10k
#vim /etc/puppetlabs/r10k/r10k.yaml
cat <<EOF | sudo tee /etc/puppetlabs/r10k/r10k.yaml
---
cachedir: '/var/cache/r10k'
#proxy: 'http://proxy.example.com:8000'
sources:
  control-repo:
    remote: 'https://github.com/eb4x/puppet-project.git'
    basedir: '/etc/puppetlabs/code/environments'
EOF
sudo mkdir -p /var/cache/r10k

sudo $pkg_mgr install -y puppetserver
sudo chown puppet:puppet /var/cache/r10k

# Fix permissions for puppet and install from control-repo
sudo chown puppet:puppet -R /etc/puppetlabs/code/environments
pushd /tmp && sudo --non-interactive --set-home --user=puppet /opt/puppetlabs/puppet/bin/r10k deploy environment production --verbose --puppetfile && popd

# Get PDK
#wget --content-disposition 'https://pm.puppet.com/cgi-bin/pdk_download.cgi?dist=el&rel=7&arch=x86_64&ver=latest'
#sudo yum install ./pdk-*.rpm
