
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
    if ($Boot -ne "GPT") {
        irm "https://raw.githubusercontent.com/hunandy14/autoFixEFI/master/autoFixEFI.ps1"|iex
        autoFixEFI -DriveLetter:$DriveLetter -Force:$Force
    } elseif ($Boot -ne "MBR") { 
        irm "https://raw.githubusercontent.com/hunandy14/autoFixEFI/master/autoFixMBR.ps1"|iex
        autoFixMBR -DriveLetter:$DriveLetter -Force:$Force
    }
}