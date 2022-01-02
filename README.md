<!--
 * @Author: your name
 * @Date: 2022-01-02 19:46:35
 * @LastEditTime: 2022-01-02 20:05:04
 * @LastEditors: Please set LastEditors
 * @Description: 打开koroFileHeader查看配置 进行设置: https://github.com/OBKoro1/koro1FileHeader/wiki/%E9%85%8D%E7%BD%AE
 * @FilePath: \autoFixEFI\README.md
-->
自動修復EFI啟動分區
===

輸入需要修復的 Windows 資料夾槽，程序會自動修復該磁碟中的EFI分區。  
  
下面指令預設的槽位是K槽，將硬碟接上電腦後請自行修改成對應的槽位。  
  
如何打開終端機：按下 `Win+X` 然後再按下 `A`   
  
```
irm "https://raw.githubusercontent.com/hunandy14/autoFixEFI/master/autoFixEFI.ps1" | iex
autoFixEFI -DriveLetter:K
```

短網址指令

```
(irm https://bit.ly/3EQwFzs|iex);autoFixEFI "K"
```

## 注意事項
預設會把EFI分區掛載到 X 曹位，如果該曹位已經被占用了，還沒寫防呆會直接報錯失敗。