# This file contains the salt provisioning logic.
# It will be executed if 'salt_enable' is set to true (default option) and the
# libvirt_domain.domain (hana_node) resources are created (check triggers option).

terraform {
  required_version = "~> 0.11.7"
}

resource "null_resource" "hana_node_provisioner" {

  count = "${var.enable_salt ? libvirt_domain.domain.count : 0}"

  triggers = {
      cluster_instance_ids = "${join(",", libvirt_domain.domain.*.id)}"
  }

  connection {
    host = "${element(libvirt_domain.domain.*.network_interface.0.addresses.0, count.index)}"
    user     = "root"
    password = "linux"
  }

  provisioner "file" {
    source      = "../../salt"
    destination = "/root"
  }

  provisioner "file" {
    content = <<EOF

name_prefix: ${var.name}
hostname: ${var.name}${var.count > 1 ? "0${count.index  + 1}" : ""}
domain: ${var.base_configuration["domain"]}
timezone: ${var.base_configuration["timezone"]}
reg_code: ${var.reg_code}
reg_email: ${var.reg_email}
reg_additional_modules: {${join(", ", formatlist("'%s': '%s'", keys(var.reg_additional_modules), values(var.reg_additional_modules)))}}
additional_repos: {${join(", ", formatlist("'%s': '%s'", keys(var.additional_repos), values(var.additional_repos)))}}
additional_packages: [${join(", ", formatlist("'%s'", var.additional_packages))}]
authorized_keys: [${trimspace(file(var.base_configuration["public_key_location"]))},${trimspace(file(var.public_key_location))}]
host_ips: [${join(", ", formatlist("'%s'", var.host_ips))}]
host_ip: ${element(var.host_ips, count.index)}

${var.grains}

EOF

    destination = "/etc/salt/grains"
  }

  provisioner "remote-exec" {
    inline = [
      "sh /root/salt/deployment.sh",
      "sh /root/salt/formula.sh",
    ]
  }
}
