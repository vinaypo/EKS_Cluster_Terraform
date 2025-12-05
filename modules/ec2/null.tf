resource "null_resource" "null_bastion" {
  connection {
    type        = var.connection_type
    user        = var.user
    private_key = var.private_key
    host        = aws_instance.bastion-server.public_ip
  }
  provisioner "file" {
    source      = var.src
    destination = var.destination
  }
  provisioner "remote-exec" {
    inline = var.commands
  }
  depends_on = [aws_instance.bastion-server]
  lifecycle {
    create_before_destroy = true
  }
}
