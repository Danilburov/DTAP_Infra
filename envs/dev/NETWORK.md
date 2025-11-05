## DTAP dev Network Overview

This document explains the DTAP dev network topology created by the Terraform in this folder.

### High-level
- **Region**: eu-central-1
- **VPC**: `DTAP-vpc` CIDR `10.0.0.0/16` (DNS hostnames/support enabled)
- **AZs used**: first two available in region
  - `az_a` = `data.aws_availability_zones.this.names[0]`
  - `az_b` = `data.aws_availability_zones.this.names[1]`

### Subnets
- Public (internet-routable via IGW)
  - `DTAP-public-a` `10.0.1.0/24` in `az_a` (map_public_ip_on_launch)
  - `DTAP-public-b` `10.0.11.0/24` in `az_b` (map_public_ip_on_launch)

- Private - App tier (for EC2 ASG behind ALB)
  - `DTAP-app-a` `10.0.2.0/24` in `az_a`
  - `DTAP-app-b` `10.0.12.0/24` in `az_b`

- Private - Data tier (for RDS)
  - `DTAP-data-a` `10.0.3.0/24` in `az_a`
  - `DTAP-data-b` `10.0.13.0/24` in `az_b`

- Private - Monitoring
  - `DTAP-monitoring-a` `10.0.50.0/24` in `az_a`

### Internet and NAT
- Internet Gateway: `DTAP-igw` attached to the VPC
- NAT Gateway: `DTAP-nat` in `DTAP-public-a` with EIP `DTAP-nat-eip`
  - Private subnets reach the internet via the NAT (for OS/package updates, image pulls, etc.)

### Route Tables
- Public route table: `DTAP-dtap-rt-public`
  - Default route `0.0.0.0/0 -> IGW`
  - Associated with: `DTAP-public-a`, `DTAP-public-b`

- Private route table: `DTAP-dtap-rt-private`
  - Default route `0.0.0.0/0 -> NAT`
  - Associated with: `DTAP-app-a`, `DTAP-app-b`, `DTAP-data-a`, `DTAP-data-b`, `DTAP-monitoring-a`

### Load Balancing and Compute
- ALB: `DTAP-app-alb` (internet-facing) in public subnets A/B
- Target Group: `DTAP-app-tg` HTTP:80
- ASG: `DTAP-asg` in private app subnets A/B
- App instances tagged `Name=DTAP-app`, IMDSv2 required

### Security Groups (key ports)
- `DTAP-alb-sg`
  - In: 80/tcp from `0.0.0.0/0` (and `::/0`)
  - Out: all

- `DTAP-app-sg`
  - In: 80/tcp from `DTAP-alb-sg`
  - In: 9100/tcp from `DTAP-monitoring-sg` (node_exporter)
  - Out: all

- `DTAP-rds-sg`
  - In: 5432/tcp from `DTAP-app-sg`
  - Out: all

- `DTAP-monitoring-sg`
  - In: 3000/tcp (Grafana) from VPN `10.8.0.0/24` and `DTAP-vpn-sg`
  - In: 9090/tcp (Prometheus) from VPN `10.8.0.0/24` and `DTAP-vpn-sg`
  - In: 22/tcp from `DTAP-vpn-sg`
  - Out: all

- `DTAP-vpn-sg`
  - In: 1194/udp from `0.0.0.0/0`
  - In: 22/tcp from `var.my_ip_cidr` (default open, recommend restrict)
  - Out: all

### Name Resolution
- Private Route53 zone: `intra.local` associated to the VPC
- Record: `app.intra.local` (A/alias) -> ALB

### Databases
- RDS Postgres `DTAP-db` (single-AZ, `db.t3.micro` by default)
- DB subnet group spans `DTAP-data-a` and `DTAP-data-b`

### Monitoring
- Instance in `DTAP-monitoring-a`, no public IP
- Runs Dockerized Prometheus (9090) and Grafana (3000)
- Prometheus uses EC2 service discovery and filters instances tagged `Name=DTAP-app` and `state=running`, scraping `:9100`

### VPN
- Ubuntu-based OpenVPN in `DTAP-public-a` with an Elastic IP
- SG and user data allow quick non-interactive install
- Config pushes VPC DNS `10.0.0.2` to clients

### Quick reference (CIDRs)
```
VPC            10.0.0.0/16
Public A       10.0.1.0/24
Public B       10.0.11.0/24
Private App A  10.0.2.0/24
Private App B  10.0.12.0/24
Private Data A 10.0.3.0/24
Private Data B 10.0.13.0/24
Monitoring A   10.0.50.0/24
```

### Notes / Tips
- Consider moving RDS to `gp3` storage for cost/performance.
- Restrict `var.my_ip_cidr` for SSH to VPN.
- NAT GW lives only in AZ A; if you need higher resilience for egress, consider a NAT per AZ.


