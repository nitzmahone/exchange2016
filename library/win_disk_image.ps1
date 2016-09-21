#!powershell

# POWERSHELL_COMMON
# WANTS_JSON

$parsed_args = Parse-Args $args

$result = @{changed=$false}

$image_path = Get-AnsibleParam $parsed_args "image_path" -failifempty $result
$state = Get-AnsibleParam $parsed_args "state" -default "present" -validateset "present","absent"

$di = Get-DiskImage $image_path

If($state -eq "present") {
  If(-not $di.Attached) {
    $di = Mount-DiskImage $image_path -PassThru
    $result.changed = $true
  }
  $result.mount_path = ($di | Get-Volume).DriveLetter + ":\"
}
ElseIf($state -eq "absent") {
  If($di.Attached) {
    Dismount-DiskImage $image_path | Out-Null
    $result.changed = $true
  }
}

Exit-Json $result
