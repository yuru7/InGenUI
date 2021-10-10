## ソースフォントを作る

- 英数字: Inter
- その他文字: 源真ゴシックP
  - Fontforge
    - EM: 2816 に設定する
  - fonttools (pyftsubset)
    - vhea テーブルの削除

```
pyftsubset EM2816_GenShinGothic-P-Regular.ttf '*' --drop-tables+=vhea --drop-tables+=vmtx
```

## 合成

```
pyftmerge 'Inter-3.19/Inter Hinted for Windows/Desktop/Inter-Regular.ttf' EM2816_GenShinGothic-P-Regular.subset.ttf

ttx -t name -t OS/2 merged.ttf

mv merged.ttx InGenUI-Regular.ttx

vim InGenUI-Regular.ttx
# 編集...

ttx -m merged.ttf InGenUI-Regular.ttx
```

## Narrow版

x 方向を0.9倍