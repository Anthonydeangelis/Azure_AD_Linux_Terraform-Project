 Test-NetConnection -ComputerName 10.0.2.5 -Port 445


ComputerName     : 10.0.2.5
RemoteAddress    : 10.0.2.5
RemotePort       : 445
InterfaceAlias   : Ethernet
SourceAddress    : 10.0.1.4
TcpTestSucceeded : True


New-PSDrive -Name Z -PSProvider FileSystem -Root "\\10.0.2.5\shared" -Credential (Get-Credential)

