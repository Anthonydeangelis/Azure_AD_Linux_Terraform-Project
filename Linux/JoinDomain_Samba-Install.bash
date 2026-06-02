#!/bin/bash
# ============================================================================
# Linux Domain Join and Samba Installation Script
# ============================================================================
# Purpose: Configure a Linux system to join an Active Directory domain
#          and set up Samba/SSSD for AD authentication
# Domain: antsdomain.local
# ============================================================================

# SECTION 1: Network Configuration
# ============================================================================
# Configure netplan to use the AD domain controller as DNS server
network:
  version: 2
  ethernets:
    eth0:
      match:
        macaddress: "7c:1e:52:ec:11:69"        # Physical network interface
        driver: "hv_netvsc"                     # Hyper-V network driver
      dhcp4: true                               # Use DHCP for IPv4
      nameservers:
        addresses:
          - 10.0.1.4                            # AD domain controller IP
        search:
          - antdomain.local                     # Primary search domain
      dhcp4-overrides:
        route-metric: 100                       # Override DHCP-provided DNS
      dhcp6: false                              # Disable IPv6 DHCP
      set-name: "eth0"                         # Interface name

# Apply network configuration changes
sudo netplan apply

# SECTION 2: DNS Resolution Setup
# ============================================================================
# Restart systemd-resolved to apply new DNS settings
sudo systemctl restart systemd-resolved

# Flush DNS caches to force resolution of new servers
sudo resolvectl flush-caches

# Verify DNS configuration and currently configured servers
resolvectl status
# Expected output shows:
# - Current DNS Server: 10.0.1.4 (AD domain controller)
# - DNS Domain: antsdomain.local reddog.microsoft.com

# SECTION 3: Install Required Packages
# ============================================================================
# Update system package lists
sudo apt update && sudo apt upgrade -y

# Install all required packages for AD integration and Samba:
# - realmd: Simplifies realm joining
# - sssd: System Security Services Daemon for AD auth
# - sssd-tools: Utility tools for SSSD
# - samba: SMB/CIFS file sharing protocol
# - samba-common-bin: Common Samba utilities
# - krb5-user: Kerberos 5 authentication
# - winbind: Maps Windows users to UNIX users
# - libnss-winbind: NSS module for Winbind
# - libpam-winbind: PAM module for Winbind
# - packagekit: Package management tool
sudo apt install -y realmd sssd sssd-tools samba samba-common-bin krb5-user winbind libnss-winbind libpam-winbind packagekit
# When prompted for Kerberos realm, enter: ANTSDOMAIN.LOCAL (uppercase)

# SECTION 4: Configure Kerberos
# ============================================================================
# Edit Kerberos configuration file
sudo nano /etc/krb5.conf

# Kerberos configuration content:
# [libdefaults]
#     default_realm = ANTSDOMAIN.LOCAL
#     dns_lookup_realm = false          # Don't query DNS for realm info
#     dns_lookup_kdc = true             # Find KDC via DNS SRV records
#     rdns = false                      # Disable reverse DNS lookups
#
# [realms]
#     ANTSDOMAIN.LOCAL = {              # Define the Kerberos realm
#         kdc = win-mgmt-01.antsdomain.local           # Key Distribution Center
#         admin_server = win-mgmt-01.antsdomain.local  # Admin server
#     }
#
# [domain_realm]
#     .antsdomain.local = ANTSDOMAIN.LOCAL
#     antsdomain.local = ANTSDOMAIN.LOCAL

# SECTION 5: Join the Active Directory Domain
# ============================================================================
# Use realm to join the domain
# Requires an AD account with domain join permissions (anthonyadmin in this case)
sudo realm join --user=anthonyadmin antsdomain.local -v
# -v flag enables verbose output for troubleshooting

# SECTION 6: Verify Domain Join
# ============================================================================
# List configured realms and their status
realm list
# Expected output:
# antsdomain.local
#   type: kerberos
#   realm-name: ANTSDOMAIN.LOCAL
#   domain-name: antsdomain.local
#   configured: kerberos-member
#   server-software: active-directory
#   client-software: sssd
#   login-formats: %U@antsdomain.local

# Verify the computer account was created in AD (run on domain controller)
# Get-ADComputer -Filter *
# Should show: LINUX-SRV-01 with ObjectClass: computer


DistinguishedName : CN=win-mgmt-01,OU=Domain 
                    Controllers,DC=antsdomain,DC=local
DNSHostName       : win-mgmt-01.antsdomain.local
Enabled           : True
Name              : win-mgmt-01
ObjectClass       : computer
ObjectGUID        : ef66e824-98bb-4eb5-8b28-7148815c9a5e
SamAccountName    : win-mgmt-01$
SID               : S-1-5-21-3998762621-3624424612-2764397256-1000
UserPrincipalName : 

DistinguishedName : CN=LINUX-SRV-01,CN=Computers,DC=antsdomain,DC=local
DNSHostName       : linux-srv-01
Enabled           : True
Name              : LINUX-SRV-01
ObjectClass       : computer
ObjectGUID        : 298a0f16-2b89-4d5f-9852-bbb8775665cd
SamAccountName    : LINUX-SRV-01$
SID               : S-1-5-21-3998762621-3624424612-2764397256-1601
UserPrincipalName : 
