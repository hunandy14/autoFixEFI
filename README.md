自動修復 Windows 啟動分區
===

打開終端機：按下 `Win+X` 然後再按下 `A`   
</br></br>

## 自動修復開機引導 (EFI+MBR)
```
irm bit.ly/340Pi6W|iex; autoFixBoot E
```
</br>

![](img/autoFixBoot-MBR.png)


#### 注意事項
預設會把啟動分區掛載到 B 曹位，如果該曹位已經被占用了，還沒寫防呆會直接報錯失敗。




</br></br></br>

## 安裝 DiskGenius
```
irm bit.ly/340Pi6W|iex; Install-DiskGenius
```






</br></br></br></br></br>

## 自動修復EFI引導
```
irm bit.ly/3EQwFzs|iex; autoFixEFI E
```
</br>

![](img/autoFixEFI.png)


## 自動修復MBR引導
```
irm bit.ly/3rk6Jrk|iex; autoFixMBR E
```
</br>

![](img/autoFixMBR.png)


