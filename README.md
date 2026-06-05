# Azure HomeLab — Enterprise Network Simulation

A fully automated, Infrastructure-as-Code Azure homelab simulating a real corporate network environment. Built to develop hands-on skills in cloud networking, Active Directory administration, Linux systems management, and DevOps practices.

---

## Project Overview

This project provisions and configures a segmented Azure virtual network containing a Windows Server 2022 domain controller and an Ubuntu Linux server. All infrastructure is defined in Terraform and deployed via a GitHub Actions CI/CD pipeline. The environment mirrors patterns used in real enterprise environments — AD-integrated authentication, Samba file sharing, network segmentation, and automated infrastructure delivery.

---

## Architecture

<img src="architecture.svg" alt="Architecture Diagram" width="100%"/>

```
Azure Resource Group — antsdomain-rg
└── Virtual Network — 10.0.0.0/16
    ├── NSG — RDP/SSH locked to home IP · SMB internal only
    ├── Management Subnet — 10.0.1.0/24
    │   └── win-mgmt-01 (Windows Server 2022)
    │       ├── Active Directory Domain Services
    │       ├── DNS Server
    │       ├── Kerberos / LDAP
    │       └── AD Groups: LinuxShareUsers · DL-LinuxShare-RW (AGDLP model)
    └── Services Subnet — 10.0.2.0/24
        └── linux-srv-01 (Ubuntu Server 22.04)
            ├── sssd — AD authentication for Linux logins
            ├── Samba (smbd) — AD-authenticated file share
            ├── winbind — Samba group resolution
            └── UFW — host-level firewall
```

---

## Technology Stack

| Category | Technology |
|---|---|
| Cloud | Microsoft Azure (Student Subscription) |
| IaC | Terraform |
| CI/CD | GitHub Actions |
| Identity | Active Directory Domain Services |
| OS | Windows Server 2022 · Ubuntu 22.04 LTS |
| File Sharing | Samba (SMB protocol) |
| AD Integration | sssd · winbind · realmd · Kerberos |
| Firewall | Azure NSG · UFW |
| Scripting | PowerShell · Bash |

---

## Infrastructure — Terraform

All Azure resources are provisioned using Terraform with remote state stored in an Azure Blob Storage container.

**Resources provisioned:**
- Resource group
- Virtual network with two subnets (management + services)
- Network security group with custom inbound rules
- Two virtual machines with public IPs
- Azure Key Vault for secret storage

**CI/CD pipeline** (`.github/workflows/terraform.yml`) automates:
- `terraform fmt` — enforces code formatting on every push
- `terraform plan` — runs a dry-run on every pull request
- `terraform apply` — applies changes only when merged to `main`

Backend configuration and all sensitive values (credentials, passwords, IP addresses) are stored as GitHub Actions secrets and injected at runtime — no secrets are stored in the repository.

---

## Active Directory — Windows Server 2022

The domain controller runs Active Directory Domain Services for the `antsdomain.local` domain, managed entirely via PowerShell.

**Domain configuration:**
- Domain: `antsdomain.local`
- Forest/Domain functional level: Windows Server 2016
- DNS integrated with AD

**Group structure follows the AGDLP model:**

```
DL-LinuxShare-RW (Domain Local) ← assigned permissions on Samba share
    └── LinuxShareUsers (Global) ← contains user accounts
            ├── anthonyadmin
            └── jdoe
```

The AGDLP (Accounts → Global → Domain Local → Permissions) model is the Microsoft-recommended approach for access control. Permissions are assigned once to the Domain Local group. Adding or removing users from the Global group is all that's needed to grant or revoke share access — the share itself never needs to be touched.

**PowerShell used for:**
- AD DS installation and domain promotion
- OU, user, and group creation
- Group nesting and membership management
- DNS verification

---

## Linux Server — Ubuntu 22.04 LTS

The Linux VM is domain-joined to `antsdomain.local` and provides an AD-authenticated Samba file share.

### Domain Join

The domain join process required configuring:
- `systemd-resolved` — pointed at DC (`10.0.1.4`) for DNS
- `/etc/krb5.conf` — Kerberos configuration with `rdns = false` to prevent reverse DNS lookup failures against Azure's internal DNS
- `realmd` + `adcli` — used to perform the domain join
- `net ads join` — separately registered Samba's machine account in AD

**Key troubleshooting learned:**
- Azure VMs default to `168.63.x.x` for DNS — must be overridden to point at the DC
- Kerberos reverse DNS lookups fail in Azure because PTR records return Azure internal hostnames rather than AD FQDNs — resolved with `rdns = false`
- `realm join` configures sssd but does NOT set up Samba's machine account — `net ads join` must be run separately

### sssd — AD Authentication for Linux

sssd enables AD users to log into the Linux VM via SSH. On first login, `mkhomedir` automatically creates the user's home directory with correct ownership pulled from AD.

```
jdoe SSHes in → PAM → sssd → AD DC → home dir created → login succeeds
```

Configuration: `/etc/sssd/sssd.conf`

### Samba — AD-Authenticated File Share

Samba provides a file share (`\\10.0.2.5\shared`) accessible from Windows machines. Authentication is handled via Kerberos and winbind, with access controlled by the `DL-LinuxShare-RW` AD group.

**Service responsibilities:**
| Service | Purpose |
|---|---|
| `sssd` | Linux OS authentication (SSH logins) |
| `smbd` | SMB protocol file server |
| `winbind` | Samba → AD group resolution |
| `nmbd` | NetBIOS name resolution |

sssd and winbind serve different purposes and must both run simultaneously — sssd for Linux logins, winbind for Samba share authentication. They are configured to not conflict via `/etc/sssd/sssd.conf` and `/etc/nsswitch.conf`.

**Share access control — two layers:**

1. Samba (`smb.conf`) — only members of `DL-LinuxShare-RW` can connect
2. Linux filesystem (`chmod 2770`) — enforces permissions at the OS level regardless of client

**Share configuration:** `/etc/samba/smb.conf`

### UFW Firewall

Host-level firewall configured in addition to the Azure NSG (defence in depth):

```
Port 22  (SSH) → allowed from home IP only
Port 445 (SMB) → allowed from 10.0.1.0/24 (management subnet) only
All other inbound → denied
```

---

## Security Practices

| Practice | Implementation |
|---|---|
| No public RDP/SSH | Locked to home IP via NSG + UFW |
| No secrets in code | All secrets in GitHub Actions + Azure Key Vault |
| Least privilege file access | AD group controls share access, filesystem enforces permissions |
| Defence in depth | Azure NSG + UFW host firewall on both VMs |
| IaC only | All infrastructure defined in Terraform, no manual portal changes |
| AD group model | AGDLP — permissions assigned to groups, never individual users |

---

## CI/CD Pipeline

The GitHub Actions pipeline (`.github/workflows/terraform.yml`) automates infrastructure delivery:

```
Push to feature branch
        ↓
Open Pull Request → fmt check + plan runs automatically
        ↓
Review plan output in PR
        ↓
Merge to main → apply runs and updates Azure infrastructure
```

All sensitive values injected at runtime from GitHub Actions secrets:
- `AZURECRED` — Azure service principal (JSON)
- `TF_RG` / `TF_STORAGE` / `TF_CONTAINER` / `TF_KEY` — Terraform backend config
- `TF_VM_PASSWORD` / `TF_ADMIN_USERNAME` / `TF_MY_IP` — Terraform input variables

---

## Repository Structure

```
azure-homelab/
├── .github/
│   └── workflows/
│       └── terraform.yml       # CI/CD pipeline
├── Terraform/
│   ├── main.tf                 # Resource group, core resources
│   ├── network.tf              # VNet, subnets, NSG, route tables
│   ├── compute.tf              # Virtual machines, public IPs
│   ├── providers.tf            # Azure provider configuration
│   └── variables.tf            # Input variable definitions
└── README.md
```

---

## Skills Demonstrated

- **Cloud networking** — VNet design, subnet segmentation, NSG rules, UDRs (AZ-104)
- **Infrastructure as Code** — Terraform modules, remote state, CI/CD automation
- **Active Directory** — domain promotion, OU design, AGDLP group model, PowerShell administration
- **Linux administration** — domain join, Kerberos configuration, service management, file permissions, bash troubleshooting
- **Samba** — AD-integrated file sharing, smb.conf configuration, winbind/sssd coexistence
- **DevOps** — GitHub Actions, secret management, automated infrastructure delivery
- **Security** — defence in depth, least privilege, no secrets in code, network segmentation