locals {
  sonar_url = "http://${aws_instance.sonar.private_ip}:9000"
  nexus_url = "http://${aws_instance.nexus.private_ip}:8081"
}

resource "aws_instance" "jenkins" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.instance_type
  key_name               = var.key_pair_name
  subnet_id              = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.devops.id]
  associate_public_ip_address = true

  user_data = templatefile("${path.module}/../cloud-init/jenkins.sh", {
    repo_url           = var.repo_url
    admin_user         = var.jenkins_admin_user
    admin_password     = var.jenkins_admin_password
    sonar_url          = local.sonar_url
    nexus_url          = local.nexus_url
    ansible_master_ip  = aws_instance.ansible_master.private_ip
    ansible_slave_ip   = aws_instance.ansible_slave.private_ip
    app_server_ip      = aws_instance.app_server.private_ip
    ansible_private_key = tls_private_key.ansible.private_key_pem
    nexus_repo_name    = var.nexus_repo_name
  })

  tags = merge(local.common_tags, { Name = "jenkins" })
}

resource "aws_instance" "sonar" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = var.instance_type
  key_name                    = var.key_pair_name
  subnet_id                   = aws_subnet.public.id
  vpc_security_group_ids      = [aws_security_group.devops.id]
  associate_public_ip_address = true

  user_data = templatefile("${path.module}/../cloud-init/sonar.sh", {
    admin_password = var.jenkins_admin_password
  })

  tags = merge(local.common_tags, { Name = "sonarqube" })
}

resource "aws_instance" "nexus" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = var.instance_type
  key_name                    = var.key_pair_name
  subnet_id                   = aws_subnet.public.id
  vpc_security_group_ids      = [aws_security_group.devops.id]
  associate_public_ip_address = true

  user_data = templatefile("${path.module}/../cloud-init/nexus.sh", {
    admin_password = var.jenkins_admin_password
    repo_name      = var.nexus_repo_name
  })

  tags = merge(local.common_tags, { Name = "nexus" })
}

resource "aws_instance" "ansible_master" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = var.instance_type
  key_name                    = var.key_pair_name
  subnet_id                   = aws_subnet.public.id
  vpc_security_group_ids      = [aws_security_group.devops.id]
  associate_public_ip_address = true

  user_data = templatefile("${path.module}/../cloud-init/ansible_master.sh", {
    repo_url          = var.repo_url
    public_key        = tls_private_key.ansible.public_key_openssh
    private_key       = tls_private_key.ansible.private_key_pem
    ansible_slave_ip  = aws_instance.ansible_slave.private_ip
    app_server_ip     = aws_instance.app_server.private_ip
  })

  tags = merge(local.common_tags, { Name = "ansible-master" })
}

resource "aws_instance" "ansible_slave" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = var.instance_type
  key_name                    = var.key_pair_name
  subnet_id                   = aws_subnet.public.id
  vpc_security_group_ids      = [aws_security_group.devops.id]
  associate_public_ip_address = true

  user_data = templatefile("${path.module}/../cloud-init/ansible_slave.sh", {
    public_key = tls_private_key.ansible.public_key_openssh
  })

  tags = merge(local.common_tags, { Name = "ansible-slave" })
}

resource "aws_instance" "app_server" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = var.instance_type
  key_name                    = var.key_pair_name
  subnet_id                   = aws_subnet.public.id
  vpc_security_group_ids      = [aws_security_group.devops.id]
  associate_public_ip_address = true

  user_data = templatefile("${path.module}/../cloud-init/app_server.sh", {
    public_key = tls_private_key.ansible.public_key_openssh
  })

  tags = merge(local.common_tags, { Name = "app-server" })
}

resource "local_file" "ansible_inventory" {
  content = templatefile("${path.module}/templates/inventory.tpl", {
    ansible_slave_ip = aws_instance.ansible_slave.private_ip
    app_server_ip    = aws_instance.app_server.private_ip
  })

  filename = "${path.module}/../ansible/inventory.ini"
}
