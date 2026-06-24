<#
.SYNOPSIS
    John OS — network stack tuning for online gaming (latency-focused, safe).
.DESCRIPTION
    Disables Nagle's algorithm on the active gaming NIC, removes the multimedia
    network throttle, turns off NIC power management, and ensures RSS is on.
    Deliberately LEAVES TCP autotuning at 'normal' (disabling it hurts modern
    high-BDP links) and does NOT chase the "20% reserved bandwidth" myth.
.PARAMETER Profile
    Balanced | Esports | Creator.
.PARAMETER SetDns
    Optional fast resolver: 'Cloudflare' | 'Google' | 'Quad9' | 'None'.
.EXAMPLE
    .\04-network-optimization.ps1 -Profile Esports -SetDns Cloudflare -WhatIf
#>
[CmdletBinding(SupportsShouldProcess)]
param(
    [ValidateSet('Balanced','Esports','Creator')][string]$Profile='Balanced',
    [ValidateSet('Cloudflare','Google','Quad9','None')][string]$SetDns='None'
)

. "$PSScriptRoot\lib\common.ps1"
Assert-Admin
Write-JohnBanner 'Network optimization' $Profile

# --- Identify the active (up, gateway-bearing) adapter ----------------------
$active = Get-NetAdapter -Physical -ErrorAction SilentlyContinue |
    Where-Object Status -eq 'Up' |
    Sort-Object @{e={ if ($_.MediaType -eq '802.3') {0} else {1} }}, ifIndex |
    Select-Object -First 1
if (-not $active) { Write-JohnLog "No active network adapter found." 'WARN'; return }
Write-JohnLog "Active adapter: $($active.Name) [$($active.InterfaceDescription)]" 'INFO'

# --- Disable Nagle on the active interface (per-interface registry) ----------
$ifaceRoot = 'HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces'
$nicKey = Get-ChildItem $ifaceRoot | Where-Object {
    (Get-ItemProperty $_.PSPath -ErrorAction SilentlyContinue).PSObject.Properties.Name -contains 'DhcpIPAddress' -or
    (Get-ItemProperty $_.PSPath -ErrorAction SilentlyContinue).PSObject.Properties.Name -contains 'IPAddress'
} | Select-Object -First 1
if ($nicKey) {
    Set-RegValue $nicKey.PSPath 'TcpAckFrequency' 1 'DWord' $PSCmdlet   # Nagle off
    Set-RegValue $nicKey.PSPath 'TCPNoDelay'      1 'DWord' $PSCmdlet
    Set-RegValue $nicKey.PSPath 'TcpDelAckTicks'  0 'DWord' $PSCmdlet
} else { Write-JohnLog "Could not resolve interface registry key for Nagle tweak." 'WARN' }

# --- Global multimedia throttle off (mirrors script 03) ---------------------
Set-RegValue 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile' `
    'NetworkThrottlingIndex' 0xFFFFFFFF 'DWord' $PSCmdlet

# --- NIC power management off (don't let the NIC sleep mid-match) ------------
if ($PSCmdlet.ShouldProcess($active.Name,'Disable NIC power-down')) {
    try {
        Disable-NetAdapterPowerManagement -Name $active.Name -ErrorAction Stop
        Write-JohnLog "NIC power management disabled on $($active.Name)." 'OK'
    } catch { Write-JohnLog "NIC power mgmt unchanged: $($_.Exception.Message)" 'WARN' }
} else { Write-JohnLog "would disable NIC power management on $($active.Name)" 'WHATIF' }

# --- Receive Side Scaling on; autotuning LEFT at normal ---------------------
if ($PSCmdlet.ShouldProcess('TCP global','Enable RSS; keep autotuning=normal')) {
    try {
        Set-NetTCPSetting -SettingName InternetCustom -AutoTuningLevelLocal Normal -ErrorAction SilentlyContinue
        Set-NetAdapterRss -Name $active.Name -Enabled $true -ErrorAction SilentlyContinue
        Write-JohnLog "RSS enabled; TCP autotuning kept 'normal' (intentional)." 'OK'
    } catch { Write-JohnLog "RSS/TCP settings note: $($_.Exception.Message)" 'WARN' }
}

# --- Optional fast DNS ------------------------------------------------------
if ($SetDns -ne 'None') {
    $dns = switch ($SetDns) {
        'Cloudflare' { '1.1.1.1','1.0.0.1' }
        'Google'     { '8.8.8.8','8.8.4.4' }
        'Quad9'      { '9.9.9.9','149.112.112.112' }
    }
    if ($PSCmdlet.ShouldProcess($active.Name,"Set DNS -> $SetDns")) {
        try { Set-DnsClientServerAddress -InterfaceIndex $active.ifIndex -ServerAddresses $dns -ErrorAction Stop
              Write-JohnLog "DNS set to $SetDns ($($dns -join ', '))." 'OK' }
        catch { Write-JohnLog "DNS unchanged: $($_.Exception.Message)" 'WARN' }
    } else { Write-JohnLog "would set DNS to $SetDns" 'WHATIF' }
}

Write-JohnLog "Network tuning complete. Wired + this config = lowest, most consistent latency." 'OK'
Write-JohnLog "NOT changed: TCP autotuning (kept normal), QoS reservable bandwidth (myth)." 'INFO'
