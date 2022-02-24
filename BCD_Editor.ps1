# 獲取BCD物件
function Get-BCD {
    param (
        
    )
    $BCD_Object = @()
    # 解析 BCD
    $BCD = (bcdedit).Split("`n")
    $BootCount = ($BCD|Select-String -AllMatches "identifier").Count-1
    $obj = $BCD | Select-String -Pattern "identifier"

    # 計算 Loder 屬性數量
    if($obj.Length -le 1){
        Write-Host "No Loder"; return
    } elseif ($obj.Length -eq 2) {
        $AttrCount = $BCD.Count - $obj[1].LineNumber +1
        $HeadCount = $obj[1].LineNumber-7
        $Offset = $obj[1].LineNumber-1
    } else {
        $AttrCount = $obj[2].LineNumber - $obj[1].LineNumber -3
        $HeadCount = $BCD.Count - $obj[1].LineNumber +1
        $Offset = $obj[1].LineNumber-1
    }

    # 解析 BCD 表頭
    # $BootHeader = @()
    $Item = @{}
    for ($i = 0; $i -lt $HeadCount; $i++) {
        $Line = $BCD[3+$i]
        $Attr = $Line.Substring(0,24).trim()
        $Value = $Line.Substring(24,$Line.Length-24).trim()
        $Item += @{ $Attr = $Value}
    } $Item = $Item|ForEach-Object { New-Object object | Add-Member -NotePropertyMembers $_ -PassThru }
    # $BootHeader += @($Item)
    $BCD_Object += @($Item)

    # 解析 BCD 選單
    # $BootLoader = @()
    for ($j = 0; $j -lt $BootCount; $j++) {
        $Star = ($j*$BootCount)+$Offset
        $Item = @{Number = $j+1}
        for ($i = 0; $i -lt $AttrCount; $i++) {
            $Line = $BCD[$Star+$i]
            $Attr = $Line.Substring(0,24).trim()
            $Value = $Line.Substring(24,$Line.Length-24).trim()
            $Item += @{ $Attr = $Value}
        } $Item = $Item|ForEach-Object { New-Object object | Add-Member -NotePropertyMembers $_ -PassThru }
        # $BootLoader += @($Item)
        $BCD_Object += @($Item)
    }
    # 改變預設輸出模式
    $DefaultProps = @('Number','description','device','timeout')
    $DefaultDisplay = New-Object System.Management.Automation.PSPropertySet("DefaultDisplayPropertySet",[string[]]$DefaultProps)
    $PSStandardMembers = [System.Management.Automation.PSMemberInfo[]]@($DefaultDisplay)
    $BCD_Object | Add-Member MemberSet PSStandardMembers $PSStandardMembers
    
    return $BCD_Object
} # Get-BCD
# function __Get-BCD_Tester__ {
#     param (
        
#     )
    # 直接輸出看結果
    # Get-BCD
    # 測試RE環境
    # (Get-BCD)[1].recoveryenabled
    # 獲取預設選單
    # $default = (Get-BCD)|Where-Object{$_.identifier -contains ((Get-BCD)[0].default)}
    # $default|Format-Table Number,description,@{Name='Letter'; Expression={$_.device -replace"partition=", ""}},resumeobject
    # 獲取當前系統
    # $current = (Get-BCD)|Where-Object{$_.identifier -contains '{current}'}
    # $current|Format-Table Number,description,@{Name='Letter'; Expression={$_.device -replace"partition=", ""}},resumeobject
# } # __Get-BCD_Tester__

function BCD_Editor {
    [CmdletBinding(DefaultParameterSetName = "Info")]
    param (
    [Parameter(Position = 0, ParameterSetName = "Delete")]
    [switch] $Delete,
    [Parameter(Position = 0, ParameterSetName = "Default")]
    [switch] $Default,
    [Parameter(Position = 0, ParameterSetName = "Info")]
    [switch] $Info,
    [Parameter(Position = 1, ParameterSetName = "Delete")]
    [Parameter(Position = 1, ParameterSetName = "Default")]
    [int] $Index,
    [Parameter(ParameterSetName = "")]
    [int] $Times,
    [Parameter(ParameterSetName = "")]
    [switch] $Force
    )
    # 修改等待時間
    if ($Times) { bcdedit /timeout $Times }
    
    # 獲取 BCD
    $BCD = Get-BCD
    
    # 查看選單
    if ($Info) { $BCD }
    
    # 刪除選單
    if ($Delete) {
        $BCD[$Index]
        Write-Host " 即將刪除上述選單 (錯誤的操作會導致無法開機)" -ForegroundColor:Yellow
        if (!$Force) {
            $response = Read-Host "  沒有異議請輸入Y (Y/N) ";
            if ($response -ne "Y" -or $response -ne "Y") { Write-Host "使用者中斷" -ForegroundColor:Red; return; }
        }
        bcdedit /delete $BootID
        Write-Host ""
        # 重新讀取BCD選單
        Write-Host "重新載入最新選單狀態：" -ForegroundColor:Yellow
        Get-BCD
        return
    } 
    
    # 變更預設選單
    elseif ($Default) {
        $BCD[$Index]
        Write-Host " 即將把上述選單設為預設 (錯誤的操作會導致無法開機)" -ForegroundColor:Yellow
        if (!$Force) {
            $response = Read-Host "  沒有異議請輸入Y (Y/N) ";
            if ($response -ne "Y" -or $response -ne "Y") { Write-Host "使用者中斷" -ForegroundColor:Red; return; }
        }
        bcdedit /default $BootID
        Write-Host ""
        Write-Host "重新載入最新選單狀態：" -ForegroundColor:Yellow
        Get-BCD
        return
    }
} # BCD_Editor -Info
