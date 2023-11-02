# Ansible-IIS-Sites

## Purpose
This repository contains the Ansible playbooks for configuring an IIS web server and its websites. These can be pulled by Ansible Tower and run as jobs that will ensure the remote servers listed in the hosts file will be configured exactly as described in the playbooks. In the future, we may be able to integrate these playbooks into a full application to handle deployment of individual web servers for students at the university, professors, or other staff.

## Why Ansible?
Ansible is part of a fairly recent trend in IT and software development known as DevOps. In particular Ansible is part of the Infrastructure as Code (IoC) approach for server management. In other words, Ansible lets us define how we want a server to look via templates, called Playbooks. We run these playbooks and Ansible ensures that our remote servers will look exactly as our playbook has defined them to. We a well written playbook, we can guarantee these tasks are idempotent. This is especially powerful for cloud based computing and clusters of servers since we can define a list of hosts as part of our Ansible inventory, which will all be visited by Ansible when a playbook referencing them is run. 
Another advantage of Ansible is that, compared to other IoC approaches, Ansible is agentless. This means we do not need a background daemon on our remote servers for Ansible to function. This reduces overhead on the servers since they do not need to constantly be polled. More information can be found [here](http://docs.ansible.com/ansible/index.html).

## Playbooks
Ansible templates are called playbooks. These define how we want our remote servers to look, and which servers should be visited for each set of tasks. Playbooks are written in YAML. In addition to the simplicity of YAML, Ansible allows for Jinja2 templating to expand the functionality of playbooks.

## YAML
YAML is a relatively low learning curve, highly human readable data serialization language. It primarily uses indentation to denote the structure of a document, and uses a few reserved characters to further define syntax. More information about YAML can be found [here](http://www.yaml.org/spec/1.2/spec.html).

**Example YAML document**
```yaml
---
receipt:     Oz-Ware Purchase Invoice
date:        2012-08-06
customer:
    first_name:   Dorothy
    family_name:  Gale

items:
    - part_no:   A4786
      descrip:   Water Bucket (Filled)
      price:     1.47
      quantity:  4

    - part_no:   E1628
      descrip:   High Heeled "Ruby" Slippers
      size:      8
      price:     133.7
      quantity:  1

bill-to:  &id001
    street: |
            123 Tornado Alley
            Suite 16
    city:   East Centerville
    state:  KS

ship-to:  *id001

specialDelivery:  >
    Follow the Yellow Brick
    Road to the Emerald City.
    Pay no attention to the
    man behind the curtain.
...
```

## Requirements
In order for Ansible to work with Windows nodes, PowerShell remoting must be enabled on the remote servers. This can be done a few different ways, but it is perhaps easiest to simply run [this script](https://github.com/ansible/ansible/blob/devel/examples/scripts/ConfigureRemotingForAnsible.ps1) on the destination servers. The script optionally takes a few switches, the effects of which are explained [here](http://docs.ansible.com/ansible/intro_windows.html#windows-system-prep).

Another requirement is that PowerShell 3.0 or higher is being run on the remote servers. This shouldn't be an issue assuming the remote devices are running at least Windows Server 2008. However, should there be a need, there is another script that will upgrade PowerShell to 3.0. It can be found [here](https://github.com/ansible/ansible/blob/devel/examples/scripts/upgrade_to_ps3.ps1).

Assuming the intent is for our web servers to sit on AWS instances, passing these scripts as part of a Cloud Formation template metadata might be an automated solution for running them on every machine.

## Repository Structure
This repo is structured according to Ansible's suggested project file structure with a few differences here and there. Specific information about each file can be found at the top of each file as a comment.

### Top Level
  * group_vars contains universal variables pulled in automatically
  * roles contains named task lists to be executed
  * hosts contains a list of target nodes
  * main.yml is the start of our playbook

```
group_vars/
roles/
hosts
main.yml
```

### roles 
  * iis - contains tasks for configuring IIS and necessary software
    + defaults folder within contains vars that are pulled in to the role automatically
  * sites - contains tasks for creating IIS sites

```
iis/
sites/
```

### sites
  * defaults are variables pulled in automatically for the role
  * helpers contains a PowerShell script that handles a case Ansible currently does not support
  * site_definitions contain site specific information
  * tasks contains the logic for creating sites, app pools, bindings, and virtual directories

```
defaults/
helpers/
site_definitions/
tasks/
```

### sites/tasks
  * create_apps.yml handles web app creation
  * create_pools.yml handles application pool creation
  * create_site.yml handles creation of individual sites
  * create_virtual_dirs.yml handles creation of virtual directories within a website
  * main.yml is the main loop with calls the four tasks above to create a fully fledged IIS site

```
create_apps.yml
create_pools.yml
create_site.yml
create_virtual_dirs.yml
main.yml
```

### site_definitions
This folders contains site specific folders. Within each site specific folder there is a file `site_vars.yml` which defines site specific information. Within the apps for for each site, each app is defined as a YAML file containing app specific information.

```
site_definitions/site_name/
  apps/
    app1.yml
    app2.yml
  site_vars.yml
```

## Execution
From a Unix host machine, assuming you are currently at the top level, simply run `ansible-playbook -i hosts main.yml` to execute the playbook.

**How It Works**
1. Ansible pulls in the list of hosts and global variables. 
2. For each host, the iis role is executed first, followed by the sites role.
3. The iis role installs IIS, any features we want on the server, and any additional applications we need.
4. The sites role configures the individual IIS websites
   * Loops over a list of sites defined in `defaults/main.yml`
5. create_site is called first. It gets the site specific variables and then, in this order, creates the app pools for the site, creates the site itself, configures local bindings, creates any virtual directories, and finally creates individual apps.
   * create_pools currently defines four pools for each site to handle different .Net and 32/64bit applications
   * create_virtual_dirs create any defined virtual directories
   * create_apps create individual web apps

**A Caveat**

The Windows modules for Ansible are less supported than Unix modules since Ansible was developed for managing Unix based systems primarily. This means there are some workarounds that are required to get the necessary functionality out of this playbook.
1. There is no native git module. Git commands must be run as part of the win_command module to get this functionality.
2. The win_iis_webapplication module does not handle apps that are nested in virtual directories. To accommodate this, a helper script is copied to the remote server that converts existing directories into IIS web applications by using one of the Web Administration cmdlets provided by Microsoft. 
