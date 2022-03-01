resource "aws_key_pair" "production" {
  key_name   = "key-for-demo"
  public_key = file(var.ssh_pubkey_file)
}