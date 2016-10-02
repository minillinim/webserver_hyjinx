#Webserver hijinx on AWS for fun and profit

This is an Ansible project that deploys an nginx-elastic-kibana web stack onto AWS. Note there's no Logstash, it's an experiment with rsyslog that seems to work.

#Requirements

  - A Linux machine with a working build chain (e.g. Ubuntu with build-essential)
  - Python 2.7 or better
  - An AWS account and an AWS_ACCESS_KEY and AWS_SECRET_ACCESS_KEY

From an base ubuntu install use:

```
$ sudo aptitude install git build-essential virtualenv python-dev libssl-dev
```

#Getting started

The setup is opinionated. It assumes you'd like to set up Ansible in a virtual environment. Please do.

```
 $ git clone git@github.com:minillinim/webserver_hyjinx.git
 $ cd webserver_hyjinx
 $ ./local/bin/install-hyjinx
 $ . ./local/bin/enable
```

Fomr now on, I'll refer to the folder `webserver_hyjinx` as the `<project_root>`.

Naming things is THE HARDEST thing. Check out the file `group_vars\all\common.yml` and set the `base_name` var to something sensible. Many things created by this project will be named using this variable, so make it unique.

##Adding your credentials to the project

The project makes use of Ansible vault. You will need to create a new encrypted var file called: `vault.yml` which resides in the `group_vars\all` folder. Place the password for the vault in the `vault.passwd` file in the `<project_root>` (this file is ignored by git by default).

The Kibana site is password protected. Use `htpasswd` to make a new user and password and add this information to the vault so that your file looks like this:

```
---
aws_access_key_UID                   : "__SECRET__"
aws_secret_access_key_UID            : "__SECRET__"
kibana_user                          : __PASS.pt1__
kibana_passwd                        : __PASS.pt2__
```

Where: 

`__PASS.1__:__PASS.2__` is the contents of the output from `htpasswd` split at the `:`.
UID uniquely identifies these AWS keys and matches with the entries in `group_vars\all\ec2.yml`

i.e.:

```
aws_access_key               : '{{ aws_access_key_UID }}'
aws_secret_key               : '{{ aws_secret_access_key_UID }}'
```

##Pro tip

The file `group_vars/all/ec2.yml` contains lost of useful values. It's worth checking out.

#Creating a keypair and security group

If you don't have a security group you can make one using the command:
```
$ cd <project_root>
$ make ec2-security
```

NOTE: This command relies on a sane value for `keypair_path` in `group_vars\all\ec2.yml`
It will create a keypair called `<keypair_path><base_name>.pem` and a security group called `<keypair_path>-group`

You can undo the changes made by this command using the command:

```
$ cd <project_root>
$ make ec2-remove-security
```

##Pro tip

The Makefile is modular while some of the commands listed here are compounded. Check out the Makefile if you need more granularity.

#Launching an instance

You can launch and instance using the command:

```
$ cd <project_root>
$ make ec2-instance
```

It will try to launch an EC2 instance in the security group and keypair created with the previous command.
It also provisions a 50GB volume and attaches it to the image. This is where we'll store all the other goodies.

Once this has completed, you need to add the IP address that AWS provides in the Ansible output to the "[webservers]" group of the development.hosts file:

For example, if things went well you should see the message" `"msg": "EC2 instance: i-b9b2c13b is up at: 52.63.186.119"` at the bottom of Ansible's output. Add the address `52.63.186.119` under the text `[webservers]` in the `development.hosts` file. Future steps will target this instance.

You can terminate an instance(s) you've made using the command:

```
$ cd <project_root>
$ make ids=i-XXXXX,i-XXXXX ec2-terminate-instance
```

Where `i-XXXXX` is an EC2 instance ID.

#Provisioning the webservers

Finally it's time to load the webserver containers onto the instance. You can do this with the command:

```
$ make configure-server
```

This command properly mounts the volume (@ /vol), installs Docker on the instance and then deploys three Docker containers: official `Kibana`, `ElasticSearch` containers and a custom build of the official nginx container that uses rsyslog to speak with elastic, so no LogStash. Why? I thought it would be fun. It was just hard. But now that it's done I'm intrigued to see if I can make it more robust.

Each container has a startup file which handles volume mounting stuff and linking to the other containers. Check out `/vol/containers/<container>/start` to see the specific settings for each container. All the ports these servers operate and locations of mount points etc. can be tweaked using the `group_vars\webservers\<something>.yml` files. We build the nginx container on the server and it bakes in the ports listed in this file.

This command also deploys a static website stored in the `templates` folder of the `www` role. It adds two scripts to `/usr/local/bin` called `start-web-stack` and `stop-web-stack` that do just that.

##Pro tips

The file `www.tar.gz` is a tar bomb. Be careful :)

Sometimes the new Docker install is finicky. If you get an error during the nginx build saying something like "Are you sure Docker is running". you can try the whole command again or:

```
$ make containers && make site
```

Which skips the Docker installation. Finally, you can redeploy any site using the longer Ansible command:

```
$ ansible-playbook -i development.hosts playbooks/webserver.yml -t deploy-<container_name>
```

# Starting it all up

Log into the webserver using the command:

```
$ ssh -i path_to_keypair ubuntu@ip_address
$ start-web-stack
```

The nginx-powered website is available at: `http:\\ip_address` and the Kibana instance is available at: `http:\\ip_address:8080`

Stop the servers using the command:

```
$ stop-web-stack
```

#TODO

Access to the ElasticSearch instance is controlled by the security group firewall not allowing 9200. It would be better to do this with an internal firewall

The nginx instance needs hardening up (no SSL, various other bad practices). Also the Docker container itself could be streamlined more and integrate rsyslog more betterer.

The system could be tweaked to sit behind an ELB and incorporate some scaling solution. It would be nice to use this framework to deploy identical instances to multiple regions!

The start and stop scripts for the webserver are basically toys. It would be nice to incorporate a "real" container management solution.

#License
MIT
