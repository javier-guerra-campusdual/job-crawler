resource "aws_key_pair" "key" {
  key_name   = "my-key-name-finale"
  public_key = file(var.public_key_path)  # Ruta de tu clave pública en tu máquina local
}


resource "aws_instance" "elasticsearch_nodes" {
  count           = 3  # Número de instancias EC2 que deseas lanzar
  ami            = "ami-091f18e98bc129c4e" #ubuntu 24
  instance_type   = "t3.xlarge"
  subnet_id       = var.subnet_ids[(count.index % 3)] 
  key_name        = aws_key_pair.key.key_name
  disable_api_stop=false

  # Seguridad
  vpc_security_group_ids = [aws_security_group.elasticsearch.id]

  tags = {
    Name = "Grupo2-elastic-instance-${var.project_name}-${var.environment}-es-${count.index + 1}"
  }
  provisioner "remote-exec" {# este bloque es para que si ejecuto un local-exec sobre este ec2 espere a que la maquina este accesible.
    inline = ["echo Hey system"]
    connection {
      type        = "ssh"
      user        = "ubuntu"  # Usa "ec2-user" para AMIs de Amazon Linux, "ubuntu" para AMIs de Ubuntu
      private_key = file(var.private_key_path)  # Ruta a tu clave privada en tu máquina local
      host        = self.public_ip  # La IP pública de la instancia
    }
  }


}

# Output para las IPs privadas
output "elasticsearch_private_ips" {
  value = [for instance in aws_instance.elasticsearch_nodes : instance.private_ip]
}


# Generar archivo seed_hosts.txt localmente
resource "null_resource" "generate_seed_file" {

  provisioner "local-exec" {
    command = <<EOT
      echo "Generando archivo de configuración localmente..."
      # Crear archivo seed_hosts.txt con todas las IPs privadas
      echo "${join(",", [for instance in aws_instance.elasticsearch_nodes : instance.private_ip])}" > ../modules/elasticsearch/ansible/seed_hosts.txt && echo "algo"
      echo "listo"
    EOT
  }
  triggers = {
    always_run = "${timestamp()}"  # Usamos timestamp como valor cambiante
  }
  depends_on=[aws_instance.elasticsearch_nodes]
}

resource "null_resource" "update_hosts_ini1" {
  provisioner "local-exec" {
    #command = "pwd"
    command = "echo [webservers] > ../modules/elasticsearch/ansible/hosts.ini "
     }
  # Usar triggers para forzar la ejecución del recurso
  triggers = {
    always_run = "${timestamp()}"  # Usamos timestamp como valor cambiante
  }
}

resource "null_resource" "update_hosts_ini2" {
  provisioner "local-exec" {
    command = <<-EOT
      echo "${join("\n", [for ip in aws_instance.elasticsearch_nodes[*].public_ip : "${ip} ansible_user=ubuntu ansible_ssh_private_key_file=../my-ec2-key "]) }" >> ../modules/elasticsearch/ansible/hosts.ini && echo "algo"
      echo "listo"
    EOT
  }

  triggers = {
    always_run = "${timestamp()}"
  }

  depends_on = [
    null_resource.update_hosts_ini1,
    aws_instance.elasticsearch_nodes
  ]
}



resource "null_resource" "provisioner1" {
  provisioner "local-exec" {

    command = "export ANSIBLE_CONFIG=../modules/elasticsearch/ansible/ansible.cfg && ansible-playbook -i ../modules/elasticsearch/ansible/hosts.ini ../modules/elasticsearch/ansible/install.yml"
  }
  # Usar triggers para forzar la ejecución del recurso
  #triggers = {
  #  always_run = "${timestamp()}"  # Usamos timestamp como valor cambiante
  #}
  
  depends_on = [null_resource.update_hosts_ini2]
}
resource "null_resource" "provisioner2" {
  provisioner "local-exec" {

    command = "export ANSIBLE_CONFIG=../modules/elasticsearch/ansible/ansible.cfg && ansible-playbook -i ../modules/elasticsearch/ansible/hosts.ini ../modules/elasticsearch/ansible/install2.yml"
  }
  # Usar triggers para forzar la ejecución del recurso
  triggers = {
    always_run = "${timestamp()}"  # Usamos timestamp como valor cambiante
  }
  
  depends_on = [null_resource.provisioner1]
}




