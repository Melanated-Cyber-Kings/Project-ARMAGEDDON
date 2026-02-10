#Short Incident Report

PART VI — Required Incident Report (Short)
Students must submit:
Incident Summary
What failed?
How was it detected?
Root cause
Time to recovery
App was giving back 500 errors. Alarm email was sent. Password was changed inside Secrets Manager without updating database; error logs in Cloudwatch pointed to authentication failures. Recovery took about an hour.
