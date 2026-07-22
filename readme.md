# AWS Two-Tier VPC — Terraform

Two-tier AWS network as code. Public subnet with an internet-facing
EC2 that doubles as a bastion; private subnet with outbound-only access
through NAT. Remote state in S3, locked and versioned.

Whole stack, including instance config, comes up from `terraform apply`.

## Architecture
```
Internet → IGW → VPC 10.0.0.0/16 (eu-north-1) 
├── public-a 10.0.0.0/24 (1a) EC2 frontend/bastion + NAT 
├── private-a 10.0.1.0/24 (1a) EC2 backend 
└── private-b 10.0.2.0/24 (1b) 
```
Public RT: `0.0.0.0/0` → IGW. Private RT: `0.0.0.0/0` → NAT.
Backend SG allows ingress from the frontend SG, not a CIDR.

## Usage

```bash
# state bucket, once
cd bootstrap && terraform init && terraform apply

# stack
terraform init -backend-config=state.config
terraform apply
terraform destroy    # NAT bills hourly
```

Needs `terraform.tfvars` with `my_ip` (`/32`, SSH ingress) and a locally
generated keypair. Neither is committed.

SSH to backend:
```bash
ssh -J ubuntu@<frontend-public-ip> ubuntu@<backend-private-ip>
```

## Layout
```
bootstrap/ S3 state bucket, local state, applied once
./ VPC, subnets, routing, SGs, EC2, NAT
```
## Decisions

- `for_each` over a keyed map for subnets, not `count`
- CIDRs derived with `cidrsubnet()`; `validation` rejects an undersized VPC
- SSH keypair generated with `ssh-keygen`; Terraform manages the public key
  only — `tls_private_key` would put the private key in state
- One NAT, not one per AZ. `private-b` routes cross-AZ. Production wouldn't.

## Roadmap

- [ ] Second backend instance in `private-b`
- [ ] Flask backend proxied through nginx
- [ ] Modules (`network`, `compute`)
- [ ] Ansible, lifting config out of `user_data`