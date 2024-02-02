#!/usr/bin/env bash

source /etc/os-release
distro_major_version=${VERSION_ID%.*}
distro_minor_version=${VERSION_ID#*.}

pkg_mgr=dnf

if [[ $distro_major_version -le "7" ]]; then
  pkg_mgr=yum
  PUPPET_MAJ_VERSION=5
fi

if [ "${PUPPET_MAJ_VERSION:=7}" -eq 6 ]; then
  $pkg_mgr install -y gcc make
fi

$pkg_mgr install -y bash-completion epel-release git-core vim wget

rpm -Uvh https://yum.puppet.com/puppet${PUPPET_MAJ_VERSION:=7}-release-el-${distro_major_version}.noarch.rpm
$pkg_mgr install -y puppet-agent

if [ ${PUPPET_MAJ_VERSION:=7} -lt 7 ]; then
  /opt/puppetlabs/puppet/bin/gem install r10k -v '<4'
else
  /opt/puppetlabs/puppet/bin/gem install faraday-net_http -v '~>3.0.2'
  /opt/puppetlabs/puppet/bin/gem install faraday -v '~>2.8.1'
  /opt/puppetlabs/puppet/bin/gem install r10k
fi

if [ ${PUPPET_SERVER:=false} = "false" ]; then
  exit 0
fi

# Only puppet-server code beyond this point

mkdir -p /etc/puppetlabs/r10k
#vim /etc/puppetlabs/r10k/r10k.yaml
cat <<EOF | sudo tee /etc/puppetlabs/r10k/r10k.yaml
---
cachedir: '/var/cache/r10k'
#proxy: 'http://proxy.example.com:8000'
sources:
  control-repo:
    remote: 'https://github.com/eb4x/hav.git'
    basedir: '/etc/puppetlabs/code/environments'
EOF
mkdir -p /var/cache/r10k

$pkg_mgr install -y puppetserver
chown puppet:puppet /var/cache/r10k

# Fix permissions for puppet and install from control-repo
chown puppet:puppet -R /etc/puppetlabs/code/environments
pushd /tmp && sudo --non-interactive --set-home --user=puppet /opt/puppetlabs/puppet/bin/r10k deploy environment production --verbose --puppetfile && popd

# Get PDK
#wget --content-disposition 'https://pm.puppet.com/cgi-bin/pdk_download.cgi?dist=el&rel=7&arch=x86_64&ver=latest'
#sudo yum install ./pdk-*.rpm
