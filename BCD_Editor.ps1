function __BootList__ {
    param (
        
    )
    # 解析 BCD
    $BCD = (bcdedit).Split("`n")
    $BootCount = ($BCD|Select-String -AllMatches "identifier").Count - 1
    $BootHead = ($BCD)[3..13]
    # 解析 BCD 選單
    $BootList = @()
    for ($i = 0; $i -lt $BootCount; $i++) {
        $Star = (13 + ($i*19)) + 4
        $Item = @{
            Number                  = $i+1
            identifier              = $BCD[$Star+0 ].Substring(24,(($BCD)[$Star+0 ].Length-24))
            device                  = $BCD[$Star+1 ].Substring(24,(($BCD)[$Star+1 ].Length-24))
            path                    = $BCD[$Star+2 ].Substring(24,(($BCD)[$Star+2 ].Length-24))
            description             = $BCD[$Star+3 ].Substring(24,(($BCD)[$Star+3 ].Length-24))
            locale                  = $BCD[$Star+4 ].Substring(24,(($BCD)[$Star+4 ].Length-24))
            inherit                 = $BCD[$Star+5 ].Substring(24,(($BCD)[$Star+5 ].Length-24))
            recoverysequence        = $BCD[$Star+6 ].Substring(24,(($BCD)[$Star+6 ].Length-24))
            displaymessageoverride  = $BCD[$Star+7 ].Substring(24,(($BCD)[$Star+7 ].Length-24))
            recoveryenabled         = $BCD[$Star+8 ].Substring(24,(($BCD)[$Star+8 ].Length-24))
            isolatedcontext         = $BCD[$Star+9 ].Substring(24,(($BCD)[$Star+9 ].Length-24))
            allowedinmemorysettings = $BCD[$Star+10].Substring(24,(($BCD)[$Star+10].Length-24))
            osdevice                = $BCD[$Star+11].Substring(24,(($BCD)[$Star+11].Length-24))
            systemroot              = $BCD[$Star+12].Substring(24,(($BCD)[$Star+12].Length-24))
            resumeobject            = $BCD[$Star+13].Substring(24,(($BCD)[$Star+13].Length-24))
            nx                      = $BCD[$Star+14].Substring(24,(($BCD)[$Star+14].Length-24))
            bootmenupolicy          = $BCD[$Star+15].Substring(24,(($BCD)[$Star+15].Length-24))
        } |ForEach-Object { New-Object object | Add-Member -NotePropertyMembers $_ -PassThru }
        # $Item|Format-Table Number,description,@{Name='Letter'; Expression={$_.device -replace"partition=", ""}},resumeobject
        $BootList += $Item
    } return $BootList
}

function BCD_Editor {
    [CmdletBinding(DefaultParameterSetName = "Info")]
    param (
    [Parameter(ParameterSetName = "Delete")]
    [int] $DeleteIndex,
    [Parameter(ParameterSetName = "Default")]
    [int] $DefaultIndex,
    [Parameter(ParameterSetName = "")]
    [int] $Times,
    [Parameter(ParameterSetName = "Info")]
    [switch] $Info
    )
    # 解析 BCD 選單
    $BootList = __BootList__
    
    # 修改等待時間
    if ($Times) { bcdedit /timeout $Times }
    
    # 變更預設選單
    
    
    # 查看選單
    if ($Info) {
        $BootList|Format-Table Number,description,@{Name='Letter'; Expression={$_.device -replace"partition=", ""}},resumeobject
    }
    if ($DeleteIndex) {
        $BootList[$DeleteIndex-1]|Format-Table Number,description,@{Name='Letter'; Expression={$_.device -replace"partition=", ""}},resumeobject
        Write-Host " 即將刪除上述選單" -ForegroundColor:Yellow
        if (!$Force) {
            $response = Read-Host "  沒有異議請輸入Y (Y/N) ";
            if ($response -ne "Y" -or $response -ne "Y") { Write-Host "使用者中斷" -ForegroundColor:Red; return; }
        }
        $BootID = $BootList[$DeleteIndex-1].resumeobject
        # $BootID
        # bcdedit /delete $BootID
        Write-Host ""
        
        # 重新讀取BCD選單
        Write-Host "重新載入最新選單狀態："
        (__BootList__)|Format-Table Number,description,@{Name='Letter'; Expression={$_.device -replace"partition=", ""}},resumeobject
    }
}
BCD_Editor -DefaultIndex:1

# $BootList

