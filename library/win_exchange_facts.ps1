#!powershell

Set-StrictMode -Version 2
$ErrorActionPreference = "Stop"

$cu = "http://$($env:COMPUTERNAME).$($env:USERDNSDOMAIN)/Powershell"

Try {
  $ges_result = Invoke-Command -ConnectionUri $cu -Authentication Kerberos -ConfigurationName Microsoft.Exchange -ScriptBlock { Get-ExchangeServer }
  $cs_result = Invoke-Command -ConnectionUri $cu -Authentication Kerberos -ConfigurationName Microsoft.Exchange -ScriptBlock { Get-ServerComponentState -Identity $args[0] } -Args $env:COMPUTERNAME
  $formatted_cs = @{}
  $cs_result | Foreach-Object { $formatted_cs[$_.Component] = @{State=$_.State} }

  $res = @{ansible_facts=@{exchange_facts=$ges_result; component_states=$formatted_cs}}

}
Catch {
  $res = @{failed=$true; msg="Exchange Management unavailable: $_"}
}

ConvertTo-Json $res -Depth 99

