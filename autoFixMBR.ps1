function MBR_INFO {
    Get-Partition|Select-Object DriveLetter,Type,IsBoot,IsActive
}
function autoFixMBR {
    param (
        [Parameter(Position = 0, ParameterSetName = "", Mandatory = $true)]
        [string] $DriveLetter,
        [Parameter(Position = 1, ParameterSetName = "")]
        [string] $BootLetter,
        [switch] $Force
    )
    $MBR_Letter = "B"
    # 驗證磁碟是否有效
    $Dri = (Get-Partition -DriveLetter:$DriveLetter)
    
    if (!$Dri) { Write-Host "錯誤::請輸入正確的 DriveLetter 磁碟代號"; return }
    if (($Dri | Get-Disk).PartitionStyle -ne "MBR") {
        Write-Host "錯誤::該分區的磁碟格式非 MBR 格式"; return
    }

    # 獲取啟動磁區位置
    $Dri|Format-Table
    if ($BootLetter) { # 使用指定的啟動磁區
        $Active = $Dri|Get-Disk|Get-Partition -DriveLetter:$BootLetter
        if (!$Active) { Write-Host "錯誤::請輸入正確的 BootLetter 磁碟代號"; return }
        if (!$Active.IsActive) { $Active|Set-Partition -IsActive $True }
    }
    else { # 自動搜尋啟動磁區是否存在
        $Active = $Dri|Get-Disk|Get-Partition|Where-Object{$_.IsActive}
        if (!$Active) {
            $DriName = ($Dri|Get-Volume).FileSystemLabel
            Write-Host "磁碟分區 " -NoNewline
            Write-Host "$DriName($DriveLetter`:)" -ForegroundColor:Yellow -NoNewline 
            Write-Host " 沒有啟動分區，即將把該分區設置成啟動分區"
            if (!$Force) {
                $response = Read-Host "  沒有異議或看不懂，請輸入Y (Y/N) ";
                if ($response -ne "Y" -or $response -ne "Y") { Write-Host "使用者中斷" -ForegroundColor:Red; return; }
            }
            $Active = $Dri
            $Active|Set-Partition -IsActive $True
        }
    }

    # 獲取Active磁碟代號
    if(!$Active.DriveLetter){
        $Active|Set-Partition -NewDriveLetter:$MBR_Letter;
        $Active = $Dri|Get-Disk|Get-Partition|Where-Object{$_.IsActive}
        if (!$Active.DriveLetter) {Write-Error "未知錯誤無法添加磁碟代號"}
    } $MBR_Letter = $Active.DriveLetter

    # 重建MBR開機引導
    $cmd = "bcdboot $($DriveLetter):\windows /f BIOS /s $MBR_Letter`:\ /l zh-tw"
    Write-Host $cmd
    
    # 將引導寫入啟動磁區
    Write-Host "即將把" -NoNewline
    Write-Host " ($($DriveLetter):\windows) " -ForegroundColor:Yellow -NoNewline
    Write-Host "的啟動引導, " -NoNewline
    Write-Host "寫入MBR引導分區" -NoNewline
    Write-Host " (磁碟:$($Active.DiskNumber), 分區:$($Active.PartitionNumber)) " -ForegroundColor:Yellow
    if (!$Force) {
        $response = Read-Host "  沒有異議或看不懂，請輸入Y (Y/N) "
        if (($response -ne "Y") -or ($response -ne "Y")) {
            Write-Host "使用者中斷" -ForegroundColor:Red
            # 移除Active磁碟代號
            if (($DriveLetter -ne $Active.DriveLetter) -and ($Active.DriveLetter -ne "C")) {
                $Active|Remove-PartitionAccessPath -AccessPath:"$($Active.DriveLetter)`:"
            } return
        }
    }

    # 執行
    Invoke-Expression $cmd

    # 移除Active磁碟代號
    if (($DriveLetter -ne $Active.DriveLetter) -and ($Active.DriveLetter -ne "C")) {
        $Active|Get-Volume|Set-Volume -NewFileSystemLabel "系統保留"
        $Active|Remove-PartitionAccessPath -AccessPath:"$($Active.DriveLetter)`:"
    }

    # 確認最終結果
    $Dri|Get-Disk|Get-Partition|Format-Table PartitionNumber,DriveLetter,@{Name='Size'; Expression={'{0:F1} GB'-f($_.Size/1GB)}},Type,IsBoot,IsActive
} # autoFixMBR D -Force

function CreateBootPartition {
    param (
        [Parameter(Position = 0, ParameterSetName = "")]
        [string] $DriveLetter,
        [Parameter(Position = 1, ParameterSetName = "")]
        [string] $Size,
        [switch] $Force
    )
    # 基本設定 
    if (!$Size) { $Size = 300MB }
    if (!$DriveLetter) { $DriveLetter = "C" }

    # 搜尋啟動分區
    $Dri = (Get-Partition -DriveLetter:$DriveLetter)
    if (!$Dri) { Write-Host "錯誤::請輸入正確的 DriveLetter 磁碟代號"; return }
    if (($Dri | Get-Disk).PartitionStyle -ne "MBR") {
        Write-Host "錯誤::該分區的磁碟為 MBR 非 GPT 格式"; return
    } $Active = $Dri|Get-Disk|Get-Partition|Where-Object{$_.IsActive}

    # 有啟動且不同分區(不需要創建)
    if ($Active) {
        if ($Active.DriveLetter -ne $DriveLetter) {
            $Dri|Get-Disk|Get-Partition|Format-Table DriveLetter,Type,IsBoot,IsActive
            Write-Host "已有獨立啟動分區，無須分離" -ForegroundColor:Yellow
            return
        }
    }

    # 防呆保護
    Write-Host "即將分離" -NoNewline
    Write-Host " ($($DriveLetter):\windows) " -ForegroundColor:Yellow -NoNewline
    Write-Host "的啟動引導"
    if (!$Force) {
        $response = Read-Host "  沒有異議，請輸入Y (Y/N) "
        if (($response -ne "Y") -or ($response -ne "Y")) { Write-Host "使用者中斷" -ForegroundColor:Red; return; }
    }

    # 查詢與計算空間
    $Dri = (Get-Partition -DriveLetter:$DriveLetter)
    $SupSize = $Dri|Get-PartitionSupportedSize
    $CurSize = $Dri.size
    $MaxSize = $SupSize.SizeMax
    $AvailableSize = $MaxSize - $CurSize

    # 空餘空間小於Boot空間，壓縮該曹
    if ($AvailableSize -lt ([int]$Size + 1048576)) {
        $ReSize = $MaxSize - $Size
        # 目標分區在結尾(結尾必須保留 1048576 空間)
        if ((($Dri|Get-Disk|Get-Partition)[-1]).UniqueId -eq $Dri.UniqueId) {
            $ReSize = $ReSize - 1048576
        }
        $Dri|Resize-Partition -Size:$ReSize
    }
    
    # 創建分區
    $Active = (($Dri|New-Partition -Size:$Size)|Format-Volume)|Get-Partition
    $Active|Set-Partition -IsActive $True
    $Active|Get-Volume|Set-Volume -NewFileSystemLabel "系統保留"
    autoFixMBR $DriveLetter
} # CreateBootPartition -DriveLetter:D -Force
