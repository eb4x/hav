# -*- mode: ruby -*-
# vi: set ft=ruby :

# vagrant plugin install vagrant-libvirt
# export VAGRANT_DEFAULT_PROVIDER=libvirt

# vagrant plugin install vagrant-hostmanager
# /etc/sudoers.d/vagrant_hostmanager
# Cmnd_Alias VAGRANT_HOSTMANAGER_UPDATE = /bin/cp <home-directory>/.vagrant.d/tmp/hosts.local /etc/hosts
# %<admin-group> ALL=(root) NOPASSWD: VAGRANT_HOSTMANAGER_UPDATE

Vagrant.configure("2") do |config|

  # Allow messing with the hypervisor /etc/hosts file
  # for dns
  config.hostmanager.enabled = true
  config.hostmanager.manage_host = true

  config.vm.provider "libvirt" do |lv|
    lv.machine_type = "q35" # qemu-system-x86_64 -machine help

    # https://libvirt.org/formatdomain.html#bios-bootloader
    #lv.loader = '/usr/share/OVMF/OVMF_CODE.secboot.fd'
    #lv.nvram = '/usr/share/OVMF/OVMF_VARS.secboot.fd'

    lv.cpus = 2
    lv.memory = 4096

    lv.disk_bus = "scsi"
    lv.disk_controller_model = "virtio-scsi"

    lv.graphics_type = "vnc"
    lv.video_type = "virtio"
  end

  config.vm.define "vagrant-leaf-01" do |subconfig|
    subconfig.vm.hostname = "vagrant-leaf-01.vagrant.local"
    subconfig.vm.box = "CumulusCommunity/cumulus-vx"
    #subconfig.vm.box_version = "5.5.1" # no net command
    #subconfig.vm.box_version = "4.4.5" # dropped broadcom support
    subconfig.vm.box_version = "4.3.2"

    subconfig.vm.provider "libvirt" do |lv|
      # Cumulus VX, which requires at least 768MB of RAM
      # Cumulus VX versions 4.3 and later requires 2 vCPUs
      # BUT even 1GB doesn't seem enough for the system anymore.
      lv.memory = 2048
      lv.cpus = 2
      lv.disk_bus = "virtio"
      lv.nic_adapter_count = 54 # 52 for ports and 2 for mgmt and vagrant?
    end

    subconfig.vm.network "private_network", auto_config: false,
      mac: "44:38:39:00:00:01",
      libvirt__tunnel_type: "udp",
      libvirt__tunnel_local_ip: "127.0.1.1",
      libvirt__tunnel_local_port: "10001",
      libvirt__tunnel_ip: "127.0.1.2",
      libvirt__tunnel_port: "10000",
      libvirt__iface_name: "swp1"

    subconfig.vm.network "private_network", auto_config: false,
      mac: "44:38:39:00:00:02",
      libvirt__tunnel_type: "udp",
      libvirt__tunnel_local_ip: "127.0.1.1",
      libvirt__tunnel_local_port: "10002",
      libvirt__tunnel_ip: "127.0.1.3",
      libvirt__tunnel_port: "10000",
      libvirt__iface_name: "swp2"

    subconfig.vm.synced_folder ".", "/vagrant", disabled: true
    #subconfig.vm.synced_folder ".", "/vagrant", type: "rsync",
    #  rsync__exclude: [".git/", ".r10k/", "modules/"]

    subconfig.vm.provision "ztp", type: "shell",
      privileged: true,
      inline: <<-SHELL
        ztp -d
        addgroup vagrant netedit
        addgroup vagrant netshow
        newgrp netedit

        net add vlan 3
        net add interface swp1 bridge access 3
        net add interface swp2 bridge access 3
        net commit
      SHELL

    #subconfig.vm.provision "puppet install", type: "shell",
    #  privileged: true,
    #  inline: <<-SHELL
    #    codename=$(lsb_release --codename --short)

    #    if [ ! -f /etc/apt/sources.list.d/puppet${PUPPET_MAJ_VERSION:-6}.list ]; then
    #      wget https://apt.puppet.com/puppet${PUPPET_MAJ_VERSION:-6}-release-${codename}.deb
    #      sudo dpkg -i puppet${PUPPET_MAJ_VERSION:-6}-release-${codename}.deb
    #      rm puppet${PUPPET_MAJ_VERSION:-6}-release-${codename}.deb
    #    fi

    #    # It's a stable enough interface
    #    echo "Apt::Cmd::Disable-Script-Warning \\"true\\";" > /etc/apt/apt.conf.d/99apt-disable-script-warning

    #    apt update
    #    apt install -y puppet-agent gcc libc6-dev

    #    /opt/puppetlabs/puppet/bin/gem install r10k -v '<4'
    #  SHELL
  end

  config.vm.define "vagrant-controller-01" do |subconfig|
    subconfig.vm.hostname = "vagrant-controller-01.vagrant.local"
    subconfig.vm.box = "almalinux/8"

    subconfig.vm.provider "libvirt" do |lv|
      lv.cpus = 4
      lv.memory = 8192
    end

    subconfig.vm.network "private_network", auto_config: false,
      libvirt__tunnel_type: "udp",
      libvirt__tunnel_local_ip: "127.0.1.2",
      libvirt__tunnel_local_port: "10000",
      libvirt__tunnel_ip: "127.0.1.1",
      libvirt__tunnel_port: "10001",
      libvirt__iface_name: "sfp0"
  end

  config.vm.define "vagrant-controller-02" do |subconfig|
    subconfig.vm.hostname = "vagrant-controller-02.vagrant.local"
    subconfig.vm.box = "almalinux/8"

    subconfig.vm.provider "libvirt" do |lv|
      lv.cpus = 4
      lv.memory = 8192
    end

    subconfig.vm.network "private_network", auto_config: false,
      libvirt__tunnel_type: "udp",
      libvirt__tunnel_local_ip: "127.0.1.3",
      libvirt__tunnel_local_port: "10000",
      libvirt__tunnel_ip: "127.0.1.1",
      libvirt__tunnel_port: "10002",
      libvirt__iface_name: "sfp0"
  end

  config.vm.define "vagrant-admin-01" do |subconfig|
    subconfig.vm.hostname = "vagrant-admin-01.vagrant.local"
    subconfig.vm.box = "almalinux/8"

    subconfig.vm.provider "libvirt" do |lv|
      lv.cpus = 4
      lv.memory = 8192
    end

    subconfig.vm.network "private_network", ip: "172.16.0.10",
      libvirt__network_name: "provision",
      libvirt__dhcp_enabled: false,
      libvirt__forward_mode: "nat"

    subconfig.vm.synced_folder ".", "/vagrant", type: "rsync",
      rsync__exclude: [".git/", ".r10k/", "modules/"]

    subconfig.vm.provision "puppet install", type: "shell",
      privileged: true,
      inline: <<-SHELL
        source /etc/os-release
        distro_major_version=${VERSION_ID%.*}
        distro_minor_version=${VERSION_ID#*.}

        if [[ $distro_major_version -eq "8" ]]; then
          dnf module enable -y postgresql:12
          dnf module enable -y ruby:2.7
          dnf install -y git vim
        fi

        if [ "${PUPPET_MAJ_VERSION:-6}" -eq 6 ]; then
          dnf install -y gcc make
        fi

        rpm -Uvh https://yum.puppet.com/puppet${PUPPET_MAJ_VERSION:-6}-release-el-${distro_major_version}.noarch.rpm
        dnf install -y puppet-agent
        /opt/puppetlabs/puppet/bin/gem install r10k -v '<4'
      SHELL

    subconfig.vm.provision "puppet modules", type: "shell",
      privileged: false, keep_color: true,
      inline: <<-SHELL
        cd /vagrant
        /opt/puppetlabs/puppet/bin/r10k --verbose=info puppetfile install
      SHELL

    subconfig.vm.provision "puppet apply", type: "shell",
      privileged: false, keep_color: true,
      inline: <<-SHELL
        cd /vagrant
        sudo /opt/puppetlabs/bin/puppet apply --modulepath site-modules:modules --hiera_config=hiera.yaml manifests/site.pp
      SHELL

    subconfig.vm.provision "ansible foreman", type: "ansible", compatibility_mode: "2.0",
      galaxy_role_file: "ansible/ansible-collection-requirements.yml",
      raw_arguments: ["--diff"], playbook: "ansible/foreman.yml"
  end

  config.vm.define "test-discovery", autostart: false do |subconfig|
    subconfig.vm.provider "libvirt" do |lv|
      lv.mgmt_attach = false

      boot_network = { network: "provision" }
      lv.boot 'network'
      lv.boot 'hd'
      lv.storage :file, size: "20G", type: "qcow2", allow_existing: true
    end

    subconfig.vm.network "private_network", auto_config: false,
      libvirt__network_name: "provision",
      libvirt__dhcp_enabled: false,
      libvirt__forward_mode: "nat"
  end
end
