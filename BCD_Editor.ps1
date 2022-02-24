function __BootList__ {
    param (
        
    )
    # 解析 BCD
    $BCD_Str = (bcdedit)
    $BCD = $BCD_Str.Split("`n")
    $BootCount = ($BCD|Select-String -AllMatches "identifier").Count - 1
    $BootHead = ($BCD)[3..13]
    
    $obj = $BCD_Str | Select-String -Pattern "identifier"
    # 計算 Loder 屬性數量
    if($obj.Length -le 1){
        Write-Host "No Loder"; return
    } elseif ($obj.Length -eq 2) {
        $AttrCount = $BCD.Count - $obj[1].LineNumber +1
    } else {
        $AttrCount = $obj[2].LineNumber - $obj[1].LineNumber -3
    }
    # 解析 BCD 選單
    $BootList = @()
    for ($i = 0; $i -lt $BootCount; $i++) {
        $Star = ($i*$BootCount)+16
        $Item = @{ Number = $i+1}
        for ($j = 0; $j -lt $AttrCount; $j++) {
            $idx = $Star+$j
            $Line =  $BCD[$idx]
            $Attr = $Line.Substring(0,24).trim()
            $Value = $Line.Substring(24,$Line.Length-24).trim()
            $Item += @{ $Attr = $Value}
        } 
        $Item = $Item|ForEach-Object { New-Object object | Add-Member -NotePropertyMembers $_ -PassThru }
        # __Boot_Print__ $Item
        $BootList += @($Item)
    }
    return $BootList
} # (__BootList__)|Format-Table Number,description,@{Name='Letter'; Expression={$_.device -replace"partition=", ""}},resumeobject

function __Boot_Print__ {
    param (
        [System.Object] $Boot
    )
    if (!$Boot) { $Boot = __BootList__ }
    ($Boot)|Format-Table Number,description,@{Name='Letter'; Expression={$_.device -replace"partition=", ""}},resumeobject
} # __Boot_Print__


__Boot_Print__ (__BootList__)



return


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
    [switch] $Force
    )
    # 解析 BCD 選單
    $BootList = __BootList__
    $BootID = $BootList[$Index-1].resumeobject
    
    # 修改等待時間
    if ($Times) { bcdedit /timeout $Times }
    
    # 查看選單
    if ($Info) {
        __Boot_Print__ $BootList
    }
    # 刪除選單
    if ($Delete) {
        __Boot_Print__ $BootList[$Index-1]
        Write-Host " 即將刪除上述選單" -ForegroundColor:Yellow
        if (!$Force) {
            $response = Read-Host "  沒有異議請輸入Y (Y/N) ";
            if ($response -ne "Y" -or $response -ne "Y") { Write-Host "使用者中斷" -ForegroundColor:Red; return; }
        }
        bcdedit /delete $BootID
        Write-Host ""
        # 重新讀取BCD選單
        Write-Host "重新載入最新選單狀態："
        __Boot_Print__
    } 
    
    # 變更預設選單
    elseif ($Default) {
        "bcdedit /default $BootID"
        
        Write-Host "重新載入最新選單狀態：" -ForegroundColor:Yellow
        __Boot_Print__
    }
}
# BCD_Editor -Default 1

# $BootList

