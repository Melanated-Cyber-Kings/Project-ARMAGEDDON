<h1 align="center">ARMAGEDDON PROJECT LAB 1</h1>


**Project Co-ordinator:** 
<a href="https://github.com/BalericaAI">THEO WAF CEO</a>


**Project Leader:** 
<a href="https://github.com/Charles-Roro">Charles CEO</a>


**Project Group Leader:** 
<a href="https://github.com/Brimah-Khalil-Kamara">Brimah Khalil Kamara</a>


**Cloud Engineers (Infrastructure & Netwroking):**

<a href="https://github.com/BashiM1">Mohamed Bashir</a> , <a href="https://github.com/statuc30721">ST Tucker</a> , <a href="https://github.com/Futurist2099">Trevore Jerome</a> , <a href="https://github.com/jareonbailey-web">Jae Bailey</a> and <a href="https://github.com/twixxxman357">Alastair Davis</a>




**DevSecOps (Identity, Secrets, Least Privilege):**

<a href="https://github.com/anthonyadeconsulting-source">Adeji Adeyei</a> , <a href="https://github.com/theswordpt-git">Voloxar Karsze</a> , <a href="https://github.com/Lew228">Shawn Mosby</a> , 
<a href="https://github.com/Cameron-Cleveland">Cameron-Cleveland</a> and <a href="https://github.com/penorpencil44">Mark Thornhill</a>



**Dev Tooling:**

<a href="https://github.com/waseeconsulting-git">Van Ngila</a> , <a href="https://github.com/DBs-art">Daniel Bryce</a> , <a href="https://github.com/BennyCampCloud">Campanella Godfrey Jr</a> and <a href="https://github.com/AnunnakiRa">Anunnaki MetuNetter AmenRa</a> 


<br>


---

<br>

<details>
  <summary>Table Of Contents</summary>

  - <a href="https://github.com/Melanated-Cyber-Kings/ARMAGEDDON/blob/main/README.md#-about-lab-1a">About Lab 1a</a>
    - <a href="https://github.com/Melanated-Cyber-Kings/ARMAGEDDON/blob/main/README.md#-phase-0-ideation">Phase 0 Ideation:</a>
      - <a href="https://github.com/Melanated-Cyber-Kings/ARMAGEDDON/blob/main/README.md#-actors">0.1 Actors:</a>
      - <a href="https://github.com/Melanated-Cyber-Kings/GCP-Armageddon/tree/main?tab=readme-ov-file#step-1">0.2 Trust Problems:</a>
  - <a href="https://github.com/Melanated-Cyber-Kings/ARMAGEDDON/blob/main/README.md#-about-lab-1b">About Lab 1b</a>
  - <a href="https://github.com/Melanated-Cyber-Kings/ARMAGEDDON/blob/main/README.md#-about-lab-1c">About Lab 1c</a>



</details>


<br>

<br>

<h2 align="center">📌 About Lab 1a</h2>

<br>

This lab demonstrates how AWS services securely interact using a trust chain. An EC2 instance must first prove its identity through an IAM role, which allows it to retrieve database credentials from AWS Secrets Manager. With valid credentials and approved network access, the application can then connect to an RDS database that only accepts connections from the EC2 security group. Access is granted step by step, ensuring compute, secrets, and data are securely connected without exposing credentials.

<br>



<h2 align="center">🤔 Phase 0 Ideation</h2>

<br>

What exactly are you building? 


In this Lab EC2 is the app tier. The Flask app on the EC2 serves HTTP and runs the application logic. In addition the Database tier RDS MySQL. The Lab focuses on trust between EC2 and RDS, security groups, IAM roles, Service Manager, and Stateless vs Statefull design. Adding additional tiers would increase additinal moving parts making it harder to debug. You would add an additional tier if you were using ALB's ASG, Running containers, and so on. 



<h2 align="center">🤔 0.1 Actors</h2>

<br>


From this identify system actors and their use cases


  - User, which is a browser that wants to establish an HTTP response
  - EC2, which is a compute service that wants to establish DB credentials
  - IAM, which is an identity system that wants to decide access
  - Secrets Manager, which is secure storage that wants to deliver secrets
  - RDS, which is the database that wants to accept trusted connections



<br>

<br>



<h2 align="center">🤔 0.2 Trust Problems</h2>

<br>

Two trust problems identified. 

<br>

- Who can connect to the database?
    
- Who can authenticate to the database?

<br>


**Who can connect to the database?**

This is solved by Security Groups at the network level and answers the important question, is traffic from this EC2 even allowed to reach the database. These rules are enforced before authentication where no usernames or passwordes are involved. This happens at the network level.

**Who can authenticate to the database?**

This is solved by the Secrets Manager and MySQL credentials. This answers the question if a connection is allowed, who is logging in. These rules are enforced after network access, where a username and password are required, and the credentials don not live on the EC2 disk, "Stateless".





<br>

<br>


<h2 align="center">📌 About Lab 1b</h2>

<br>
Lab 1b



 <br>
<h2 align="center">📌 About Lab 1c</h2>

<br>
Lab 1c 
