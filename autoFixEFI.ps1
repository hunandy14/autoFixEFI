function autoFixEFI {
    param (
        [Parameter(Position = 0, ParameterSetName = "", Mandatory=$true)]
        [string] $DriveLetter,
        [switch] $Force
    )
    # 基本設定
    $EfiSize     = 300MB
    $response    = ""
    $DriveLetter = $DriveLetter.Trim(":|\")
    $EFI_ID      = "{c12a7328-f81f-11d2-ba4b-00a0c93ec93b}"
    $EFI_Letter  = "B"
    # 檢測
    $Dri=(Get-Partition -DriveLetter:$DriveLetter)
    if (!$Dri) { Write-Host "錯誤::請輸入正確的磁碟代號"; return}
    if (($Dri|Get-Disk).PartitionStyle -ne "GPT") {
        Write-Host "錯誤::該分區的磁碟為 MBR 非 GPT 格式"; return }
    $EFI = Get-Partition($Dri.DiskNumber)|Where-Object{$_.GptType -eq $EFI_ID}
    # 沒有EFI分區則重新建立
    if (!$EFI) {
        Get-Partition -DiskNumber:$Dri.DiskNumber
        Write-Host ""
        Write-Host "該磁碟沒有EFI分區，即將從" -NoNewline
        Write-Host " ($($DriveLetter):) " -ForegroundColor:Yellow -NoNewline
        Write-Host "壓縮300M並建立EFI分區" 
        if (!$Force) {
            $response = Read-Host "  沒有異議或看不懂，請輸入Y (Y/N) ";
            if ($response -ne "Y" -or $response -ne "Y") { Write-Host "使用者中斷" -ForegroundColor:Red; return; }
        }
        # 查詢與計算空間
        $SupSize = $Dri|Get-PartitionSupportedSize
        $CurSize = $Dri.size
        $MaxSize = $SupSize.SizeMax
        $AvailableSize = $MaxSize - $CurSize
        # 空餘空間小於EFI空間，壓縮C曹
        if ($AvailableSize -lt $EfiSize) {
            $ReSize = $MaxSize - $EfiSize
            # 目標分區在結尾(GPT結尾必須保留 1048576 空間)
            if ((($Dri|Get-Disk|Get-Partition)[-1]).UniqueId -eq $Dri.UniqueId) {
                $ReSize = $ReSize - 1048576
            }
            $Dri|Resize-Partition -Size:$ReSize
        }
        # 建立EFI分區並格式化
        $EFI = (($Dri|New-Partition -Size:($EfiSize) -GptType:$EFI_ID)|Format-Volume -FileSystem:FAT32 -Force)|Get-Partition
        
    }
    
    # 新增EFI磁碟代號
    if(!$EFI.DriveLetter){
        $EFI|Set-Partition -NewDriveLetter:$EFI_Letter
        $EFI = Get-Partition($Dri.DiskNumber)|Where-Object{$_.GptType -eq $EFI_ID}
    }
    # 重建EFI開機引導
    $cmd = "bcdboot $($DriveLetter):\windows /f UEFI /s $($EFI_Letter):\ /l zh-tw"
    Get-Partition($Dri.DiskNumber)|Format-Table PartitionNumber,DriveLetter,Size,Type
    Write-Host $cmd
    
    # 修復EFI引導
    Write-Host ""
    Write-Host "即將把" -NoNewline
    $DriName = ($Dri|Get-Volume).FileSystemLabel
    Write-Host " $DriName($DriveLetter`:) " -ForegroundColor:Yellow -NoNewline
    Write-Host "的啟動引導, " -NoNewline
    Write-Host "寫入EFI分區" -NoNewline
    Write-Host " (磁碟:$($EFI.DiskNumber), 分區:$($EFI.PartitionNumber)) " -ForegroundColor:Yellow
    if (!$Force) {
        $response = Read-Host "  沒有異議或看不懂，請輸入Y (Y/N) "
        if (($response -ne "Y") -or ($response -ne "Y")) {
            Write-Host "使用者中斷" -ForegroundColor:Red
            $EFI|Remove-PartitionAccessPath -AccessPath:"$($EFI.DriveLetter):"
            return
        }
    }
    
    # 執行命令
    Invoke-Expression $cmd
    
    # 移除EFI磁碟代號
    $EFI|Remove-PartitionAccessPath -AccessPath:"$($EFI.DriveLetter):"
} # autoFixEFI -DriveLetter:C: -Force
