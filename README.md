<h1 align="center">ARMAGEDDON PROJECT LAB 1</h1>


<br>

**Project Co-ordinator:** 
<a href="https://github.com/BalericaAI">THEO WAF CEO</a>

<br>

**Project Leader:** 
<a href="https://github.com/Charles-Roro">Charles CEO</a>

<br>

**Project Group Leader:** 
<a href="https://github.com/Brimah-Khalil-Kamara">Brimah Khalil Kamara</a>

<br>

**Cloud Engineers (Infrastructure & Netwroking):**

<a href="https://github.com/BashiM1">Mohamed Bashir</a> , <a href="https://github.com/statuc30721">ST Tucker</a> , <a href="https://github.com/Futurist2099">Trevore Jerome</a> , <a href="https://github.com/jareonbailey-web">Jae Bailey</a> and <a href="https://github.com/twixxxman357">Alastair Davis</a>

<br>




**DevSecOps (Identity, Secrets, Least Privilege):**

<a href="https://github.com/anthonyadeconsulting-source">Adeji Adeyei</a> , <a href="https://github.com/theswordpt-git">Voloxar Karsze</a> , <a href="https://github.com/Lew228">Shawn Mosby</a> , 
<a href="https://github.com/Cameron-Cleveland">Cameron-Cleveland</a> and <a href="https://github.com/penorpencil44">Mark Thornhill</a>


<br>

**Dev Tooling:**

<a href="https://github.com/waseeconsulting-git">Van Ngila</a> , <a href="https://github.com/DBs-art">Daniel Bryce</a> , <a href="https://github.com/BennyCampCloud">Campanella Godfrey Jr</a> and <a href="https://github.com/AnunnakiRa">Anunnaki MetuNetter AmenRa</a> 


<br>


---

<br>

<details>
  <summary>Table Of Contents</summary>

  - <a href="https://github.com/Melanated-Cyber-Kings/ARMAGEDDON/blob/main/README.md#-instructions">1. Instructions</a>
  - <a href="https://github.com/Melanated-Cyber-Kings/ARMAGEDDON/blob/main/README.md#-about-lab-1a">2. About Lab 1a</a>
    - <a href="https://github.com/Melanated-Cyber-Kings/ARMAGEDDON/blob/main/README.md#-21-ideation-phase-0-">2.1 Ideation Phase 0</a>
      - <a href="https://github.com/Melanated-Cyber-Kings/ARMAGEDDON/blob/main/README.md#-211-actors">2.1.1 Actors</a>
      - <a href="https://github.com/Melanated-Cyber-Kings/ARMAGEDDON/blob/main/README.md#-212-trust-problems">2.1.2 Trust Problems</a>
      - <a href="https://github.com/Melanated-Cyber-Kings/ARMAGEDDON/blob/main/README.md#-213-iam">2.1.3 IAM</a>
      - <a href="https://github.com/Melanated-Cyber-Kings/ARMAGEDDON/blob/main/README.md#-214-static-credentials">2.1.4 Static Credentials</a> 
      - <a href="https://github.com/Melanated-Cyber-Kings/ARMAGEDDON/blob/main/README.md#-215-data-flow-you-should-be-able-to-say-this-out-loud">2.1.5 Data Flow (You Should Be Able to Say This Out Loud)</a>

      
  - <a href="https://github.com/Melanated-Cyber-Kings/ARMAGEDDON/blob/main/README.md#-about-lab-1b">About Lab 1b</a>
  - <a href="https://github.com/Melanated-Cyber-Kings/ARMAGEDDON/blob/main/README.md#-about-lab-1c">About Lab 1c</a>



</details>


<br>

<br>



<br>

<h2 align="center">📌 1. Instructions</h2>

<br>

1. Pull or clone Armageddon Repo on your gitbash terminal to your git on your local machine. You will only be allowed to pull once you have cloned the repo. 

<br>

```bash
git clone git@github.com:Melanated-Cyber-Kings/ARMAGEDDON.git
```

<br>

```bash
git pull origin "name of your branch goes here"
```
<br>

2. Navigate to the cloned repo location in your gitbash terminal and create folder Lab 1a, Lab 1b and Lab 1c. These are the folders that will have your documentation and code.

<br>

3. Create your branches and switch into it immediately. (I have created the names as I want you to create your branches)

<br>

```bash
git checkout -b Mahamed-Bashir-Armageddon-Branch
```
```bash
git checkout -b Van-Ngila-Armageddon-Branch
```
```bash
git checkout -b Adedji-Adeyemi-Armageddon-Branch
```
```bash
git checkout -b Jay-Bailey-Armageddon-Branch
```
```bash
git checkout -b Daniel-Bryce-Armageddon-Branch
```
```bash
git checkout -b ST-Tucker-Armageddon-Branch
```
```bash
git checkout -b Trevore-Jerome-Armageddon-Branch
```
```bash
git checkout -b Voloxar-Karsze-Armageddon-Branch
```
```bash
git checkout -b Mark-Thornhill-Armageddon-Branch
```
```bash
git checkout -b Anunnaki-MetuNetter-AmenRa-Armageddon-Branch
```
```bash
git checkout -b Shawn-Mosby-Armageddon-Branch
```
```bash
git checkout -b Cameron-Cleveland-Armageddon-Branch
```
```bash
git checkout -b Campanella-Godfrey-Jr-Armageddon-Branch
```
```bash
git checkout -b Alastair-Davis-Armageddon-Branch
```

<br>
   
5. Create Readme.md files in each folder you created above this will be the file that you will document your Armageddon Labs in and that will be presented to THEO, so make sure it's readable and that someone who wouldnt know how to do the homework/project can follow with little to no difficulty.



<br>









<h2 align="center">📌 2. About Lab 1a</h2>

<br>

This lab demonstrates how AWS services securely interact using a trust chain. An EC2 instance must first prove its identity through an IAM role, which allows it to retrieve database credentials from AWS Secrets Manager. With valid credentials and approved network access, the application can then connect to an RDS database that only accepts connections from the EC2 security group. Access is granted step by step, ensuring compute, secrets, and data are securely connected without exposing credentials.

<br>



<h2 align="center">🤔 2.1 Ideation Phase 0 </h2>

<br>

### **What exactly are you building?**


In this Lab EC2 is the app tier. The Flask app on the EC2 serves HTTP and runs the application logic. In addition the Database tier RDS MySQL. The Lab focuses on trust between EC2 and RDS, security groups, IAM roles, Service Manager, and Stateless vs Statefull design. Adding additional tiers would increase additinal moving parts making it harder to debug. You would add an additional tier if you were using ALB's ASG, Running containers, and so on. 



<h2 align="center">🤔 2.1.1 Actors</h2>

<br>


### **From this identify system actors and their use cases**


  - User, which is a browser that wants to establish an HTTP response
  - EC2, which is a compute service that wants to establish DB credentials
  - IAM, which is an identity system that wants to decide access
  - Secrets Manager, which is secure storage that wants to deliver secrets
  - RDS, which is the database that wants to accept trusted connections



<br>

<br>




<h2 align="center">🤔 2.1.2 Trust Problems</h2>

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



<h2 align="center">🤔 2.1.3 IAM</h2>

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

<h2 align="center">🤔 2.1.4 Static Credentials</h2>
<br>

Static credentials are forbidden. These are typically your username and password which you could store in the application code, environment variables and so on. However you shouldn't store fixed passwords on a server or in code makes them easy to leak, hard to rotate, and dangerous if compromised.

If the DB credentials are put into the application code or environment variables you would have violated **least privilege**, made rotation impossible, and failed a real security review. This Lab exists to break that habbit. Instead of static credentials, this lab uses an IAM role attached to the EC2 instance to dynamically retrieve database credentials from AWS Secrets Manager.

<br>

<h2 align="center">🤔 2.1.5 Data Flow (You Should Be Able to Say This Out Loud)</h2>

<br>

### **Here is the exact flow, step by step:**

<br>

**1.** User sends HTTP request to EC2

**2.** EC2 application

- asks IAM: “Who am I?”

- IAM says: “You are this role”

**3.** EC2 calls Secrets Manager

- Secrets Manager verifies IAM policy

**4.** Secrets are returned in memory

**5.** EC2 opens TCP connection to RDS endpoint

**6.** RDS security group checks source SG

**7.** MySQL authenticates user

**8.** Query executes

**9.** Response flows back to user

<br> 


<h2 align="center">📌 About Lab 1b</h2>

<br>

Lab 1b



 <br>
<h2 align="center">📌 About Lab 1c</h2>

<br>
Lab 1c 
