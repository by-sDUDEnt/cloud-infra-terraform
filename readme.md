# AWS Two-Tier VPC — Terraform

Two-tier AWS network provisioned entirely as code. Public subnet fronts the internet; private subnet is reachable only through a bastion and reaches out only through NAT. Remote state in S3 with locking, versioning, and encryption.

No manual console clicks — the whole stack comes up from `terraform apply`, including instance configuration.

## Architecture

```
                       Internet
                          │
                    ┌─────▼─────┐
                    │    IGW    │
                    └─────┬─────┘
                          │
        ┌─────────────────▼──────────────────┐
        │  VPC  10.0.0.0/16   (eu-north-1)   │
        │                                    │
        │  public-a   10.0.0.0/24  (1a)      │
        │    ├── EC2  frontend / bastion     │
        │    │        nginx, public IP       │
        │    └── NAT gateway + EIP           │
        │                                    │
        │  private-a  10.0.1.0/24  (1a)      │
        │    └── EC2  backend                │
        │             no public IP           │
        │                                    │
        │  private-b  10.0.2.0/24  (1b)      │
        └────────────────────────────────────┘
```

**Routing.** The public route table sends `0.0.0.0/0` to the internet gateway — that route, and nothing else, is what makes a subnet public. The private route table sends `0.0.0.0/0` to the NAT gateway: outbound only. Nothing from the internet has a path in.

**Security groups.** The backend does not trust a CIDR range — it trusts the frontend's *security group*. SG-referencing-SG means the rule survives the frontend being rebuilt with a new address, and it means nothing else in the VPC can reach the backend regardless of subnet.

**Access.** The frontend doubles as a bastion. SSH to the backend goes through it via `ProxyJump`, so the private key never leaves the local machine:

```bash
ssh -J ubuntu@<frontend-public-ip> ubuntu@<backend-private-ip>
```

## State

State lives in S3: versioned (so a corrupt write is recoverable), encrypted (state holds secrets in plaintext), and locked (so two applies can't race and silently overwrite each other's records).

The bucket is created by a separate `bootstrap/` config with its own local state. That solves the chicken-and-egg problem — a backend bucket managed inside the config it backs would be destroyed by its own `terraform destroy`.

## Layout

```
bootstrap/     S3 state bucket. Local state. Applied once.
./         VPC, subnets, routing, security groups, EC2, NAT.
```

## Usage

```bash
# once
cd bootstrap
terraform init && terraform apply

# the stack
terraform init -backend-config=state.config
terraform plan
terraform apply

terraform destroy      # NAT gateway bills hourly — destroy when idle
```

Requires a `terraform.tfvars` with `my_ip` (your `/32`, for the SSH ingress rule) and an SSH keypair generated locally — Terraform manages only the public key. Neither is committed.

## Notes on design

- **Subnets** are generated with `for_each` over a stable-keyed map, not `count` — so reordering or removing one doesn't shift every index after it and force needless recreation.
- **CIDRs** are derived from the VPC block with `cidrsubnet()` rather than hardcoded, so changing the base cascades correctly. A `validation` block on `var.vpc_cidr` rejects a VPC too small to carve.
- **Secrets stay out of state.** The SSH keypair is generated with `ssh-keygen` and Terraform manages only the public key via `aws_key_pair`. Generating it with `tls_private_key` would write the private key into state in plaintext.
- **One NAT gateway, not one per AZ.** Deliberate cost trade: `private-b` routes cross-AZ, which is cheaper but couples it to `1a`'s availability. Production would run one per AZ.

## Roadmap

- [ ] Cross-AZ backend deployment (second instance in `private-b`)
- [ ] Flask app on the backend, proxied through nginx on the frontend
- [ ] Refactor into modules (`network`, `compute`) once boundaries are stable
- [ ] Ansible for instance configuration, lifting it out of `user_data`