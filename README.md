# Terraform AWS EC2 Instance Deployment

This guide provides a step-by-step tutorial to launch an AWS EC2 instance using Terraform. The configuration sets up an EC2 instance with an Ubuntu AMI, a security group, and a key pair for SSH access.

## Prerequisites

- **AWS Account**: Ensure you have an active AWS account.
- **Terraform**: Install Terraform on your local machine ([Download Terraform](https://www.terraform.io/downloads.html)).
- **AWS CLI**: Install and configure the AWS CLI ([AWS CLI Installation](https://aws.amazon.com/cli/)).
- **SSH Key Pair**: Generate an SSH key pair for secure access to the EC2 instance.

## Step-by-Step Setup

### 1. Configure AWS IAM User
1. Log in to the **AWS Management Console**.
2. Navigate to **IAM** > **Users** > **Add users**.
3. Enter a username (e.g., `terraform-user`).
4. Select **Programmatic access** for CLI usage.
5. Attach the **AdministratorAccess** policy directly.
6. Create the user and note the **Access Key ID** and **Secret Access Key**.
   - In the user’s **Security credentials** tab, click **Create access key**.
   - Choose **CLI** as the use case and copy the keys.

### 2. Set Up SSH Key Pair
1. Generate an SSH key pair using `ssh-keygen`:
   ```bash
   ssh-keygen -t rsa -b 4096 -f ~/.ssh/dove-key
   ```
2. Copy the public key (`dove-key.pub`) content for use in the `Keypair.tf` file.

### 3. Directory Structure
Create the following Terraform configuration files in a project directory:

```
project/
├── provider.tf
├── Instance.tf
├── InstID.tf
├── Keypair.tf
├── SecGrp.tf
```

### 4. Terraform Configuration Files

#### provider.tf
Configures the AWS provider with the specified region.

```hcl
provider "aws" {
  region = "us-east-1"
}
```

#### Instance.tf
Defines the EC2 instance resource with specified AMI, instance type, and security group.

```hcl
resource "aws_instance" "web" {
  ami                    = data.aws_ami.amiID.id
  instance_type          = "t3.micro"
  key_name               = "dove-key"
  vpc_security_group_ids = [aws_security_group.dove-sg.id]
  availability_zone      = "us-east-1a"

  tags = {
    Name    = "Dove-web"
    Project = "Dove"
  }
}
```

#### InstID.tf
Fetches the latest Ubuntu 22.04 AMI and outputs the AMI ID.

```hcl
data "aws_ami" "amiID" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"]
}

output "instance_id" {
  description = "AMI ID of Ubuntu instance"
  value       = data.aws_ami.amiID.id
}
```

#### Keypair.tf
Creates an AWS key pair for SSH access. Replace `public-key-need-to-use-keygen` with the actual public key.

```hcl
resource "aws_key_pair" "dove-key" {
  key_name   = "dove-key"
  public_key = "public-key-need-to-use-keygen"
}
```

#### SecGrp.tf
Configures a security group with rules for SSH and HTTP access, and allows all outbound traffic.

```hcl
resource "aws_security_group" "dove-sg" {
  name        = "dove-sg"
  description = "dove-sg"

  tags = {
    Name = "dove-sg"
  }
}

resource "aws_vpc_security_group_ingress_rule" "ssh_from_my_ip" {
  security_group_id = aws_security_group.dove-sg.id
  cidr_ipv4         = "113.211.212.131/32"
  from_port         = 22
  ip_protocol       = "tcp"
  to_port           = 22
}

resource "aws_vpc_security_group_ingress_rule" "allow_http" {
  security_group_id = aws_security_group.dove-sg.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 80
  ip_protocol       = "tcp"
  to_port           = 80
}

resource "aws_vpc_security_group_egress_rule" "allowAllOutBound_ipv4" {
  security_group_id = aws_security_group.dove-sg.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

resource "aws_vpc_security_group_egress_rule" "allowAllOutBound_ipv6" {
  security_group_id = aws_security_group.dove-sg.id
  cidr_ipv6         = "::/0"
  ip_protocol       = "-1"
}
```

### 5. Terraform Commands
Run the following commands in the project directory:

1. **Format the configuration**:
   ```bash
   terraform fmt
   ```
   Ensures consistent formatting of Terraform files.

2. **Initialize the project**:
   ```bash
   terraform init
   ```
   Downloads the AWS provider and sets up the backend.

3. **Validate the configuration**:
   ```bash
   terraform validate
   ```
   Checks for syntax errors and configuration validity.

4. **Plan the deployment**:
   ```bash
   terraform plan
   ```
   Generates an execution plan to preview changes.

5. **Apply the configuration**:
   ```bash
   terraform apply
   ```
   Creates the EC2 instance and associated resources. Confirm with `yes` when prompted.

### 6. Accessing the EC2 Instance
- Use the private key (`dove-key`) to SSH into the instance:
  ```bash
  ssh -i ~/.ssh/dove-key ubuntu@<public-ip>
  ```
  Replace `<public-ip>` with the instance’s public IP from the AWS Console or Terraform output.

### 7. Cleanup
To avoid charges, destroy the resources when done:
```bash
terraform destroy
```
Confirm with `yes` when prompted.

## Notes
- Replace the `public_key` in `Keypair.tf` with the actual public key from `dove-key.pub`.
- Update the `cidr_ipv4` in `SecGrp.tf` for SSH access to your actual IP address for security.
- Ensure your AWS credentials are configured in `~/.aws/credentials` or via environment variables:
  ```bash
  export AWS_ACCESS_KEY_ID="your-access-key"
  export AWS_SECRET_ACCESS_KEY="your-secret-key"
  ```

## Troubleshooting
- **AMI Not Found**: Verify the AMI filter in `InstID.tf` matches available AMIs in the `us-east-1` region.
- **Permission Denied**: Ensure the SSH key has correct permissions (`chmod 400 ~/.ssh/dove-key`).
- **Terraform Errors**: Check AWS credentials and region settings in `provider.tf`.
