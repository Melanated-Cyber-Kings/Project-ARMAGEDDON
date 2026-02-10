<h1 align="center">Ideation Phase 0</h1>

<br>

<details>
  <summary>Table Of Contents</summary>

  

  - <a href="https://github.com/Melanated-Cyber-Kings/ARMAGEDDON/blob/main/README.md#-21-ideation-phase-0-">1 Ideation Phase 0</a>
    - <a href="https://github.com/Melanated-Cyber-Kings/ARMAGEDDON/blob/main/README.md#-211-actors">1.1 Actors</a>
    - <a href="https://github.com/Melanated-Cyber-Kings/ARMAGEDDON/blob/main/README.md#-212-trust-problems">1.2 Trust Problems</a>
    - <a href="https://github.com/Melanated-Cyber-Kings/ARMAGEDDON/blob/main/README.md#-213-iam">1.3 IAM</a>
    - <a href="https://github.com/Melanated-Cyber-Kings/ARMAGEDDON/blob/main/README.md#-214-problems-with-static-credentials">1.4 Problems With Static Credentials</a> 
    - <a href="https://github.com/Melanated-Cyber-Kings/ARMAGEDDON/blob/main/README.md#-215-data-flow-you-should-be-able-to-say-this-out-loud">1.5 Data Flow (You Should Be Able to Say This Out Loud)</a>
    - <a href="https://github.com/Melanated-Cyber-Kings/ARMAGEDDON/blob/main/README.md#-215-data-flow-you-should-be-able-to-say-this-out-loud">1.6 Stateful VS Stateless</a>



</details>


<h2 align="center">🤔 1 Ideation Phase 0 </h2>

<br>

### **What exactly are you building?**


In this Lab EC2 is the app tier. The Flask app on the EC2 serves HTTP and runs the application logic. In addition the Database tier RDS MySQL. The Lab focuses on trust between EC2 and RDS, security groups, IAM roles, Service Manager, and Stateless vs Statefull design. Adding additional tiers would increase additinal moving parts making it harder to debug. You would add an additional tier if you were using ALB's ASG, Running containers, and so on. 



<h2 align="center">🤔 1.1 Actors</h2>

<br>


### **From this identify system actors and their use cases**


  - User, which is a browser that wants to establish an HTTP response
  - EC2, which is a compute service that wants to establish DB credentials
  - IAM, which is an identity system that wants to decide access
  - Secrets Manager, which is secure storage that wants to deliver secrets
  - RDS, which is the database that wants to accept trusted connections



<br>

<br>




<h2 align="center">🤔 1.2 Trust Problems</h2>

<br>

### **Two trust problems identified**

<br>

- Who can connect to the database?
    
- Who can authenticate to the database?

<br>


**Who can connect to the database?**

This is solved by Security Groups at the network level and answers the important question, is traffic from this EC2 even allowed to reach the database. These rules are enforced before authentication where no usernames or passwordes are involved. This happens at the network level. Security groups control which servers can even reach the database, blocking traffic at the network level before any login happens.

To get an idea of how this would logically flow think of it like this

<br>

**1. On the RDS side, you create a security group (sg-rds-lab) that says:**
<br>
- Allow inbound traffic on port 3306 (MySQL)
- Source = the EC2’s security group (sg-ec2-lab)

<br>

**2. When the EC2 instance tries to connect:**
<br>  
- AWS checks the RDS security group
- If the connection comes from a server in `sg-ec2-lab` and uses port `3306` → connection allowed
- If not → connection blocked

<br> 

**3. This is enforced at the network level, before the database even asks for a username or password.**

<br>

**Who can authenticate to the database?**

This is solved by the Secrets Manager and MySQL credentials. This answers the question if a connection is allowed, who is logging in. These rules are enforced after network access, where a username and password are required, and the credentials don not live on the EC2 disk, "Stateless".




Interview trap:
If you explain credentials before security groups, you’re thinking backwards.


<br>

<br>



<h2 align="center">🤔 1.3 IAM</h2>

<br>

IAM does not allow the EC2 instance to connect to RDS, to open ports, or manage MySQL users. It only answers this question "Is the EC2 allowed to read this secret from the secrets manager?" If IAM is wrong the app fails before the DB connection and MySQL is never reached. Below is the trust chain. 

<br>

**EC2 Instance**  
↓ *(assume role)*  
**IAM Role**  
↓ *(policy allows)*  
**AWS Resource**


<br>

The EC2 instance does not have a username or password. Instead, AWS automatically gives it an IAM role, which acts like an identity badge. When the EC2 instance needs the database password, it asks AWS, “Who am I allowed to be?” The IAM role answers that question and checks its permissions. If the role is allowed, AWS Secrets Manager then gives the EC2 instance the secret. If not, access is denied. In other words The EC2 instance proves who it is using an IAM role, and if that role has permission, Secrets Manager allows it to retrieve the secret.


<br>

<h2 align="center">🤔 1.4 Problems With Static Credentials</h2>
<br>

Static credentials are forbidden. These are typically your username and password which you could store in the application code, environment variables and so on. However you shouldn't store fixed passwords on a server or in code makes them easy to leak, hard to rotate, and dangerous if compromised.

If the DB credentials are put into the application code or environment variables you would have violated **least privilege**, made rotation impossible, and failed a real security review. This Lab exists to break that habbit. Instead of static credentials, this lab uses an IAM role attached to the EC2 instance to dynamically retrieve database credentials from AWS Secrets Manager.

<br>

<h2 align="center">🤔 1.5 Data Flow (You Should Be Able to Say This Out Loud)</h2>

<br>

### **Here is the exact flow, step by step:**

<br>

**1. User sends HTTP request to EC2**

**2. EC2 application**

- asks IAM: “Who am I?”

- IAM says: “You are this role”

**3 EC2 calls Secrets Manager**

- Secrets Manager verifies IAM policy

**4. Secrets are returned in memory**

**5. EC2 opens TCP connection to RDS endpoint**

**6. RDS security group checks source SG**

**7. MySQL authenticates user**

**8. Query executes**

**9. Response flows back to user**

<br> 

### Refined Flow: EC2 Accessing RDS via Secrets Manager

<br>

**1. User sends HTTP request to EC2**
   - A user hits your web application running on the EC2 instance.

**2. EC2 application starts processing**
   - The app uses its **IAM role** (instance profile) to get temporary credentials via AWS STS.
   - The STS (Security token Service) will issue temporary security credentials. When your EC2 instance has an IAM role attached (via instance profile), it doesn’t have permanent AWS keys. So instead
     - EC2 contacts STS to get temporary credentials for its IAM role
     - STS validates the role
     - STS returns the temporary credentials
     - EC2 uses these credentials to call AWS services securely, like Secrets Manager
    
Why this matters is Security. Secrets don’t persist on disk. If someone gained access to the EC2 storage, they can’t see the secret. Also volatility. When the app restarts, the secret must be fetched again from Secrets Manager via IAM + STS.


**3. EC2 IAM role validated**
   - IAM confirms the role is allowed to call Secrets Manager.

**4. EC2 app calls Secrets Manager**
   - `GetSecretValue` API is called.
   - Secrets Manager checks the IAM policy.

**5. Secrets returned to EC2 app**
   - The secret (username/password) is **loaded into the app’s variables in RAM**:
     - Example:  
       ```python
       db_username = secret["username"]
       db_password = secret["password"]
       ```
   - ⚡ **Important:** The secret is never written to disk; it only exists in RAM while the app runs.

**6. EC2 opens TCP connection to RDS endpoint**
   - Uses `db_username` and `db_password` from variables to authenticate.

**7. RDS security group checks**
   - Connection allowed only if the source is `sg-ec2-lab` and port 3306 is used.
   - Otherwise, connection is blocked.

**8. MySQL authenticates user**
   - RDS validates the credentials stored in the app’s variables.

**9. Query executes and response flows back to user**
   - Data is sent back to the user.
   - After the connection is closed, **the variables (and secret) remain only in RAM temporarily** and disappear when the app stops.

<br>


<br>


<h2 align="center">🤔 1.6 Stateful VS Stateless</h2>

The EC2 is stateless as it can be replaced at any time, whereas the RDS is stateful as data must persist. This is why EC2 can be terminated safely and RDS must be protected and private.

<br>



<br>


