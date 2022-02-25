# 獲取BCD物件
function Get-BCD {
    [CmdletBinding(DefaultParameterSetName = "_Default_")]
    param (
        [Parameter(Position = 0, ParameterSetName = "_Default_")]
        [switch] $_Default_,
        [Parameter(Position = 0, ParameterSetName = "FormatOut")]
        [switch] $FormatOut,
        [Parameter(Position = 0, ParameterSetName = "DefaultLoder")]
        [switch] $DefaultLoder,
        [Parameter(Position = 0, ParameterSetName = "CurrentLorder")]
        [switch] $CurrentLorder,
        [Parameter(Position = 1, ParameterSetName = "")]
        [string] $Path
    )
    $BCD_Object = @()
    # 解析 BCD
    if ($Path) {
        $BCD_Context = bcdedit /store $Path
    } else {
        $BCD_Context = bcdedit
    }
    $BCD = ($BCD_Context+"`n").Split("`n")
    $BootCount = ($BCD|Select-String -AllMatches "identifier").Count
    $BCDHeadLine = $BCD | Select-String -Pattern "identifier"

    # 解析 BCD 選單
    for ($j = 0; $j -lt $BootCount; $j++) {
        $Star = $BCDHeadLine[$j].LineNumber - 1
        $LoderObj = @{number = $j}
        $PreKeyName = ""
        for ($i = 0; $i -lt $BCD.Count; $i++) {
            $Line = $BCD[$Star+$i]
            if ($Line -eq "") { break; }
            $Attr = $Line.Substring(0,24).trim()
            $Value = $Line.Substring(24,$Line.Length-24).trim()

            if ($Attr -eq "") { # 添加新值到上一個屬性
                $PreAttrValue = $LoderObj[$PreKeyName]
                $NewValue = @()
                    $NewValue += @($PreAttrValue)
                    $NewValue += @($Value)
                $LoderObj[$PreKeyName] = $NewValue
            } else { # 增加新屬性
                $PreKeyName = $Attr
                $LoderObj += @{ $Attr = $Value}
            }
        } $LoderObj = $LoderObj|ForEach-Object { New-Object object | Add-Member -NotePropertyMembers $_ -PassThru }
        $BCD_Object += @($LoderObj)
    }

    # 設置秒數
    $timeout = $BCD_Object[0].timeout
    $BCD_Object[0].number = "# [t:$timeout"+"s]"

    # 改變預設輸出模式
    $DefaultProps = @('number','description','device','identifier')
    $DefaultDisplay = New-Object System.Management.Automation.PSPropertySet("DefaultDisplayPropertySet",[string[]]$DefaultProps)
    $PSStandardMembers = [System.Management.Automation.PSMemberInfo[]]@($DefaultDisplay)
    $BCD_Object|Add-Member MemberSet PSStandardMembers $PSStandardMembers
    
    # 格式化輸出終端機
    $Output=$false
    if ($FormatOut) {
        $Output=$true
    } elseif ($DefaultLoder) {
        $DstName = $BCD_Object[0].default
        $BCD_Object = $BCD_Object|Where-Object{$_.identifier -contains $DstName}; $Output=$true
    } elseif ($CurrentLorder) {
        $DstName = '{current}'
        $BCD_Object = $BCD_Object|Where-Object{$_.identifier -contains $DstName}; $Output=$true
    }
    # 輸出格式化結果
    if ($Output) {
        $BCD_Object|Format-Table number,description,@{Name='partition'; Expression={($_.device -replace"partition=", "")}},identifier
        return
    }
    
    # 輸出選單
    return $BCD_Object
} 
# (Get-BCD)|select *
# Get-BCD 
# Get-BCD -Path:"B:\Boot\BCD"
# Get-BCD -FormatOut
# Get-BCD -DefaultLoder
# Get-BCD -CurrentLorder
# return

# 測試
# function __Get-BCD_Tester__ {
#     param (
        # 
#     )
    # 直接輸出看結果
    # Get-BCD
    # 測試RE環境
    # (Get-BCD)[1].recoveryenabled
    # 獲取預設選單
    # $default = (Get-BCD)|Where-Object{$_.identifier -contains ((Get-BCD)[0].default)}
    # $default|Format-Table number,description,@{Name='Letter'; Expression={$_.device -replace"partition=", ""}},resumeobject
    # 獲取當前系統
    # $current = (Get-BCD)|Where-Object{$_.identifier -contains '{current}'}
    # $current|Format-Table number,description,@{Name='Letter'; Expression={$_.device -replace"partition=", ""}},resumeobject
# } # __Get-BCD_Tester__

function BCD_Editor {
    [CmdletBinding(DefaultParameterSetName = "Info")]
    param (
        [Parameter(Position = 0, ParameterSetName = "Info")]
        [switch] $Info,
        [Parameter(Position = 0, ParameterSetName = "Delete")]
        [switch] $Delete,
        [Parameter(Position = 0, ParameterSetName = "Default")]
        [switch] $Default,
        [Parameter(Position = 0, ParameterSetName = "Description")]
        [switch] $Description,
        [Parameter(Position = 0, ParameterSetName = "MoveToFirst")]
        [switch] $MoveToFirst,
        [Parameter(Position = 0, ParameterSetName = "MoveToLast")]
        [switch] $MoveToLast,
        
        [Parameter(Position = 1, ParameterSetName = "Delete")]
        [Parameter(Position = 1, ParameterSetName = "Default")]
        [Parameter(Position = 1, ParameterSetName = "Description")]
        [Parameter(Position = 1, ParameterSetName = "MoveToFirst")]
        [Parameter(Position = 1, ParameterSetName = "MoveToLast")]
        [int] $Index,
        
        [Parameter(Position = 2, ParameterSetName = "Description")]
        [string] $DescName,
        
        [Parameter(ParameterSetName = "")]
        [string] $Path,
        [Parameter(ParameterSetName = "")]
        [int] $Times = [int]-1,
        [Parameter(ParameterSetName = "")]
        [switch] $Force
    )

    
    # 獲取 BCD
    if ($Path) { $BCD = Get-BCD -Path:$Path } else { $BCD = Get-BCD }
    if ($Path) { $cmd_bcdedit = "bcdedit /store $Path" } else {$cmd_bcdedit = "bcdedit"}
    $BootID = $BCD[$Index].identifier
    # if ($Index -eq 0) { Write-Error "Index 輸入錯誤" }
    if (!$BootID) { Write-Error "Index 輸入錯誤" }

    # 查看選單
    if ($Info) {
        $BCD|Format-Table
    }

    # 修改等待時間
    if ($Times -ge 0) {
        $cmd = "$cmd_bcdedit /timeout $Times"
        Write-Host $cmd
        Invoke-Expression $cmd
    }

    # 刪除選單
    if ($Delete) {
        $BCD[$Index]|Format-Table
        $cmd = "$cmd_bcdedit /delete '$BootID'"
        Write-Host " 即將刪除上述選單 (錯誤的操作會導致無法開機)" -ForegroundColor:Yellow
        Write-Host $cmd
        if (!$Force) {
            $response = Read-Host "  沒有異議請輸入Y (Y/N) ";
            if ($response -ne "Y" -or $response -ne "Y") { Write-Host "使用者中斷" -ForegroundColor:Red; return; }
        }
        Invoke-Expression $cmd
        Write-Host ""
        # 重新讀取BCD選單
        Write-Host "重新載入最新選單狀態：" -ForegroundColor:Yellow
        if ($Path) { $BCD = Get-BCD -Path:$Path } else { $BCD = Get-BCD }
        $BCD|Format-Table
        return
    }

    # 變更預設選單
    if ($Default) {
        $BCD[$Index]|Format-Table
        $cmd = "$cmd_bcdedit /default '$BootID'"
        Write-Host " 即將把上述選單設為預設 (錯誤的操作會導致無法開機)" -ForegroundColor:Yellow
        Write-Host $cmd
        if (!$Force) {
            $response = Read-Host "  沒有異議請輸入Y (Y/N) ";
            if ($response -ne "Y" -or $response -ne "Y") { Write-Host "使用者中斷" -ForegroundColor:Red; return; }
        }
        Invoke-Expression $cmd
        Write-Host ""
        Write-Host "重新載入最新選單狀態：" -ForegroundColor:Yellow
        if ($Path) { $BCD = Get-BCD -Path:$Path } else { $BCD = Get-BCD }
        $BCD|Format-Table
        return
    }
    
    # 變更描述名稱
    if ($Description) {
        $BCD[$Index]|Format-Table
        $cmd = "$cmd_bcdedit /set '$BootID' description '$DescName'"
        Write-Host " 即將把上述選單描述修改為 $DescName" -ForegroundColor:Yellow
            Write-Host $cmd
            if (!$Force) {
            $response = Read-Host "  沒有異議請輸入Y (Y/N) ";
            if ($response -ne "Y" -or $response -ne "Y") { Write-Host "使用者中斷" -ForegroundColor:Red; return; }
        }
        Invoke-Expression $cmd
        Write-Host ""
        Write-Host "重新載入最新選單狀態：" -ForegroundColor:Yellow
        if ($Path) { $BCD = Get-BCD -Path:$Path } else { $BCD = Get-BCD }
        $BCD|Format-Table
        return
    }
    # 將選單移動到最前面
    if ($MoveToFirst -or $MoveToLast) {
        $BCD[$Index]|Format-Table

        if ($MoveToFirst) {
            $cmd = "$cmd_bcdedit /displayorder '$BootID' /addfirst"
            Write-Host " 即將把上述選單移動到最頂部" -ForegroundColor:Yellow
            Write-Host $cmd
        } elseif ($MoveToLast) {
            $cmd = "$cmd_bcdedit /displayorder '$BootID' /addlast"
            Write-Host " 即將把上述選單移動到最底下" -ForegroundColor:Yellow
            Write-Host $cmd
        }

        
        if (!$Force) {
            $response = Read-Host "  沒有異議請輸入Y (Y/N) ";
            if ($response -ne "Y" -or $response -ne "Y") { Write-Host "使用者中斷" -ForegroundColor:Red; return; }
        }

        Invoke-Expression $cmd
        Write-Host ""
        Write-Host "重新載入最新選單狀態：" -ForegroundColor:Yellow
        if ($Path) { $BCD = Get-BCD -Path:$Path } else { $BCD = Get-BCD }
        $BCD|Format-Table
        return
    }
} 
# BCD_Editor -Info
# BCD_Editor -Default 1
# BCD_Editor -Delete 2
# BCD_Editor -Times 5
# BCD_Editor -Description 2 "Windows 11  - 臨時系統"
# BCD_Editor -MoveToFirst 2
# BCD_Editor -MoveToLast 1

# BCD_Editor -Path:"B:\Boot\BCD" -Info
# BCD_Editor -Path:"X:\Boot\BCD" -Info
# BCD_Editor -Path:"B:\Boot\BCD" -Default 1
# BCD_Editor -Path:"A:\Boot\BCD" -Delete 1
# BCD_Editor -Path:"B:\Boot\BCD" -Times 5
# BCD_Editor -Path:"B:\Boot\BCD" -Description 2 "Windows 11"
# BCD_Editor -Path:"B:\Boot\BCD" -MoveToFirst 2
# BCD_Editor -Path:"B:\Boot\BCD" -MoveToLast 1

# BCD_Editor -Path:"B:\Boot\BCD" -Info
