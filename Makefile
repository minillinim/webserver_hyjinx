ec2-group:
	ansible-playbook -i development.hosts playbooks/ec2-security.yml -t create-group
ec2-keypair:
	ansible-playbook -i development.hosts playbooks/ec2-security.yml -t create-keypair
ec2-remove-group:
	ansible-playbook -i development.hosts playbooks/ec2-security.yml -t remove-group
ec2-remove-keypair:
	ansible-playbook -i development.hosts playbooks/ec2-security.yml -t remove-keypair

ec2-security: ec2-group ec2-keypair

ec2-remove-security: ec2-remove-group ec2-remove-keypair

ec2-instance:
	ansible-playbook -i development.hosts playbooks/ec2-instances.yml -t launch-ec2

ec2-terminate-instance:
	ansible-playbook -i development.hosts playbooks/ec2-instances.yml -t terminate-ec2 --extra-vars='{instance_ids: [$(ids)]}'

configure-server:
	ansible-playbook -i development.hosts playbooks/webserver.yml

