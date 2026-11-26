# Gyaim (Swift 版)

[GyaimMotion](../) を Swift と InputMethodKit で書き直したものです。RubyMotion がなくても Xcode の Command Line Tools だけでビルドできます。

## インストール

```sh
cd swift
make install
```

その後「システム設定 > キーボード > 入力ソース > 編集」で「+」を押し、日本語の中から Gyaim を追加します。初回はログアウトとログインが必要なことがあります。

## 使い方

- ローマ字を打つと候補が出ます。スペースで次の候補、BS で前の候補に戻ります。
- 1番目の候補のまま Enter を押すと、ひらがな・カタカナと完全一致の候補に切り替わります。
- 末尾に `.` を付けると Google 日本語変換の候補を出します。
- `ds` で現在の日時を入力します。
- 文字列を選択してから読みを打ち、その文字列を確定すると個人辞書に登録します。
- 辞書は元の版と同じ `~/.gyaim/localdict.txt` と `~/.gyaim/studydict.txt` を使います。

## 元の版から外したもの

Gyazo 画像の入力、色画像 (`#`)、画像検索 (`!`)、暗号化単語 (`?`) は移植していません。
画像系は System Events のキー操作の再現に頼っていて壊れやすく、画像検索は元の版でも動いていませんでした。

## 構成

- `Sources/GyaimCore` 変換エンジン (ローマ字かな変換、接続辞書、学習、入力状態)。AppKit に依存せず Linux でもテストできます。
- `Sources/Gyaim` InputMethodKit のコントローラと候補ウィンドウ。
