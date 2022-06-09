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
        Invoke-RestMethod "https://raw.githubusercontent.com/hunandy14/autoFixEFI/master/autoFixEFI.ps1"|Invoke-Expression
        autoFixEFI -DriveLetter:$DriveLetter -Force:$Force
    } elseif ($Boot -eq "MBR") { 
        Invoke-RestMethod "https://raw.githubusercontent.com/hunandy14/autoFixEFI/master/autoFixMBR.ps1"|Invoke-Expression
        autoFixMBR -DriveLetter:$DriveLetter -Force:$Force
    }
} # autoFixBoot C

# 下載 DiskGenius 到桌面並啟動
function Install-DiskGenius {
    param (
        [switch] $Force
    )
    $Address = "https://download.eassos.cn/DG5421239_x64.zip"
    $FileName    = "DG5421239_x64.zip"
    $AppPath     = $([Environment]::GetFolderPath('Desktop'))
    $Download = !(Test-Path "$AppPath\DiskGenius\DiskGenius.exe")
    if ($Download -or $Force) {
        Start-BitsTransfer $Address "$env:TEMP\$FileName"
        # Invoke-WebRequest $Address -OutFile:$env:TEMP\$FileName
        Expand-Archive "$env:TEMP\$FileName" $AppPath -Force
        explorer "$AppPath\DiskGenius"
    } explorer "$AppPath\DiskGenius\DiskGenius.exe"
}

function MountBoot {
    param (
        [Parameter(Position = 0, ParameterSetName = "", Mandatory=$true)]
        [string] $DriveLetter,
        [Parameter(Position = 1, ParameterSetName = "")]
        [string] $BootLetter = "B"
    )
    $Dri=(Get-Partition -DriveLetter:$DriveLetter)
    if (!$Dri) { Write-Host "錯誤::請輸入正確的磁碟代號"; return}
    if ((Get-Partition -DriveLetter:$BootLetter -erroraction:'silentlycontinue')) {
        Write-Error "啟動磁區代號 ($BootLetter`:\) 已經被占用"
    }
    # 修復引導
    $Boot = ($Dri|Get-Disk).PartitionStyle
    if ($Boot -eq "GPT") {
        $EFI_ID = "{c12a7328-f81f-11d2-ba4b-00a0c93ec93b}"
        $EFI = Get-Partition($Dri.DiskNumber)|Where-Object{$_.GptType -eq $EFI_ID}
        if(!$EFI.DriveLetter){
            $EFI|Set-Partition -NewDriveLetter:$BootLetter
            $EFI = Get-Partition($Dri.DiskNumber)|Where-Object{$_.GptType -eq $EFI_ID}
            if (!$EFI.DriveLetter) {Write-Error "未知錯誤無法添加磁碟代號"}
        } $EFI_Letter = $EFI.DriveLetter
        Write-Host "已掛載啟動磁區到 ($EFI_Letter`:\)"
    } elseif ($Boot -eq "MBR") { 
        $Active = Get-Partition($Dri.DiskNumber)|Where-Object{$_.IsActive}
        if(!$Active.DriveLetter){
            $Active|Set-Partition -NewDriveLetter:$BootLetter;
            $Active = Get-Partition($Dri.DiskNumber)|Where-Object{$_.IsActive}
            if (!$Active.DriveLetter) {Write-Error "未知錯誤無法添加磁碟代號"}
        } $MBR_Letter = $Active.DriveLetter
        Write-Host "已掛載啟動磁區到 ($MBR_Letter`:\)"
    } else {
        Write-Host "該磁碟沒有啟動分區"
    }
}
