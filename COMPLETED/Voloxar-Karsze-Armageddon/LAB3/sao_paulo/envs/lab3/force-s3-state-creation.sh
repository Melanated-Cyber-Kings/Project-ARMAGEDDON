#!/bin/bash

#force creation of a state:
terraform apply -auto-approve -target=null_resource.force_state_write 2>/dev/null || true
