if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Output "Script not running as admin, restarting..."
    Start-Process powershell "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    exit
}

$mani_path = "$env:ProgramData\Epic\EpicGamesLauncher\Data\Manifests"
$output_path = "$env:ProgramData\Microsoft\Windows\Start Menu\Programs\Epic Games"
$testFilePath = "$env:ProgramData\Microsoft\Windows\Start Menu\Programs\test"

Remove-Item $output_path -Recurse -ErrorAction SilentlyContinue
New-Item $output_path -ItemType Directory -ErrorAction SilentlyContinue | Out-Null


$mani_files = Get-ChildItem $mani_path -File
foreach($mani_file in $mani_files){
    $mani_json = Get-Content $mani_file.FullName -Encoding UTF8 | ConvertFrom-Json

    $LaunchExecutable = $mani_json.LaunchExecutable
    $DisplayName =  $mani_json.DisplayName -replace '[^a-zA-Z0-9 _-]', ''
    $InstallLocation = $mani_json.InstallLocation.Replace('/', '\')
    $CatalogNamespace = $mani_json.CatalogNamespace
    $CatalogItemId = $mani_json.CatalogItemId
    $AppName = $mani_json.AppName

    $attrs = @(
        $LaunchExecutable
        $DisplayName
        $InstallLocation
        $CatalogNamespace
        $CatalogItemId
        $AppName
    )

    if ( -not ($attrs | ForEach-Object { $_ -eq $null -or $_ -eq "" } | Where-Object { $_ }) -and (Test-Path -Path $InstallLocation -PathType Container) ){
        $link_path = ($output_path + "\" + $DisplayName + ".url")
        "[{000214A0-0000-0000-C000-000000000046}]" | Set-Content $link_path
        "Prop3=19,0" | Add-Content $link_path
        "[InternetShortcut]" | Add-Content $link_path
        "IDList=" | Add-Content $link_path
        "IconIndex=0" | Add-Content $link_path
        "WorkingDirectory=" + $InstallLocation | Add-Content $link_path
        "URL=com.epicgames.launcher://apps/"+ $CatalogNamespace + "%3A" + $CatalogItemId + "%3A" + $AppName + "?action=launch&silent=true" | Add-Content $link_path

        $exe_path = ($InstallLocation + "\" + $LaunchExecutable)
        $ico_path = ($exe_path -split ".exe")[0] + ".ico"

        if (Test-Path -Path $ico_path -PathType Leaf){
            "IconFile=" + $ico_path | Add-Content $link_path
        }
        else{
            "IconFile=" + $exe_path | Add-Content $link_path
        }
        "Added: " + $DisplayName + "←" + $mani_file.Name | Write-Output
    }
    else{
        "Not added: " + $DisplayName + "←" + $mani_file.Name | Write-Output
    }
}

'' | Write-Output

if (-not ($args -contains "-skip")) {
    pause
}
