自動修復 Windows 啟動分區
===

打開終端機：按下 `Win+X` 然後再按下 `A`   
</br></br>

## 自動修復開機引導 (EFI+MBR)
```
irm autofixboot.github.io|iex; autoFixBoot E
```
</br>

![](img/autoFixBoot-MBR.png)


#### 注意事項
預設會把啟動分區掛載到 B 曹位，如果該曹位已經被占用了，還沒寫防呆會直接報錯失敗。




</br></br></br>

## 安裝 DiskGenius
```
irm autofixboot.github.io|iex; Install-DiskGenius
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


## 分離MBR的啟動磁區
```
irm bit.ly/3rk6Jrk|iex; CreateBootPartition
```

## 修改BCD選單
```

# 查看當前開機選單
irm bit.ly/3IkqdmO|iex; BCD_Editor -Info

# 設置開機選單時間
irm bit.ly/3IkqdmO|iex; BCD_Editor -Times:1

# 刪除2號選單
irm bit.ly/3IkqdmO|iex; BCD_Editor -Delete 2

# 設置2號為預設
irm bit.ly/3IkqdmO|iex; BCD_Editor -Default 2
# 修改2號選單的描述
irm bit.ly/3IkqdmO|iex; BCD_Editor -Description 2 "Windows 99"

# 移動2號選單到最頂部
irm bit.ly/3IkqdmO|iex; BCD_Editor -MoveToFirst 2
# 移動2號選單到最底下
irm bit.ly/3IkqdmO|iex; BCD_Editor -MoveToLast 2
```

```
# 查看當前開機選單
irm bit.ly/3IkqdmO|iex; Get-BCD -FormatOut

# 查看預設系統
irm bit.ly/3IkqdmO|iex; Get-BCD -DefaultLoder

# 查看當前系統
irm bit.ly/3IkqdmO|iex; Get-BCD -CurrentLorder
```

修改其他BCD文件

```
# 查看其他硬碟 E 曹的 BCD 文件
irm autofixboot.github.io|iex; MountBoot E
irm bit.ly/3IkqdmO|iex; BCD_Editor -Path:B:\EFI\Microsoft\Boot\BCD -Info
```


## 修復RE分區 (開進目標系統執行才有用)

```
reagentc /enable
reagentc /disable
reagentc /setreimage /path C:\windows\system32\recovery
reagentc /enable
reagentc /info
```