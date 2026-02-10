Currently broken.  Peering is connecting but no traffic is going through.


How to try anyways:

cd LAB3/tokyo
if you haven't started the secrets yet
cd secrets and terraform init and terraform apply there to fire up Secrets Manager (assumes you've edited tfvars file first)
Full details in the readme in that folder.

Then replicate the secret in Sao Paulo:
cd LAB3/sao_paulo/secrets and run replicate-secret.sh

if you haven't set up zone53 at all yet (at least point a domain at AWS name servers first):
cd domain_name_init and terraform init and terraform apply to make the domain name work.



now the fun begins.
cd sao_paulo/envs/lab3

run fireup.sh
it will fail.

then cd tokyo/envs/lab3
run fireap.sh

it will also fail.

then run them both again.  This time they will succeed.  


