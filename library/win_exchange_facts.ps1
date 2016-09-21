#!powershell

Set-StrictMode -Version 2
$ErrorActionPreference = "Stop"

$cu = "http://$($env:COMPUTERNAME).$($env:USERDNSDOMAIN)/Powershell"

Try {
  $ges_result = Invoke-Command -ConnectionUri $cu -Authentication Kerberos -ConfigurationName Microsoft.Exchange -ScriptBlock { Get-ExchangeServer }
  $cs_result = Invoke-Command -ConnectionUri $cu -Authentication Kerberos -ConfigurationName Microsoft.Exchange -ScriptBlock { Get-ServerComponentState -Identity $args[0] } -Args $env:COMPUTERNAME
  $formatted_cs = @{}
  $cs_result | Foreach-Object { $formatted_cs[$_.Component] = @{State=$_.State} }

  $setup_path = [System.IO.Path]::Combine($env:ExchangeInstallPath, "bin\setup.exe")

  $setup_build_version = [System.Diagnostics.FileVersionInfo]::GetVersionInfo($setup_path).ProductVersion

  $res = @{
    ansible_facts=@{
      exchange_facts=$ges_result[0]; 
      exchange_component_states=$formatted_cs;
      exchange_build_version=$setup_build_version;
    }
  }

}
Catch {
  $res = @{failed=$true; msg="Exchange Management unavailable: $_"}
}

ConvertTo-Json $res -Depth 99

