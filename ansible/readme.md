# Ansible Automation

Excellent documentation for Ansible is available at http://docs.ansible.com/ and I suggest anyone using the system take a read through some of it to understand what the system is capable of.

Ansible code will be written and tested executing from a linux/os x environment.  It's possible to get it running on Windows, but not recommended. 

The documentation site referenced above has various installation methods for installing the base Ansible system to your machine.  For OS X I used the "pip" installation method.

# Directory Structure and Files
Looking at the ansible directory there are some key things to understand.  

* site.yml - This file contains the top level code that will be executed.  When we get to the command line section you'll see that it's site.yml that is actually being run through the system.  Inside this file you will basically see include statements for each "role" or type of server for now, but other things may be added to it later.
* inventory - this file will contain each host in the environment.  Once more things are moved to AWS we can switch this to be a dynamic inventory based on EC2 tags via an inventory script instead of a flat file.  For now, each host will be entered into this file.  Hosts are split up into role sections.
* ansible.cfg - config file for Ansible, mostly defaults but we can specify things like parallelism (how many hosts are worked on simultaneously) and various other settings.  If this file is present in the current directory Ansible will automatically pick it up and use it.
* role directories - underneath common you will see a set of yml files in a tasks directory - these are the actual playbooks to perform each step in the common role setup.  A file "main.yml" is what is executed automatically by Ansible and this file is set up to include the others.  In the "docserver" role directory, we just put everything in the main.yml file since that role is a specific system setup not a set of various tasks that we might want to edit separately.  Also there is a "handlers" directory where we define a task for restarting Tomcat which can be called by the main playbook as a notification if there is a need to restart Tomcat due to a deployment etc.  This way we can not have tomcat restarted everytime the playbook is run if the system is already configured.  Ansible playbooks are meant to be idempotent - meaning then can be run multiple times and will only change things if necessary.

# Runtime Commands

When running Ansible - a command such as this is used

`ansible-playbook -i inventory ./site.yml --private-key ~/.ssh/fanxchange-ops.pem`

This means run playbook "site.yml" against the inventory file "inventory" and use the ssh key "fanxchange-ops.pem".  If you don't include a private key then ansible will try to use whatever private keys are in your ~/.ssh directory by default.  Note that one of the basic things the Ansible playbooks do is set up users, so it's important to have the base key from AWS to start things off though technically after the first run you could move to using your own key to do future updates.

The ansible playbook command basically always takes an inventory and a top level playbook to execute.

You can also run ansible not as a playbook but to run commands directly such as:

`ansible --inventory-file=./inventory prod -a "./deploy.sh"`

That command line would run "./deploy.sh" on every server in the "inventory" file tagged as "prod".

To run a playbook that contains an encrypted file use the following command

`ansible-playbook -i inventory-fanxchange ./site.yml --private-key ~/.ssh/fanxchange-ops.pem --ask-vault-pass`


# Ansible Vault

Some files contain sensitive information and they are stored as encrypted files under source control. Use the following commands in the directory of the file to encrypt, decrypt and edit the files. Please use the password stored "somewhere" to encrypt and decrypt files.

### Encrypt a file

`ansible-vault encrypt xxxxx.yml`

### Decrypt a file

`ansible-vault decrypt xxxxx.yml`

### Edit a encrypted file

`ansible-vault edit xxxxx.yml`