Vagrant.configure("2") do |config|
  IMAGE = "bento/ubuntu-24.04"
  SSH_KEY_PATH = "keys/id_rsa"

  config.ssh.insert_key = false
  config.vm.box_check_update = false

  nodes = [
    { name: "controller01", ip_mgmt: "10.0.0.11", ip_pub: "192.168.100.11", cpu: 4,  mem: 8192 },
    { name: "network01",    ip_mgmt: "10.0.0.12", ip_pub: "192.168.100.12", cpu: 4,  mem: 6144 },
    { name: "compute01",    ip_mgmt: "10.0.0.13", ip_pub: "192.168.100.13", cpu: 8,  mem: 16384 },
    { name: "storage01",    ip_mgmt: "10.0.0.14", ip_pub: "192.168.100.14", cpu: 4,  mem: 8192, extra_disk: true }
  ]

  # Desactivar red NAT por defecto de libvirt
  config.vm.provider :libvirt do |lv|
    # lv.default_network = nil
    lv.nic_model_type = "virtio"
  end

  nodes.each do |node|
    config.vm.define node[:name] do |node_cfg|
      node_cfg.vm.box = IMAGE
      node_cfg.vm.hostname = "#{node[:name]}.local"

      node_cfg.vm.provider :libvirt do |lv|
        lv.cpus = node[:cpu]
        lv.memory = node[:mem]
        lv.nested = true
        # Añadir disco extra solo para storage01
        if node[:extra_disk]
          lv.storage :file, size: "500G", type: "qcow2", bus: "virtio"
        end
      end

      node_cfg.vm.network :private_network, ip: node[:ip_mgmt],
        libvirt__network_name: "mgmt-net", libvirt__dhcp_enabled: false

      node_cfg.vm.network :private_network, ip: node[:ip_pub],
        libvirt__network_name: "public-net", libvirt__dhcp_enabled: false

      # Provisioning: instalar paquetes y añadir claves SSH a root y vagrant
      node_cfg.vm.provision "shell", inline: <<-SHELL
        apt update -y
        apt install -y python3 python3-pip git vim net-tools openssh-server lvm2

        # Añadir clave al root
        mkdir -p /root/.ssh
        cat /vagrant/keys/id_rsa.pub >> /root/.ssh/authorized_keys
        chmod 600 /root/.ssh/authorized_keys

        # Añadir clave al usuario vagrant
        mkdir -p /home/vagrant/.ssh
        cat /vagrant/keys/id_rsa.pub >> /home/vagrant/.ssh/authorized_keys
        chown -R vagrant:vagrant /home/vagrant/.ssh
        chmod 600 /home/vagrant/.ssh/authorized_keys

        # Configuración SSH para evitar host key checking
        echo "Host *\n  StrictHostKeyChecking no\n" >> /root/.ssh/config
        echo "Host *\n  StrictHostKeyChecking no\n" >> /home/vagrant/.ssh/config
      SHELL
    end
  end
end
