# 自動修復 Windows 分區
function autoFixBoot {
    param (
        [Parameter(Position = 0, ParameterSetName = "", Mandatory=$true)]
        [string] $DriveLetter,
        [switch] $Force
    )
    $Dri=(Get-Partition -DriveLetter:$DriveLetter)
    if (!$Dri) { Write-Host "錯誤::請輸入正確的磁碟代號"; return}
    # 修復引導
    $Boot = ($Dri|Get-Disk).PartitionStyle
    if ($Boot -eq "GPT") {
        irm "https://raw.githubusercontent.com/hunandy14/autoFixEFI/master/autoFixEFI.ps1"|iex
        autoFixEFI -DriveLetter:$DriveLetter -Force:$Force
    } elseif ($Boot -eq "MBR") { 
        irm "https://raw.githubusercontent.com/hunandy14/autoFixEFI/master/autoFixMBR.ps1"|iex
        autoFixMBR -DriveLetter:$DriveLetter -Force:$Force
    }
} # autoFixBoot C

# 下載 DiskGenius 到桌面並啟動
function Install-DiskGenius {
    param (
        [switch] $Force
    )
    $RegjumpSite = "https://download.eassos.cn/DG5421239_x64.zip"
    $FileName    = "DG5421239_x64.zip"
    $AppPath     = $([Environment]::GetFolderPath('Desktop'))
    $Download = !(Test-Path "$AppPath\DiskGenius\DiskGenius.exe")
    if ($Download -or $Force) {
        Start-BitsTransfer $RegjumpSite "$env:TEMP\$FileName"
        # Invoke-WebRequest $RegjumpSite -OutFile:$env:TEMP\$FileName
        Expand-Archive "$env:TEMP\$FileName" $AppPath -Force
        explorer "$AppPath\DiskGenius"
    } explorer "$AppPath\DiskGenius\DiskGenius.exe"
}

function MountBoot {
    param (
        [Parameter(Position = 0, ParameterSetName = "", Mandatory=$true)]
        [string] $DriveLetter
    )
    $Dri=(Get-Partition -DriveLetter:$DriveLetter)
    if (!$Dri) { Write-Host "錯誤::請輸入正確的磁碟代號"; return}
    # 修復引導
    $Boot = ($Dri|Get-Disk).PartitionStyle
    if ($Boot -eq "GPT") {
        $EFI = Get-Partition($Dri.DiskNumber)|Where-Object{$_.GptType -eq $EFI_ID}
        if(!$EFI.DriveLetter){
            $EFI|Set-Partition -NewDriveLetter:$EFI_Letter
            $EFI = Get-Partition($Dri.DiskNumber)|Where-Object{$_.GptType -eq $EFI_ID}
            if (!$EFI.DriveLetter) {Write-Error "未知錯誤無法添加磁碟代號"}
        } $EFI_Letter = $EFI.DriveLetter
        Write-Host "已掛載啟動磁區到 ($EFI_Letter`:\)"
    } elseif ($Boot -eq "MBR") { 
        $Active = Get-Partition($Dri.DiskNumber)|Where-Object{$_.IsActive}
        if(!$Active.DriveLetter){
            $Active|Set-Partition -NewDriveLetter:$MBR_Letter;
            $Active = Get-Partition($Dri.DiskNumber)|Where-Object{$_.IsActive}
            if (!$Active.DriveLetter) {Write-Error "未知錯誤無法添加磁碟代號"}
        } $MBR_Letter = $Active.DriveLetter
        Write-Host "已載啟動磁區到 ($MBR_Letter`:\)"
    } else {
        Write-Host "該磁碟沒有啟動分區"
    }
}
