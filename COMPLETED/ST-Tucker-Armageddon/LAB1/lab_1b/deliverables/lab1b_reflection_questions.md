A) Why might Parameter Store still exist alongside Secrets Manager?  
Parameter Store is still in use because it’s built for secure, hierarchical storage of configuration data and secrets. Teams use it for things like AMI IDs, license keys, passwords, and database connection strings. It’s simple, cost effective, and already integrated into a lot of existing AWS environments. Secrets Manager, on the other hand, is focused on managing the full lifecycle of sensitive secrets like database credentials, API keys, and OAuth tokens, and it adds automatic rotation on top of that. So in practice, Parameter Store handles general config and straightforward secrets, while Secrets Manager is used when you need rotation and more advanced secret management features.

B) What breaks first during secret rotation?  
What usually breaks first during secret rotation is the application that uses the secret. Even though Secrets Manager rotates the secret correctly, the application might still be running with the old value—like an old password or API key—because it hasn’t been restarted, refreshed, or updated to pull the new one yet. So the rotation itself works, but the app fails because it’s still trying to authenticate with outdated credentials

C) Why should alarms be based on symptoms instead of causes?  
From an engineer or administrator perspective, alarms should be based on symptoms because symptoms tell us when the system is actually failing from the user’s point of view. We need alerts that reflect real impact—like higher error rates, failed logins, or increased latency—because those symptoms show the service isn’t meeting expectations. If we only alert on causes, like CPU spikes or a secret rotation event, we risk noisy alerts that don’t require action or we miss issues that don’t match our assumptions. Symptom based alerts give us the information we need to respond quickly and accurately.


D) How does this lab reduce mean time to recovery (MTTR)?  
This lab reduces MTTR by improving both how quickly issues are detected and how quickly they’re diagnosed. It trains you to identify failures through logs, retrieve the correct configuration values from Parameter Store or Secrets Manager, and restore the service using accurate data instead of guesswork. That repeatable process shortens the time between noticing a problem and getting the system healthy again.

E) What would you automate next?  
The next thing I’d automate is the end-to-end validation workflow around secret rotation. That includes automatically testing the new secret, confirming that services can authenticate with it, and only then promoting it to production. If validation fails, the system should roll back to the previous known good value. This keeps issues contained an