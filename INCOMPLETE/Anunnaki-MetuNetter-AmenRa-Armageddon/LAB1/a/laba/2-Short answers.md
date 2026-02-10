A)Why is DB inbound source restricted to the EC2 security group? 

ans. The allowed inbound is restricted only to authorized users of the data base. This is a least privilege access control mechanism that minimizes the potential attack doors to a system. 

B)What port does MySQL use? 

ans. Port 3306 is the default primary network communications port. There are configurations for security purposes where this port is not used and another port is chosen for security purposes.

C)Why is Secrets Manager better than storing creds in code/user-data?  

ans. The Secrets stored in a Managed location allows for better role-based least privileged access controls to the Secrets as well as allowing the code to be more flexible and repeatable as scale. Non-hardcoded password/secrets are more secure preventing anyone with access to the code visibility to the creds. This is an GRC Audit ready solution that allows the Organization to maintain compliance to regulations with a built-in trail of the policy enforcement.
