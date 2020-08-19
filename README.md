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

### bq_load_jbのデプロイ
以下のコマンドを実行する
```
$ project_id=[GCPプロジェクトID]


# dev/stg/prd のいづれか
$ env=[環境名]
# トリガーとなるバケットの名前
$ bucket=jbtob-kyorindo-from-sybase-${env}

$ region=us-central1

# CloudFunctions/bq_load_jobフォルダ内に移動
$ cd ./CloudFunctions/bq_load_job

# 以下のコマンドを実行し、Cloud Functionsをデプロイ
$ gcloud functions deploy bq_load_job \
    --entry-point main \
    --project ${project_id} \
    --trigger-resource ${bucket} \
    --region ${region} \
    --trigger-event google.storage.object.finalize \
    --runtime python37 \
    --timeout 540s

＃ bq load の際に使用するスキーマ・設定ファイルをGCSバケットにインポートする必要があるため、以下のコマンドを実行
$ gsutil cp -r ../../settings/ gs://${bucket}-setting/
```
### bq_load_tableのデプロイ
以下のコマンドを実行する
```
$ project_id=[GCPプロジェクトID]

# dev/stg/prd のいづれか
$ env=[環境名]

$ region=us-central1

# テーブルのバックアップ用のときは、bq_copy_job
# poc環境へのコピー用のときは、bq_copy_job_${env}_to_poc
$ function_name=[登録名]

# Cloud Functions/bq_load_jobフォルダ内に移動
$ cd ./CloudFunctions/bq_copy_table

#以下のコマンドを実行し、Cloud Functionsをデプロイ
$ gcloud functions deploy ${function_name} \
    --entry-point main \
    --project ${project_id} \
    --trigger-http\
    --region ${region} \
    --runtime python37 \
    --timeout 540s
```

## Cloud Scheduler のデプロイ方法
```
# Cloud Functionsを起動させるためのCloud Scheduler設定
# App Engine アプリを作成
$ gcloud app create --region=us-central

# Cloud Schedulerのジョブの名前
# テーブルのバックアップ用のときは、bq_copy_job_kicker
# poc環境へのコピー用のときは、copy_job_${env}_to_poc
$ JOB=[ジョブ名]

# ジョブを実行するスケジュールを指定
$ SCHEDULE="0 9 * * *"

# Cloud Functionsのbq_copy_jobまたはbq_copy_job_${env}_to_pocのURL
$ URI=[Cloud FunctionsのURL]

# HTTPリクエストのボディ
# テーブルのバックアップ用のとき
$ MESSAGE_BODY=‘{“target_project_id”:“jbtob-looker-kyorindo-prd”, “target_dataset”:“looker_backup”, “source_dataset”:“looker”,“table_names”:[“brand”,“excode1”,“excode2",“item”,“jan”,“maker”,“member”,“office”,“old_new_id”,“JICFS_item”,“transaction”,“transaction_summary”,“update”]}’

# poc環境へのコピー用のとき
$ MESSAGE_BODY=‘{“target_project_id”:“jbtob-looker-kyorindo-poc”, “target_dataset”:“looker”, “source_dataset”:“looker”,“table_names”:[“brand”,“excode1”,“excode2",“item”,“jan”,“maker”,“member”,“office”,“old_new_id”,“JICFS_item”,“transaction”,“transaction_summary”,“update”]}’


# Cloud Schdeulerのジョブを作成
$ gcloud scheduler jobs create http ${JOB} \
--schedule ${SCHEDULE} \
--uri ${URI} \
--http-method POST \
--time-zone Asia/Tokyo \
--message-body ${MESSAGE_BODY}
```

## Scheduled Queryのデプロイ方法
後で追記
