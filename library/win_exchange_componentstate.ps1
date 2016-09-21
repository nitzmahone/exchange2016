#!powershell

# POWERSHELL_COMMON
# WANTS_JSON

Set-StrictMode -Version 2
$ErrorActionPreference = "Stop"

$parsed_args = Parse-Args $args

$result = @{changed=$false}

$component_name = Get-AnsibleParam $parsed_args "component" -default "ServerWideOffline"
$state = Get-AnsibleParam $parsed_args "state" -failifempty $result -validateset "active","inactive"

$cu = "http://$($env:COMPUTERNAME).$($env:USERDNSDOMAIN)/Powershell"

Try {
  $gcs_result = Invoke-Command -ConnectionUri $cu -Authentication Kerberos -ConfigurationName Microsoft.Exchange -ScriptBlock { Get-ServerComponentState -Identity $args[0] } -Args $env:COMPUTERNAME,$component_name

  $current_state = $gcs_result.State
  
  If($current_state -ne $state) {
    $scs_result = Invoke-Command -ConnectionUri $cu -Authentication Kerberos -ConfigurationName Microsoft.Exchange -ScriptBlock { Set-ServerComponentState -Identity $args[0] -Component $args[1] -State $args[2] -Requester Maintenance } -Args $env:COMPUTERNAME,$component_name,$state
    $result.changed = $true
  }
}
Catch {
  $result = @{failed=$true; msg="Exchange Management unavailable: $_"}
}

ConvertTo-Json $result -Depth 99

