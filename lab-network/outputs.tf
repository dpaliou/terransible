output "Jenkins-Main-Node-Public-IP" {
  value = aws_instance.jenkins-master.public_ip
}

output "Jenkins-Worker-Public-IPs" {
  value = {
    for instance in aws_instance.jenkins-worker-paris :
    instance.id => instance.public_ip
  }
}

#Output the DNS name of the LB created
output "LB-DNS-NAME" {
  value = aws_lb.application_lb.dns_name
}