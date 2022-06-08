####  Problem Statement
To run a http server inside a Docker container in an EC2 server which returns a list of all EC2s running in a region in an AWS account along with their corresponding IPs and Tags when called on the `/ec2` path.
Inside the EC2, run your application inside a docker container and expose the application on port 8000.

The stack should be as IaC(Infrastructure as Code) and should have the following components:
* EC2
* Launch template
* ASG
* Target Group
* Entry in the ALB
* Route 53 entry
* Security Group

Make a terraform module or CDK construct which takes values like EC2 instance type, Volume size, AMI Name, Number of EC2s, DNS name. Using Ansible to install docker and other dependencies in the EC2.

### Steps:
1. Install & Configure Terraform, Ansible, AWS-CLI in the local machine/server.
2. Create Terraform files to provision resources like launch template, ASG, SG, TG, ALB in AWS. Take inputs like instance type, volume size, ami, number of EC2s, DNS name.
3. After the ASG provisioning we have instances running, now using `null_resource` (null_reource 1) trigger `local-exec` to get hosts IPs for ansible connection and store at /etc/ansible/hosts. Now trigger `null_resource` (null_resource 2) by (null_reource 1) to run `ansible-playbook playbook.yaml` on remote by `local-exec` in terraform.
4. Using ansible-playbook we install dependencies to run a container of Nginx-server like docker, aws-cli. 
5. Run a nginx-server app that is exposed on port 8000 of host & returns all running ec2 instances in the region on `/ec2` path. 
6. Created a cronjob on host instances that will run every min and update the running-ec2 instances in the index.html. Mount this index.html files on the Nginx-server conatiner.

##### Architecture
![image](https://user-images.githubusercontent.com/71806907/172694519-9d5caa89-9159-45b1-a64c-442330c2eb72.png)

### Step-1: 

##### Terraform setup:
```bash
sudo apt-get update && sudo apt-get install -y gnupg software-properties-common curl
curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo apt-key add -
sudo apt-add-repository "deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main"
sudo apt-get update && sudo apt-get install terraform

# check if terraform installed
terraform -help
```

##### Ansible setup:
```bash
sudo apt update
sudo apt install ansible -y
```

##### aws-cli setup:
```bash
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install

# to configure the default access & secret keys
aws configure
```

### Step-2: 

Provisioning resources in AWS & configuring the remote hosts using Terraform & Ansible: 
```bash
# In order to provision resources in aws
git clone `repo`
cd terraform
terraform init
terraform plan -out plan.txt
terraform apply


## testing the playbook.yaml

# test ansible connection
ansible <hosts group name> -m ping
# test get-remote-hosts ips 
sh /terraform/get-host-ip.sh
# test get-running-ec2s instances in a region
sh /files/ec2-out.sh

# run the playbook to configure remote machines 
# add --check in the end to just test the configuration on remote machine & not run
anisble-playbook <location to playbook.yaml> 
```
##### Working URLs

![smallcase tickler in](https://user-images.githubusercontent.com/71806907/172694708-9035ea24-7a5e-498e-94c9-7476bd5ddd4e.PNG)

![smallcase tickler in ec2](https://user-images.githubusercontent.com/71806907/172694730-80b979f4-1fba-4c3e-a413-689fcce2bf67.PNG)


#### Problems faced

1. Configuring target group port & instance traffic port using terraform.
2. Attach roles to launch configuration.

### Further Steps 
1. Setup a cronjob on local so that everytime a instance is not healthy & asg replaces it we run the terraform module runs but only for with the recent changes.
2. Creation of AMI of pre-configured instances that will be new version of launch-template.


###### NOTE
* Just for reference `terraform.tfvars` is added, generally the file is added in `.gitignore`.
* In order to take input for variables like ami, volume, no. of ec2s, DNS name, instance-type remove the default values in `variable.tf`



