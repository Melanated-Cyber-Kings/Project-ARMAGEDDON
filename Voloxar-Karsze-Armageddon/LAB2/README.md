

How to start:

cd ab
if you haven't started the secrets yet
cd secrets and terraform init and terraform apply there to fire up Secrets Manager (assumes you've edited tfvars file first)
Full details in the readme in that folder.


if you haven't set up zone53 at all yet (at least point a domain at AWS name servers first):
cd domain_name_init and terraform init and terraform apply to make the domain name work.



now the fun begins.
cd ab/envs/lab2


run fireup.sh
it will complain (tooManyUpdates on the endpoint SSM parameter) but let it keep going.

Deliverables are in the ab/deliverables folder.
