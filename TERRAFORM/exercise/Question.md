Exercise Question 

You are given the ID of a VPC created in the us-east-1 region. You will need to create a MySQL RDS database instance inside a subnet of the given VPC. The VPC contains two private subnets; the IDs of these subnets are not given to you. 

Here are the specifications of the database:

username: should be defined as a variable with a default value of “admin_user”

password: should be defined as a variable. Its value is specified in the tfvars file.

port number: 3306

database instance class: db.t3.micro (this is to determine the 
memory and computation capacity of the database
)

allocated storage: 10 GiB

From this database instance, you want to return the database hostname, username, password and port number as output values.

Here are some useful links:

https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/db_instance
https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/db_subnet_group
https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/subnets
