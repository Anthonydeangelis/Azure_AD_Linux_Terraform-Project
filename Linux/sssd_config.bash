#!/bin/bash
# ============================================================================
# SSSD (System Security Services Daemon) Configuration
# ============================================================================
# Purpose: Configure SSSD for Active Directory authentication and user login
# This enables AD users to log in to the Linux system using their AD credentials
# ============================================================================

# SECTION 1: Edit and Configure SSSD
# ============================================================================
# Open the SSSD configuration file for editing
sudo nano /etc/sssd/sssd.conf

# SSSD Configuration Content:
# [sssd]
#   domains = antsdomain.local               # Configured domain
#   config_file_version = 2                  # Configuration file version
#   services = nss, pam                      # Enable NSS and PAM services
#
# [domain/antsdomain.local]
#   ## FIX FOR SSSD AND WINBIND ISSUES 
#   dyndns_update = false
#   default_shell = /bin/bash                # Default shell for AD users
#   krb5_store_password_if_offline = True    # Cache passwords for offline use
#   cache_credentials = True                 # Cache user credentials locally
#   krb5_realm = ANTSDOMAIN.LOCAL            # Kerberos realm name
#   realmd_tags = manages-system joined-with-adcli  # Tags from realm join
#   id_provider = ad                         # Use Active Directory for IDs
#   fallback_homedir = /home/%u@%d           # Home directory template
#   ad_domain = antsdomain.local             # AD domain name
#   use_fully_qualified_names = False        # Don't require domain in usernames
#   ldap_id_mapping = True                   # Use LDAP ID mapping
#   access_provider = ad                     # Use AD for access control

# SECTION 2: Set Permissions and Restart SSSD
# ============================================================================
# Set restrictive permissions on SSSD config (sensitive credentials)
sudo chmod 600 /etc/sssd/sssd.conf

# Restart SSSD service to apply configuration changes
sudo systemctl restart sssd

# Check SSSD service status (should show active/running)
sudo systemctl status sssd

# SECTION 3: Enable Home Directory Creation
# ============================================================================
# Enable pam_mkhomedir to automatically create home directories for AD users on first login
sudo pam-auth-update --enable mkhomedir

# SECTION 4: Test AD User Login
# ============================================================================
# SSH into the system with an AD user account (example: jdoe)
# Command: ssh jdoe@linux-srv-01
# Password: Use the AD user's password
#
# After successful login, verify the home directory was created:
jdoe@linux-srv-01:~$ pwd
# Expected output: /home/jdoe@antsdomain.local
# This confirms the AD user is properly authenticated and home directory was created