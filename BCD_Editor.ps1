# 獲取BCD物件 (新版)
function Get-BootConfigurationData {
    [Alias("Get-BcdItem")]
    param (
        [Parameter(Position = 0, ParameterSetName = "")]
        [string] $Path,
        [Parameter(ParameterSetName = "")]
        [switch] $Enum
    )
    # BCD物件清單
    $BCD_List = @()
    
    # 使用 PowerShell 命令讀取當前的 BCD 並將其輸出保存到變數
    if ($Path) {
        [IO.Directory]::SetCurrentDirectory(((Get-Location -PSProvider FileSystem).ProviderPath))
        $Path = [IO.Path]::GetFullPath($Path)
        if (Test-Path -PathType Leaf $Path) {
            $lines = bcdedit /store $Path
        } else { Write-Error "找不到 '$Path' 路徑, 因為它不存在" -ErrorAction Stop; }
    } else {
        $lines = bcdedit /enum
    }

    # 找到 keyWord 的位置
    $keyWord = "{bootmgr}"
    $wordLine = & { foreach ($line in $lines) { if ($line -match [Regex]::Escape($keyWord)) { $line; break } } }
    if(!$wordLine){
        Write-Error (($lines -replace '^', '  ') -join "`r`n" + "`r`n")
        Write-Error "命令 'bcdedit /enum' 沒有獲取到有效的 BCD 物件, 可能是權限不足導致" -ErrorAction Stop
    }; $splitIndex = $wordLine.IndexOf($keyWord)

    # 所需變數
    $currentDict = New-Object PSObject
    $blockStart = $false
    $previousLine = ""

    # 遍歷每一行
    foreach ($line in $lines) {
        # 如果該行僅包含 '-', 則開始新的區塊
        if ($line -and ($line.Trim() -eq "-" * $line.Trim().Length)) {
            # 如果當前字典有資料，則添加到最終列表中
            if ($currentDict.PSObject.Properties.Name.Count -gt 0) {
                $BCD_List += $currentDict
            }
    
            # 開始新的字典並添加標題
            $currentDict = New-Object PSObject
            $currentDict | Add-Member -Type NoteProperty -Name "Title" -Value $previousLine.Trim()
            $blockStart = $true
            $previousLine = ""
        }
        # 如果當前正在處理區塊，則將當前行添加到字典
        elseif ($blockStart -and $line.Trim()) {
            $key = $line.Substring(0, $splitIndex).Trim()
            $value = $line.Substring($splitIndex).Trim()
            if ($key -eq "") {
                $key = $previousLine.Substring(0, $splitIndex).Trim()
                $currentDict.$key = @($currentDict.$key, $value)
            } else {
                $currentDict | Add-Member -Type NoteProperty -Name $key -Value $value
            }
        }
        # 如果當前行為空，則結束區塊
        elseif ($blockStart -and -not $line.Trim()) {
            $blockStart = $false
        }
    
        # 記錄上一行 (獲取區塊標題, 與檢查空白KEY捕到上一個判斷用)
        $previousLine = $line
    }
    
    # 將最後一個區塊添加到最終列表
    if ($currentDict.PSObject.Properties.Name.Count -gt 0) {
        $BCD_List += $currentDict
    }
    
    # 添加 WindowsBootManager 到最終的結果
    if (!$Enum) {
        $WindowsBootManager = $BCD_List[0]
        $WindowsBootManager | Add-Member -Type NoteProperty -Name "WindowsBootLoader" -Value ($BCD_List[1..$($BCD_List.Count - 1)])
        return $WindowsBootManager
    } else {  
        return $BCD_List
    }
} # Get-BcdItem -Enum



# 獲取BCD物件
function Get-BCD {
    [CmdletBinding(DefaultParameterSetName = "")]
    param (
        [Parameter(Position = 0, ParameterSetName = "")]
        [string] $Path,
        [Parameter(ParameterSetName = "")]
        [switch] $FormatOut,
        [Parameter(ParameterSetName = "")]
        [switch] $DefaultLoder,
        [Parameter(ParameterSetName = "")]
        [switch] $CurrentLorder
    )
    # BCD 物件
    $BCD_Object = @()

    # 解析 BCD
    if ($Path) {
        $BCD_Context = bcdedit /store $Path
    } else { $BCD_Context = bcdedit }
    $BCD = ($BCD_Context+"`r`n").Split("`r`n")
    $BootCount = ($BCD|Select-String -AllMatches "identifier").Count
    $BCDHeadLine = $BCD | Select-String -Pattern "identifier"

    # 解析 BCD 選單
    for ($j = 0; $j -lt $BootCount; $j++) {
        $Star = $BCDHeadLine[$j].LineNumber - 1
        $PreKey = ""
        $LoderObj = [PSCustomObject]@{
            number = $j
            title  = $BCD[($Star-2)]
        }
        for ($i = 0; $i -lt $BCD.Count; $i++) {
            $Line = $BCD[$Star+$i]
            if (!$Line) {
                break # 空行或Null結束該區塊
            } else {
                $offset = 24 # Key與Value區隔位置
                $Attr   = $Line.Substring(0,$offset).trim()
                $Value  = $Line.Substring($offset,$Line.Length-$offset).trim()
                # 遇到空白Key表示是連著上一個Key陣列的屬性
                if ($Attr -eq "") { # 新值以陣列形式添加到前一個屬性
                    $LoderObj.$PreKey = ($LoderObj.$PreKey), $Value
                } else { # 增加新屬性與值
                    $LoderObj | Add-Member -MemberType NoteProperty -Name $Attr -Value $Value
                    $PreKey = $Attr
                }
            }
        } $BCD_Object += $LoderObj
    }

    # 設置秒數
    $timeout = $BCD_Object[0].timeout
    $BCD_Object[0].number = "# [t:$timeout"+"s]"

    # 改變預設輸出模式
    $DefaultProps = @('number','description','device','identifier')
    $DefaultDisplay = New-Object System.Management.Automation.PSPropertySet("DefaultDisplayPropertySet",[string[]]$DefaultProps)
    $PSStandardMembers = [System.Management.Automation.PSMemberInfo[]]@($DefaultDisplay)
    $BCD_Object | Add-Member MemberSet PSStandardMembers $PSStandardMembers
    
    # 格式化輸出終端機
    if ($FormatOut) {
        $BCD_Object|Format-Table number,description,@{Name='partition'; Expression={($_.device -replace"partition=", "")}},identifier
        return
    } elseif ($DefaultLoder) {
        $DstName = $BCD_Object[0].default
        $BCD_Object = $BCD_Object|Where-Object{$_.identifier -contains $DstName}
    } elseif ($CurrentLorder) {
        $DstName = '{current}'
        $BCD_Object = $BCD_Object|Where-Object{$_.identifier -contains $DstName}
    }

    # 輸出選單
    return $BCD_Object
}
# Get-BCD
# (Get-BCD)|select *
# Get-BCD -Path:"B:\Boot\BCD"
# Get-BCD -FormatOut
# Get-BCD -DefaultLoder
# Get-BCD -CurrentLorder



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
