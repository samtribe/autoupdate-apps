##Download update path
$downloadPath = "%Your path here%"

## Link to latest release versions
$UrlDownloadPublic = 'https://plex.tv/api/downloads/1.json'
$versionsAvailable = Invoke-RestMethod -Uri $UrlDownloadPublic


## Get info on latest release
$latestAvailDownloadURL = $versionsAvailable.computer.Windows.releases.url
$latestAvailDownloadChecksum = $versionsAvailable.computer.Windows.releases.checksum
$latestAvailDownloadVersion,$latestAvailDownloadBuild = $versionsAvailable.computer.Windows.version.Split('-')


## Find Plex Media Server Install Location
$PMSInstallKeys=("HKLM:\Software\Wow6432Node\Plex, Inc.\Plex Media Server","HKLM:\Software\Plex, Inc.\Plex Media Server")
  foreach($Key in $PMSInstallKeys){
    if(Test-Path $Key -ErrorAction SilentlyContinue){
      if(Get-ItemProperty "$(Get-ItemProperty $Key -Name "InstallFolder" -ErrorAction SilentlyContinue | Select-Object -ExpandProperty InstallFolder -OutVariable InstallFolder)\Plex Media Server.exe" -OutVariable PMSExeFile -ErrorAction SilentlyContinue){
      }
    }
  }
$installedVersion,$installedBuild = $PMSExeFile.VersionInfo.ProductVersion.Split('-')


## If newer version available download and run this version
If($latestAvailDownloadVersion -gt $installedVersion){
  $downloadFilePath = "$downloadPath\PlexMediaServer-$latestAvailDownloadVersion-$latestAvailDownloadBuild-x86.exe"
  (New-Object System.Net.WebClient).DownloadFile($latestAvailDownloadURL, $downloadFilePath)
  $downloadFileHash = (Get-FileHash -Algorithm SHA1 $downloadFilePath).Hash

  If($downloadFileHash -eq $latestAvailDownloadChecksum)
  { #Install Update
      Start-Process -FilePath $downloadFilePath -ArgumentList "/install","/quiet" -Wait
  }
}

Start-Sleep -Seconds 60
  

## Delete Auto-Run RegKey

Get-ChildItem "REGISTRY::HKEY_USERS" | Select Name | ForEach-Object {
  if(Get-ItemPropertyValue -Path "REGISTRY::$($_.Name)\Software\Microsoft\Windows\CurrentVersion\Run" -Name "Plex Media Server" -ErrorAction SilentlyContinue){
    ## Autorun Key exists and needs deleted
    Remove-ItemProperty -Path "REGISTRY::$($_.Name)\Software\Microsoft\Windows\CurrentVersion\Run" -Name "Plex Media Server"
  }
  Else{
  ## Autorun Key does not exist so do nothing 
  }
}
  
