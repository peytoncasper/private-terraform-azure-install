#cloud-config
package_upgrade: true
runcmd:
 - echo "Starting Terraform Install"
 - curl https://install.terraform.io/ptfe/stable > install.sh
 - chmod +x install.sh
 - sudo ./install.sh
