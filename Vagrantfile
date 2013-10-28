# -*- mode: ruby -*-
# vi: set ft=ruby :

VAGRANTFILE_API_VERSION = "2"

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
  config.vm.box = "mountain64-1"

  config.vm.provider :virtualbox do |vb|
    config.vm.box_url = "http://localhost/boxes/mountain64-1.box"
    vb.gui = true
  end

  config.vm.provider :vmware_fusion do |v|
    config.vm.box_url = "http://localhost/boxes/mountain64-1_vmware.box"
    v.gui = true

    v.vmx["memsize"] = "2048"
  end

  config.vm.provision :shell, :path => "setup.sh"

end