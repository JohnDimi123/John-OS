<#
.SYNOPSIS
    John OS — power plan (Ultimate Performance on AC, balanced on battery).
.DESCRIPTION
    Imports + selects the Ultimate Performance plan, unparks cores, disables USB
    selective suspend and PCIe ASPM, and pins CPU state. On laptops it ONLY pins
    aggressive settings on AC and keeps a balanced DC profile.
.PARAMETER Profile
    Balanced | Esports | Creator. Esports pins CPU min to 100%.
.EXAMPLE
    .\05-power-plan.ps1 -Profile Esports -WhatIf
#>
[CmdletBinding(SupportsShouldProcess)]
param([ValidateSet('Balanced','Esports','Creator')][string]$Profile='Balanced')

. "$PSScriptRoot\lib\common.ps1"
Assert-Admin
Write-JohnBanner 'Power plan' $Profile

$ultimateGuid = 'e9a42b02-d5df-448d-aa00-03f14749eb61'
$isLaptop = Test-IsLaptop
if ($isLaptop) { Write-JohnLog "Laptop detected: aggressive settings apply to AC only; DC stays balanced." 'INFO' }

# --- Ensure Ultimate Performance exists, then select it ---------------------
if ($PSCmdlet.ShouldProcess('Ultimate Performance','Import + activate power scheme')) {
    $existing = (powercfg /list) -match 'Ultimate Performance'
    if (-not $existing) { powercfg -duplicatescheme $ultimateGuid *>$null }
    $line = (powercfg /list | Select-String 'Ultimate Performance' | Select-Object -First 1).ToString()
    if ($line -match '([0-9a-fA-F-]{36})') {
        $active = $Matches[1]
        powercfg /setactive $active *>$null
        Write-JohnLog "Active scheme -> Ultimate Performance ($active)." 'OK'
    } else { Write-JohnLog "Could not parse Ultimate Performance GUID; leaving current scheme." 'WARN'; $active = 'SCHEME_CURRENT' }
} else { Write-JohnLog "would import/activate Ultimate Performance" 'WHATIF'; $active = $null }

function Set-Pc([string]$sub,[string]$setting,[int]$ac,[int]$dc,[string]$desc){
    if (-not $active) { Write-JohnLog "would set $desc (AC=$ac DC=$dc)" 'WHATIF'; return }
    if ($PSCmdlet.ShouldProcess($desc,"AC=$ac DC=$dc")) {
        powercfg /setacvalueindex $active $sub $setting $ac *>$null
        powercfg /setdcvalueindex $active $sub $setting $dc *>$null
        Write-JohnLog "$desc -> AC=$ac DC=$dc" 'OK'
    }
}

# GUIDs (well-known powercfg subgroup/setting aliases)
$SUB_PROCESSOR = 'SUB_PROCESSOR'
$SUB_USB       = '2a737441-1930-4402-8d77-b2bebba308a3'
$USB_SUSPEND   = '48e6b7a6-50f5-4782-a5d4-53bb8f07e226'
$SUB_PCI       = '501a4d13-42af-4429-9fd1-a8218c268e20'
$ASPM          = 'ee12f906-d277-404b-b6da-e5fa1a576df5'
$SUB_DISK      = 'SUB_DISK'

# CPU min state: Esports pins 100% on AC; Balanced/Creator allow idle down-clock.
$cpuMinAc = if ($Profile -eq 'Esports') { 100 } else { 5 }
Set-Pc $SUB_PROCESSOR 'PROCTHROTTLEMIN' $cpuMinAc 5  'CPU minimum state'
Set-Pc $SUB_PROCESSOR 'PROCTHROTTLEMAX' 100      ($(if($isLaptop){80}else{100})) 'CPU maximum state'
Set-Pc $SUB_PROCESSOR 'CPMINCORES'      100      100 'Core parking (min cores)'
Set-Pc $SUB_USB       $USB_SUSPEND      0        ($(if($isLaptop){1}else{0})) 'USB selective suspend (0=off)'
Set-Pc $SUB_PCI       $ASPM             0        ($(if($isLaptop){2}else{0})) 'PCIe ASPM (0=off)'
Set-Pc $SUB_DISK      'DISKIDLE'        0        1200 'Hard disk turn-off (sec; 0=never on AC)'

if ($active -and $PSCmdlet.ShouldProcess($active,'Apply scheme changes')) { powercfg /setactive $active *>$null }

Write-JohnLog "Power plan complete. On laptops, DC remains battery-friendly." 'OK'
