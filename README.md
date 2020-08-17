# biz-jbtob-kyorindo-etl
JBtoB-杏林堂薬局のDWH構築

機能としては以下のふたつ\
1. GCSトリガーにより起動するbq load用のCloud Functions
2. 取り込んだBigQueryテーブルに対して洗替処理を行うScheduled Query
## schema.jsonの必須指定項目
schema.jsonには以下3つの項目について必ず指定する
"name"
"type"
"mode"
## Cloud Functions のデプロイ方法

以下のコマンドを実行する
```
$ project_id=[GCPプロジェクトID]


  # dev/stg/prd のいづれか
$ env=[環境名]
  # トリガーとなるバケットの名前
$ bucket=jbtob-kyorindo-from-sybase-${env}

$ region=us-central1

  # Cloud Functions/bq_load_jobフォルダ内に移動し以下のコマンドを実行
$ gcloud functions deploy bq_load_job \
    --entry-point main \
    --project ${project_id} \
    --trigger-resource ${bucket} \
    --region ${region} \
    --trigger-event google.storage.object.finalize \
    --runtime python37 \
    --timeout 540s

  # bq load の際に使用するスキーマ・設定ファイルをGCSバケットにインポートする必要があるため、以下のコマンドを実行
$ gsutil cp -r ../settings/ gs://${bucket}-setting/
```


## Scheduled Queryのデプロイ方法
後で追記
