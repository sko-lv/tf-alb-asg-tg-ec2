## Hometask 2  
### Subtasks:  
Create ALB  
Create ASG with Launch Template. Use AWS Ubuntu AMI. Type t2-micro.  
Userdata: setup nginx server. ASG Min size:1, desired:2, max:3  
Attach ASG as Target Group to ALB  
Configure SSL/TLS certificate on ALB  
Register A-record in Route53 for ALB  
Check your cluster in browser  

### Prereqiusites:  
1. AWS account
2. GitHub account
3. Registered DNS domain
4. AWS CLI installed and configured
5. Terraform installed and configured for your AWS account  

### Run project:
1. _terraform plan_
2. _terraform apply_
3. Check your site with browser
4. Use _terraform destroy_ to free-up your recourses



