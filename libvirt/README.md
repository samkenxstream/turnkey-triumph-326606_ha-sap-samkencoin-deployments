# Libvirt deployment with Terraform and Salt

* [Terraform cluster deployment with Libvirt](#terraform-cluster-deployment-with-libvirt)
* [Requirements](#requirements)
* [Quickstart](#quickstart)
   * [Bastion](#bastion)
* [Highlevel description](#highlevel-description)
* [Customization](#customization)
   * [QA deployment](#qa-deployment)
   * [Pillar files configuration](#pillar-files-configuration)
   * [Use already existing network resources](#use-already-existing-network-resources)
   * [Autogenerated network addresses](#autogenerated-network-addresses)
* [Advanced Customization](#advanced-customization)
   * [Terraform Parallelism](#terraform-parallelism)
* [Troubleshooting](#troubleshooting)


This sub directory contains the cloud specific part for usage of this
repository with libvirt. Looking for another provider? See
[Getting started](../README.md#getting-started).


# Requirements

   You will need to have a working libvirt/kvm setup for using the libvirt-provider. (refer to upstream doc of [libvirt provider🔗](https://github.com/dmacvicar/terraform-provider-libvirt)).

   You need the xslt processor `xsltproc` installed on the system. With it terraform is able to process xsl files.

# Quickstart

This is a very short quickstart guide.

For detailed information and deployment options have a look at `terraform.tfvars.example`.

1) **Rename terraform.tfvars:**

    ```
    mv terraform.tfvars.example terraform.tfvars
    ```

    Now, the created file must be configured to define the deployment.

    **Note:** Find some help in for IP addresses configuration below in [Customization](#customization).

2) **Generate private and public keys for the cluster nodes without specifying the passphrase:**

    Alternatively, you can set the `pre_deployment` variable to automatically create the cluster ssh keys.

    ```
    mkdir -p ../salt/sshkeys
    ssh-keygen -f ../salt/sshkeys/cluster.id_rsa -q -P ""
    ```

    The key files need to have same name as defined in [terraform.tfvars](./terraform.tfvars.example).

3) **[Adapt saltstack pillars manually](../pillar_examples/)** or set the `pre_deployment` variable to automatically copy the example pillar files.

4) **Configure Terraform Access to Libvirt**

    Set `qemu_uri = "qemu:///system"` in `terraform.tfvars` if you want to deploy on the local system
    or according to [Libvirt Provider🔗](https://registry.terraform.io/providers/dmacvicar/libvirt/latest/docs#the-connection-uri).

    Also make sure the images references in `terraform.tfvars` are existing on your system.

5) **Prepare a NFS share with the installation sources**

	Add the NFS paths to `terraform.tfvars`. The NFS server is not yet part of the deployment and must already exist.

	- **Note:** Find some help in [SAP software documentation](../doc/sap_software.md)

6) **Deploy**

    The deployment can now be started with:

    ```
    terraform init
    terraform workspace new myexecution
    # If you don't create a new workspace , the string `default` will be used as workspace name.
    # This can led to conflicts to unique names in a shared server.
    terraform workspace select myexecution
    terraform plan
    terraform apply
    ```

    To get rid of the deployment, destroy the created infrastructure with:

    ```
    terraform destroy
    ```

## Bastion

A bastion host makes no sense in this setup.

# Highlevel description

This Terraform configuration deploys SAP HANA in a High-Availability Cluster on SUSE Linux Enterprise Server for SAP Applications in **Libvirt**.

![Highlevel description](../doc/highlevel_description_openstack.png)

The infrastructure deployed includes:

* virtual network
* SBD disks
* libvirt volumes
* virtual machines

By default, this configuration will create 3 instances in Libvirt: one for support services (mainly iSCSI) and 2 cluster nodes, but this can be changed to deploy more cluster nodes as needed.

Once the infrastructure is created by Terraform, the servers are provisioned with Salt.

# Customization

In order to deploy the environment, different configurations are available through the terraform variables. These variables can be configured using a `terraform.tfvars` file. An example is available in [terraform.tfvars.example](./terraform.tvars.example). To find all the available variables check the [variables.tf](./variables.tf) file.

## QA deployment

The project has been created in order to provide the option to run the deployment in a `Test` or `QA` mode. This mode only enables the packages coming properly from SLE channels, so no other packages will be used. Set `offline_mode = true` in `terraform.tfvars` to enable it.

## Pillar files configuration

Besides the `terraform.tfvars` file usage to configure the deployment, a more advanced configuration is available through pillar files customization. Find more information [here](../pillar_examples/README.md).

## Use already existing network resources

The usage of already existing network resources (virtual network and images) can be done configuring
the `terraform.tfvars` file and adjusting some variables. The example of how to use them is available
at [terraform.tfvars.example](terraform.tfvars.example).

## Autogenerated network addresses

The assignment of the addresses of the nodes in the network can be automatically done in order to avoid
this configuration. For that, basically, remove or comment all the variables related to the ip addresses (more information in [variables.tf](variables.tf)). With this approach all the addresses are retrieved based in the provided virtual network addresses range (`vnet_address_range`).

**Note:** If you are specifying the IP addresses manually, make sure these are valid IP addresses. They should not be currently in use by existing instances. In case of shared account usage, it is recommended to set unique addresses with each deployment to avoid using same addresses.

Example based on `192.168.135.0/24` address range:

| Service                          | Variable                     | Addresses                                                              | Comments                                                                                               |
| ----                             | --------                     | ---------                                                              | --------                                                                                               |
| iSCSI server                     | `iscsi_srv_ip`               | `192.168.135.4`                                                        |                                                                                                        |
| Monitoring                       | `monitoring_srv_ip`          | `192.168.135.5`                                                        |                                                                                                        |
| HANA IPs                         | `hana_ips`                   | `192.168.135.10`, `192.168.135.11`                                     |                                                                                                        |
| HANA cluster vIP                 | `hana_cluster_vip`           | `192.168.135.12`                                                       | Only used if HA is enabled in HANA                                                                     |
| HANA cluster vIP secondary       | `hana_cluster_vip_secondary` | `192.168.135.13`                                                       | Only used if the Active/Active setup is used                                                           |
| DRBD IPs                         | `drbd_ips`                   | `192.168.135.20`, `192.168.135.21`                                     |                                                                                                        |
| DRBD cluster vIP                 | `drbd_cluster_vip`           | `192.168.135.22`                                                       |                                                                                                        |
| S/4HANA or NetWeaver IPs         | `netweaver_ips`              | `192.168.135.30`, `192.168.135.31`, `192.168.135.32`, `192.168.135.33` | Addresses for the ASCS, ERS, PAS and AAS. The sequence will continue if there are more AAS machines    |
| S/4HANA or NetWeaver virtual IPs | `netweaver_virtual_ips`      | `192.168.135.34`, `192.168.135.35`, `192.168.135.36`, `192.168.135.37` | The first virtual address will be the next in the sequence of the regular S/4HANA or NetWeaver addresses |

# Advanced Customization

## Terraform Parallelism

When deploying many scale-out nodes, e.g. 8 or 10, you should must pass the [`-nparallelism=n`🔗](https://www.terraform.io/docs/cli/commands/apply.html#parallelism-n) parameter to `terraform apply` operations.

It "limit[s] the number of concurrent operation as Terraform walks the graph."

The default value of `10` is not sufficient because not all HANA cluster nodes will get provisioned at the same. A value of e.g. `30` should not hurt for most use-cases.

# Troubleshooting

In case you have some issue, take a look at this [troubleshooting guide](../doc/troubleshooting.md).

### Resources have not been destroyed

Sometimes it happens that created resources are left after running
`terraform destroy`. It happens especially when the `terraform apply` command
was not successful and you tried to destroy the setup in order of resetting the
state of your terraform deployment to zero.
It is often helpful to simply run `terraform destroy` again. However, even when
it succeeds in this case you might still want to check manually for remaining
resources.

For the following commands you need to use the command line tool Virsh. You can
retrieve the QEMU URI Virsh is currently connected to by running the command
`virsh uri`.

### Checking networks

You can run `virsh net-list --all` to list all defined Libvirt networks. You can
delete undesired ones by executing `virsh net-undefine <network_name>`, where
`<network_name>` is the name of the network you like to delete.

### Checking domains

For each node a domain is defined by Libvirt in order to address the specific
machine. You can list all domains by running the command `virsh list`. When you
like to delete a domain you can run `virsh undefine <domain_name>` where
`<domain_name>` is the name of the domain you like to delete.

### Checking images

In case you experience issues with your images such as install ISOs for
operating systems or virtual disks of your machine check the following folder
with elevated privileges: `sudo ls -Faihl /var/lib/libvirt/images/`

### Packages failures

If some package installation fails during the salt provisioning, the
most possible thing is that some repository is missing.
Add the new repository with the needed package and try again.
