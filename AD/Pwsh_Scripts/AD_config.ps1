# ============================================================================
# Active Directory Configuration Script
# ============================================================================
# Purpose: Set up Active Directory with SSH access, DNS, and Samba integration
# This script configures a Windows Server as an AD domain controller
# ============================================================================

# SECTION 1: SSH Configuration
# ============================================================================
# Ensure SSH service is running on the domain controller
Get-Service sshd

# Allow SSH on Windows Firewall (required for remote access)
New-NetFirewallRule `
  -Name "Allow SSH" `
  -DisplayName "Allow SSH" `
  -Protocol TCP `
  -Direction Inbound `
  -LocalPort 22 `
  -Action Allow



# SECTION 2: Active Directory Installation
# ============================================================================
# Check if AD-Domain-Services feature is available
Get-WindowsFeature AD-Domain-Services

# Install Active Directory Domain Services with management tools
Install-WindowsFeature AD-Domain-Services -IncludeManagementTools

# Import the AD Deployment module
Import-Module ADDSDeployment

# Install and configure a new AD forest for the domain
# Note: This will restart the server after completion
Install-ADDSForest `
  -DatabasePath "C:\Windows\NTDS" `
  -LogPath "C:\Windows\NTDS" `
  -SysvolPath "C:\Windows\SYSVOL" `
  -DomainName "antsdomain.local" `
  -DomainNetbiosName "antsdomain" `
  -InstallDns `
  -Force

# Verify AD installation by checking domain and forest configuration
Get-ADDomain
Get-ADForest
# List all users in the domain
Get-ADUser -Filter *

# SECTION 3: Create Security Groups for Linux/Samba Integration
# ============================================================================
# Create a global security group for Linux file share access
New-ADGroup -Name "LinuxShareUsers" -GroupScope Global -GroupCategory Security

# Add specific users to the LinuxShareUsers group
$users = "jdoe", "anthonyadmin"
Add-ADGroupMember "LinuxShareUsers" -Members $users

# Create a domain local group for Read-Write permissions on Linux shares
# DomainLocal groups are best for assigning permissions to resources
New-ADGroup -Name "DL-LinuxShare-RW" -GroupScope DomainLocal -GroupCategory Security

# Add the global group to the domain local group (nesting groups for better management)
Add-ADGroupMember "DL-LinuxShare-RW" -Members "LinuxShareUsers"

# Verify all members in the domain local group
Get-ADGroupMember "DL-LinuxShare-RW"                                                

