resource "aws_key_pair" "dove-key" {
  key_name   = "dove-key"
  public_key = "your-generated-public-key"
}