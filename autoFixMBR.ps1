function autoFixMBR {
    param (
        [Parameter(Position = 0, ParameterSetName = "", Mandatory=$true)]
        [string] $DriveLetter,
        [switch] $Force
    )
    $Dri=(Get-Partition -DriveLetter:$DriveLetter)
    if (!$Dri) { Write-Host "錯誤::請輸入正確的磁碟代號"; return}
    if (($Dri|Get-Disk).PartitionStyle -ne "MBR") {
        Write-Host "錯誤::該分區的磁碟為 MBR 非 GPT 格式"; return }
    
    $MBR_Letter  = "X"
    $Active = $Dri|Where-Object{$_.IsActive}
    
    if (!$Active) {
        Write-Host "該磁碟沒有啟動分區，即將把" -NoNewline
        Write-Host " ($($DriveLetter):) " -ForegroundColor:Yellow -NoNewline
        Write-Host "設置成啟動分區" 
        $response = Read-Host "  沒有異議或看不懂，請輸入Y (Y/N) ";
        if ($response -ne "Y" -or $response -ne "Y") { Write-Host "使用者中斷" -ForegroundColor:Red; return; }
        $Dri|Set-Partition -IsActive $True
        $Active = $Dri|Where-Object{$_.IsActive}
    }
    Get-Partition -DiskNumber:$Dri.DiskNumber | Out-Default 
    Write-Host "即將把" -NoNewline
    Write-Host " ($($DriveLetter):\windows) " -ForegroundColor:Yellow -NoNewline
    Write-Host "的啟動引導, " -NoNewline
    Write-Host "寫入MBR引導分區" -NoNewline
    Write-Host " (磁碟:$($Active.DiskNumber), 分區:$($Active.PartitionNumber)) " -ForegroundColor:Yellow
    if (!$Force) {
        $response = Read-Host "  沒有異議或看不懂，請輸入Y (Y/N) "
        if (($response -ne "Y") -or ($response -ne "Y")) { Write-Host "使用者中斷" -ForegroundColor:Red; return; }
    }
    # 新增Active磁碟代號
    if(!$Active.DriveLetter){ $Active|Set-Partition -NewDriveLetter:$MBR_Letter; $Active=$Active|Get-Partition; }
    # 重建MBR開機引導
    $cmd = "bcdboot $($DriveLetter):\windows /f BIOS /s $($EFI_Letter):\ /l zh-tw"
    Invoke-Expression $cmd
    # 移除EFI磁碟代號
    if ($DriveLetter -ne $Active.DriveLetter) {
        $Active|Remove-PartitionAccessPath -AccessPath:"$($Active.DriveLetter):"
    }
} # autoFixMBR C