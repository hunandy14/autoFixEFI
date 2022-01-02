自動修復EFI啟動分區
===

輸入需要修復的 Windows 資料夾槽，程序會自動修復該磁碟中的EFI分區。  
  
下面指令預設的槽位是K槽，將硬碟接上電腦後請自行修改成對應的槽位。  
  
如何打開終端機：按下 `Win+X` 然後再按下 `A`   
  
```
irm "https://raw.githubusercontent.com/hunandy14/autoFixEFI/master/autoFixEFI.ps1" | iex
autoFixEFI -DriveLetter:K
```