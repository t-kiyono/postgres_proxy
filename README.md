# Postgres Proxy

## 概要

- 外部の共有データベースのプロキシとして動作するコンテナを立ち上げる
- 特定のテーブルのみコンテナ内に作成した実体のテーブルと差し替えることで自由にデータを編集可能にする
- 共有データベースに存在しないデータパターンの時の振る舞いを確認できる

## 手順

### `.env` ファイル作成

```text
DB_USER=ユーザー名
DB_PASS=パスワード
DB_NAME=データベース名
DB_SCHEMA=スキーマ名
REMOTE_HOST=外部サーバーのホスト名
REMOTE_PORT=外部サーバーのポート番号
REMOTE_USER=外部サーバーのユーザー名
REMOTE_PASS=外部サーバーのパスワード
```

### コンテナ起動

```bash
$ docker compose up -d
```

起動が完了するとリモートデータベースにプロキシするビューがローカルデータベースに作成される

### 特定のビューを実体テーブルに差し替える

ビューの削除

```sql
DROP VIEW テーブル名;
```

#### データが多い場合

pg_dump でデータを取得する

```bash
$ pg_dump -U ユーザー名 -h 外部サーバーのホスト名 -p 外部サーバーのポート番号 -d データベース名 --no-owner -x -t テーブル名 -f dump.sql
```

dump ファイルをリストアする

```bash
=# \i dump.sql
```

#### データが少ない場合

実体テーブルの作成

```sql
CREATE TABLE テーブル名 (LIKE origin_スキーマ名.テーブル名)
```

データ移行

```sql
INSERT INTO テーブル名 SELECT * FROM origin_スキーマ名.テーブル名
```

### 差し替えたテーブルを元に戻す

テーブルを削除する

```sql
DROP TABLE テーブル名
```

ビューを作成する

```sql
CREATE VIEW テーブル名 AS SELECT * FROM origin_スキーマ名.テーブル名
```
