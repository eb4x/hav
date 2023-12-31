# -*- mode: ruby -*-
# vi: set ft=ruby :

# vagrant plugin install vagrant-libvirt
# export VAGRANT_DEFAULT_PROVIDER=libvirt

# vagrant plugin install vagrant-hostmanager
# /etc/sudoers.d/vagrant_hostmanager
# Cmnd_Alias VAGRANT_HOSTMANAGER_UPDATE = /bin/cp <home-directory>/.vagrant.d/tmp/hosts.local /etc/hosts
# %<admin-group> ALL=(root) NOPASSWD: VAGRANT_HOSTMANAGER_UPDATE

require 'yaml'

$ztp = <<-SHELL
  ztp -d
  addgroup vagrant netedit
  addgroup vagrant netshow
  newgrp netedit

  for i in {1..48}; do
    net add bond host${i} bond mode 802.3ad
    net add bond host${i} bond slaves swp${i}
    net add bond host${i} clag id ${i}
  done

  net add bridge bridge ports host1-48
  net add bridge bridge vids 10,20,30
  net add bridge bridge pvid 3

  net add interface swp49 alias peerlink
  net add interface swp50 alias peerlink

  net add bond peerlink bond slaves swp49-50

  if ! [[ $(hostname) =~ ([^-]+)-([^-]+)-([[:digit:]]+) ]]; then
    echo "Well, this hostname is unexpected."
    exit 1
  fi

  parity=$((10#${BASH_REMATCH[3]} % 2))
  net add clag peer sys-mac 44:38:39:be:ef:aa interface swp49-50 primary backup-ip 10.10.10.$(( 1 + $parity ))

  net commit
SHELL

Vagrant.configure("2") do |config|

  # Allow messing with the hypervisor /etc/hosts file
  # for dns
  #config.hostmanager.enabled = true
  #config.hostmanager.manage_host = true

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

  # Network concept
  #
  # Each switch gets a 127.0.x.y address (where y is an odd number)      idx * 2 -1
  # Each switch connects to 127.0.x.z address (where z is a even number) idx * 2
  #  Henceforth called "the tail end"
  # and a port number representing the swp.

  # Each host can be represented by a single port number,
  # on "the tail end" (127.0.x.z) of both switches.
  # Incrementing the port number between each host.

  (1..2).each do |leaf_idx|
    zero_leaf_idx = sprintf('%02d', leaf_idx)

    config.vm.define "vagrant-leaf-#{zero_leaf_idx}" do |subconfig|
      subconfig.vm.hostname = "vagrant-leaf-#{zero_leaf_idx}.vagrant.local"
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

      # Notes about mac addressing.
      #
      # * 3rd least significant byte, could represent spine instances?
      # * 2nd least significant byte, represents the leaf instance.
      # * 1st least significant byte is a zero-index to the port number
      #   Normally these would be hexits, and include a-f, but when using
      #   base10. It's human readable, and it can be reused for udp port
      #   numbers, which are base10.

      # hosts
      (1..48).each do |port_idx|
        zero_port_idx = sprintf('%02d', port_idx)

        subconfig.vm.network "private_network", auto_config: false,
          mac: "44:38:39:00:#{zero_leaf_idx}:#{zero_port_idx}",
          libvirt__tunnel_type: "udp",
          libvirt__tunnel_local_ip: "127.0.1.#{leaf_idx * 2 - 1}",
          libvirt__tunnel_local_port: "100#{zero_port_idx}",
          libvirt__tunnel_ip: "127.0.1.#{leaf_idx * 2}",
          libvirt__tunnel_port: "100#{zero_port_idx}",
          libvirt__iface_name: "swp#{port_idx}"
      end

      # peerlink
      (49..50).each do |port_idx|
        zero_port_idx = sprintf('%02d', port_idx)

        # leaf-01 <-> leaf-02, leaf-03 <-> leaf-04
        peer_switch_offset = leaf_idx % 2 == 0 ? -2 : 2

        subconfig.vm.network "private_network", auto_config: false,
          mac: "44:38:39:00:#{zero_leaf_idx}:#{zero_port_idx}",
          libvirt__tunnel_type: "udp",
          libvirt__tunnel_local_ip: "127.0.1.#{leaf_idx * 2 - 1}",
          libvirt__tunnel_local_port: "100#{zero_port_idx}",
          libvirt__tunnel_ip: "127.0.1.#{leaf_idx * 2 - 1 + peer_switch_offset}",
          libvirt__tunnel_port: "100#{zero_port_idx}",
          libvirt__iface_name: "swp#{port_idx}"
      end

      subconfig.vm.synced_folder ".", "/vagrant", disabled: true
      #subconfig.vm.synced_folder ".", "/vagrant", type: "rsync",
      #  rsync__exclude: [".git/", ".r10k/", "modules/"]

      subconfig.vm.provision "ztp", type: "shell",
        privileged: true,
        inline: $ztp

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
  end

  yaml = YAML.load_file('nodes.yaml')

  yaml['nodes'].each_with_index do |node, node_idx|
    # They start with index at 0, but we want from 1
    leaf_pair = (node_idx / 48) + 1
    node_idx = (node_idx % 48) + 1

    zero_prefixed_node_idx = sprintf('%02d', node_idx)

    config.vm.define "#{node['name']}" do |subconfig|
      subconfig.vm.hostname = "#{node['name']}.vagrant.local"
      subconfig.vm.box = "almalinux/8"

      # /etc/modprobe.d/kvm.conf
      # modprobe -r kvm_intel; modprobe kvm_intel
      subconfig.vm.provider "libvirt" do |lv|
        lv.nested = true
        #lv.cpu_mode = "custom"
        #lv.cpu_model = "SandyBridge-IBRS"
        #lv.cpu_feature name: "vmx", policy: "require"
      end

      (1..2).each do |port_idx|
        zero_prefixed_leaf_idx = sprintf('%02d', (leaf_pair * 2 - 1) + port_idx - 1)
        zero_prefixed_port_idx = sprintf('%02d', port_idx)

        subconfig.vm.network "private_network", auto_config: false,
          mac: "52:54:00:#{zero_prefixed_leaf_idx}:#{zero_prefixed_node_idx}:#{zero_prefixed_port_idx}",
          libvirt__tunnel_type: "udp",
          libvirt__tunnel_local_ip: "127.0.1.#{leaf_pair * (port_idx * 2)}",
          libvirt__tunnel_local_port: "100#{zero_prefixed_node_idx}",
          libvirt__tunnel_ip: "127.0.1.#{leaf_pair * (port_idx * 2) - 1}",
          libvirt__tunnel_port: "100#{zero_prefixed_node_idx}",
          libvirt__iface_name: "eth#{port_idx}"
      end

      subconfig.vm.synced_folder ".", "/vagrant", type: "rsync",
        rsync__exclude: [".git/", ".r10k/", "modules/"]

      subconfig.vm.provision "nmcli", type: "shell",
        privileged: true,
        inline: <<-SHELL
          dnf install -y bash-completion lldpd vim
          sed -i 's/^LLDPD_OPTIONS=.*/LLDPD_OPTIONS="-I eth1,eth2"/' /etc/sysconfig/lldpd
          systemctl enable --now lldpd

          # Fix missing speed for lacp
          ethtool -s eth1 speed 1000 duplex full
          ethtool -s eth2 speed 1000 duplex full

          # nmcli connection migrate bond0
          if sed -i 's/#plugins=ifcfg-rh/plugins=keyfile/' /etc/NetworkManager/NetworkManager.conf; then
            systemctl restart NetworkManager.service
          fi

          nmcli con

          nmcli con add type bridge con-name br-provision ifname br-provision ipv4.method manual ipv4.address '172.22.0.1#{zero_prefixed_node_idx}/24'
          nmcli con add type bridge con-name br-openstack ifname br-openstack ipv4.method disabled
          nmcli con add type bridge con-name br-storage   ifname br-storage   ipv4.method disabled
          nmcli con add type bridge con-name br-tunnel    ifname br-tunnel    ipv4.method disabled

          nmcli con add type bond con-name bond0 ifname bond0 mode 802.3ad bond.options "mode=802.3ad,miimon=100" master br-provision

          nmcli con add type ethernet slave-type bond con-name bond0p0 ifname eth1 master bond0; nmcli con up bond0p0
          nmcli con add type ethernet slave-type bond con-name bond0p1 ifname eth2 master bond0; nmcli con up bond0p1

          nmcli con add type vlan con-name bond0.10 ifname bond.10 dev bond0 id 10 master br-openstack
          nmcli con add type vlan con-name bond0.20 ifname bond.20 dev bond0 id 20 master br-storage
          nmcli con add type vlan con-name bond0.30 ifname bond.30 dev bond0 id 30 master br-tunnel
        SHELL

      subconfig.vm.provision "puppet install", type: "shell", run: "never",
        privileged: true, env: { "PUPPET_MAJ_VERSION" => "6" },
        path: "scripts/puppet-install.sh"

      subconfig.vm.provision "puppet modules", type: "shell", run: "never",
        privileged: false,
        keep_color: true,
        inline: <<-SHELL
          cd /vagrant
          /opt/puppetlabs/puppet/bin/r10k --verbose=info puppetfile install
        SHELL

      subconfig.vm.provision "puppet apply", type: "shell", run: "never",
        privileged: false,
        keep_color: true,
        inline: <<-SHELL
          cd /vagrant
          sudo /opt/puppetlabs/bin/puppet apply --modulepath site-modules:modules --hiera_config=hiera.yaml manifests/site.pp
        SHELL
    end
  end

  config.vm.define "vagrant-admin-01", autostart: false do |subconfig|
    subconfig.vm.hostname = "vagrant-admin-01.vagrant.local"
    subconfig.vm.box = "almalinux/8"

    subconfig.vm.provider "libvirt" do |lv|
      lv.cpus = 4
      lv.memory = 8192
    end

    #subconfig.vm.network "private_network", ip: "172.22.0.10",
    #  libvirt__network_name: "provision",
    #  libvirt__dhcp_enabled: false,
    #  libvirt__forward_mode: "nat"

    node_idx = 19

    leaf_pair = (node_idx / 48) + 1
    node_idx = (node_idx % 48) + 1

    zero_prefixed_node_idx = sprintf('%02d', node_idx)

    (1..2).each do |port_idx|
      zero_prefixed_leaf_idx = sprintf('%02d', (leaf_pair * 2 - 1) + port_idx - 1)
      zero_prefixed_port_idx = sprintf('%02d', port_idx)

      subconfig.vm.network "private_network", auto_config: false,
        mac: "52:54:00:#{zero_prefixed_leaf_idx}:#{zero_prefixed_node_idx}:#{zero_prefixed_port_idx}",
        libvirt__tunnel_type: "udp",
        libvirt__tunnel_local_ip: "127.0.1.#{leaf_pair * (port_idx * 2)}",
        libvirt__tunnel_local_port: "100#{zero_prefixed_node_idx}",
        libvirt__tunnel_ip: "127.0.1.#{leaf_pair * (port_idx * 2) - 1}",
        libvirt__tunnel_port: "100#{zero_prefixed_node_idx}",
        libvirt__iface_name: "eth#{port_idx}"
    end

    subconfig.vm.synced_folder ".", "/vagrant", type: "rsync",
      rsync__exclude: [".git/", ".r10k/", "modules/"]

    subconfig.vm.provision "nmcli", type: "shell",
      privileged: true,
      inline: <<-SHELL
        dnf install -y bash-completion lldpd vim
        sed -i 's/^LLDPD_OPTIONS=.*/LLDPD_OPTIONS="-I eth1,eth2"/' /etc/sysconfig/lldpd
        systemctl enable --now lldpd

        # Fix missing speed for lacp
        ethtool -s eth1 speed 1000 duplex full
        ethtool -s eth2 speed 1000 duplex full

        nmcli con
        nmcli con add type bond con-name bond0 ifname bond0 mode 802.3ad bond.options "mode=802.3ad,miimon=100" ipv4.method manual ipv4.address '172.22.0.10/24'
        nmcli con add type ethernet slave-type bond con-name bond0p0 ifname eth1 master bond0; nmcli con up bond0p0
        nmcli con add type ethernet slave-type bond con-name bond0p1 ifname eth2 master bond0; nmcli con up bond0p1
      SHELL

    subconfig.vm.provision "puppet install", type: "shell",
      privileged: true,
      path: "scripts/puppet-install.sh"

    subconfig.vm.provision "foreman deps", type: "shell",
      privileged: true, keep_color: true,
      inline: <<-SHELL
        source /etc/os-release
        distro_major_version=${VERSION_ID%.*}
        distro_minor_version=${VERSION_ID#*.}

        if [[ $distro_major_version -eq "8" ]]; then
          dnf module enable -y postgresql:12
          dnf install -y git vim
        fi
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
