# ���BCD����
function Get-BCD {
    param (
        
    )
    $BCD_Object = @()
    # �ѪR BCD
    $BCD = (bcdedit).Split("`n")
    $BootCount = ($BCD|Select-String -AllMatches "identifier").Count-1
    $obj = $BCD | Select-String -Pattern "identifier"

    # �p�� Loder �ݩʼƶq
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

    # �ѪR BCD ���Y
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

    # �ѪR BCD ���
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
    # ���ܹw�]��X�Ҧ�
    $DefaultProps = @('Number','description','device','resumeobject')
    $DefaultDisplay = New-Object System.Management.Automation.PSPropertySet("DefaultDisplayPropertySet",[string[]]$DefaultProps)
    $PSStandardMembers = [System.Management.Automation.PSMemberInfo[]]@($DefaultDisplay)
    $BCD_Object | Add-Member MemberSet PSStandardMembers $PSStandardMembers
    
    return $BCD_Object
} # Get-BCD
function __Get-BCD_Tester__ {
    param (
        
    )
    # ������X�ݵ��G
    # Get-BCD
    # ����RE����
    # (Get-BCD)[1].recoveryenabled
    # ����w�]���
    # $default = (Get-BCD)|Where-Object{$_.identifier -contains ((Get-BCD)[0].default)}
    # $default|Format-Table Number,description,@{Name='Letter'; Expression={$_.device -replace"partition=", ""}},resumeobject
    # �����e�t��
    # $current = (Get-BCD)|Where-Object{$_.identifier -contains '{current}'}
    # $current|Format-Table Number,description,@{Name='Letter'; Expression={$_.device -replace"partition=", ""}},resumeobject
} # __Get-BCD_Tester__

function __BootList__ {
    param (
        
    )
    # �ѪR BCD
    $BCD = (bcdedit).Split("`n")
    $BootCount = ($BCD|Select-String -AllMatches "identifier").Count-1
    $obj = $BCD | Select-String -Pattern "identifier"

    # �p�� Loder �ݩʼƶq
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

    # �ѪR BCD ���Y
    $BootHeader = @()
    $Item = @{}
    for ($i = 0; $i -lt $HeadCount; $i++) {
        $Line = $BCD[3+$i]
        $Attr = $Line.Substring(0,24).trim()
        $Value = $Line.Substring(24,$Line.Length-24).trim()
        $Item += @{ $Attr = $Value}
    } $Item = $Item|ForEach-Object { New-Object object | Add-Member -NotePropertyMembers $_ -PassThru }
    $BootHeader += @($Item)

    # �ѪR BCD ���
    $BootLoader = @()
    for ($j = 0; $j -lt $BootCount; $j++) {
        $Star = ($j*$BootCount)+$Offset
        $Item = @{Number = $i+1}
        for ($i = 0; $i -lt $AttrCount; $i++) {
            $Line = $BCD[$Star+$i]
            $Attr = $Line.Substring(0,24).trim()
            $Value = $Line.Substring(24,$Line.Length-24).trim()
            $Item += @{ $Attr = $Value}
        } $Item = $Item|ForEach-Object { New-Object object | Add-Member -NotePropertyMembers $_ -PassThru }
        $BootLoader += @($Item)
    }
    # return $BootLoader
} 
(__BootList__)
#  (__BootList__)|Format-Table Number,description,@{Name='Letter'; Expression={$_.device -replace"partition=", ""}},resumeobject

function __Boot_Print__ {
    param (
        [System.Object] $Boot
    )
    if (!$Boot) { $Boot = __BootList__ }
    ($Boot)|Format-Table Number,description,@{Name='Letter'; Expression={$_.device -replace"partition=", ""}},resumeobject
} # __Boot_Print__


# __Boot_Print__ (__BootList__)



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
    # �ѪR BCD ���
    $BootList = __BootList__
    $BootID = $BootList[$Index-1].resumeobject
    
    # �קﵥ�ݮɶ�
    if ($Times) { bcdedit /timeout $Times }
    
    # �d�ݿ��
    if ($Info) {
        __Boot_Print__ $BootList
    }
    # �R�����
    if ($Delete) {
        __Boot_Print__ $BootList[$Index-1]
        Write-Host " �Y�N�R���W�z���" -ForegroundColor:Yellow
        if (!$Force) {
            $response = Read-Host "  �S����ĳ�п�JY (Y/N) ";
            if ($response -ne "Y" -or $response -ne "Y") { Write-Host "�ϥΪ̤��_" -ForegroundColor:Red; return; }
        }
        bcdedit /delete $BootID
        Write-Host ""
        # ���sŪ��BCD���
        Write-Host "���s���J�̷s��檬�A�G"
        __Boot_Print__
    } 
    
    # �ܧ�w�]���
    elseif ($Default) {
        "bcdedit /default $BootID"
        
        Write-Host "���s���J�̷s��檬�A�G" -ForegroundColor:Yellow
        __Boot_Print__
    }
}
# BCD_Editor -Default 1

# $BootList

