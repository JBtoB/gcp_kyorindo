# biz-jbtob-kyorindo-etl
JBtoB-杏林堂薬局のDWH構築

機能としては以下のふたつ
1. GCSトリガーにより起動するbq load用のCloud Functions
2. 取り込んだBigQueryテーブルに対して洗替処理を行うScheduled Query
## schema.jsonの必須指定項目
schema.jsonには以下3つの項目について必ず指定する
"name"
"type"
"mode"
## Cloud Functions のデプロイ方法

### bq_load_jobのデプロイ
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
# App Engine アプリを作成(既に作成済みの場合はスキップ)
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
$ MESSAGE_BODY='{"target_project_id":"jbtob-looker-kyorindo-prd", "target_dataset":"looker_backup", "source_dataset":"looker","table_names":["brand","excode1","excode2","item","jan","maker","member","office","old_new_id","JICFS_item","transaction","transaction_summary","update", "Category_control", "weather_stn"]}'

# poc環境へのコピー用のとき
$ MESSAGE_BODY='{"target_project_id":"jbtob-looker-kyorindo-poc", "target_dataset":"looker", "source_dataset":"looker","table_names":["brand","excode1","excode2","item","jan","maker","member","office","old_new_id","JICFS_item","transaction","transaction_summary","update", "Category_control", "weather_stn"]}'


# Cloud Schdeulerのジョブを作成
$ gcloud scheduler jobs create http ${JOB} \
--schedule ${SCHEDULE} \
--uri ${URI} \
--http-method POST \
--time-zone Asia/Tokyo \
--message-body ${MESSAGE_BODY} \
--project ${project_id}
```

## BigQuery Procedureのデプロイ方法
```
$ project_id=[GCPプロジェクトID]

$ Procedureファイルのパスを指定(例: ./sql/Procedure/jan_table_create.sql)
procedure_path=[Procedureファイルのパス]

$ bq query --project_id=${project_id} \
--use_legacy_sql=false < ${procedure_path}
```

## Scheduled Queryのデプロイ方法
### Scheduled Queryのcreate_pos_data(scripting_procedure.sql)をデプロイ
```
$ project_id=[GCPプロジェクトID]

# Scheduled Queryに使用するサービスアカウントIDを指定
$ service_account_name=[サービスアカウントID]

$ bq mk --transfer_config \
--project_id=${project_id} \
--display_name=create_pos_data \
--data_source=scheduled_query \
--params='{"query": "CALL looker_procedure.scripting_procedure();"}' \
--schedule="everyday 22:00" \
--location=US \
--service_account_name=${service_account_name}
```
### Scheduled Queryのcreate_pos_data_retry1(scripting_retry_procedure.sql)をデプロイ
```
$ project_id=[GCPプロジェクトID]

# Scheduled Queryに使用するサービスアカウントIDを指定
$ service_account_name=[サービスアカウントID]

$ bq mk --transfer_config \
--project_id=${project_id}  \
--display_name=create_pos_data_retry1 \
--data_source=scheduled_query \
--params='{"query": "CALL looker_procedure.scripting_retry_procedure();"}' \
--schedule="everyday 22:40" \
--location=US \
--service_account_name=${service_account_name}
```

### Scheduled Queryのcreate_pos_data_retry2(scripting_retry_procedure.sql)をデプロイ
```
$ project_id=[GCPプロジェクトID]

# Scheduled Queryに使用するサービスアカウントIDを指定
$ service_account_name=[サービスアカウントID]

$ bq mk --transfer_config \
--project_id=${project_id}  \
--display_name=create_pos_data_retry2 \
--data_source=scheduled_query \
--params='{"query": "CALL looker_procedure.scripting_retry_procedure();"}' \
--schedule="everyday 23:20" \
--location=US \
--service_account_name=${service_account_name}
```

### Scheduled Queryのdelete_old_data(delete_old_data_monthly.sql)をデプロイ
```
$ project_id=[GCPプロジェクトID]

# Scheduled Queryに使用するサービスアカウントIDを指定
$ service_account_name=[サービスアカウントID]

$ bq mk --transfer_config \
--project_id=${project_id}  \
--display_name=delete_transaction_source_monthly \
--data_source=scheduled_query \
--params='{"query": "CALL looker_procedure.delete_old_data_monthly();"}' \
--schedule="first day of month 18:00" \
--location=US \
--service_account_name=${service_account_name}
```

## Cloud Build 手動実行方法
```
# Cloud Buildを実行させるプロジェクトを指定
project_id=[Cloud Buildを実行させるGCPプロジェクトID]

# Cloud Build 設定ファイルを指定
# 初回環境構築の場合: create_jbtob_kyorindo_etl.yaml 
# 更新の場合: update_jbtob_kyorindo_etl.yaml 
config_file=[Cloud Build設定ファイル名]

# タグ名を指定
# 初回環境構築の場合: create-${初回構築をするGCPプロジェクトID}-YYYYmmdd-${その日のtagのpush回数}
# 更新の場合: update-${更新するGCPプロジェクトID}-YYYYmmdd-${その日のtagのpush回数}
# ※ここで使用するGCPプロジェクトIDは、jbtob-looker-${JBTOBプロジェクト名}-${環境名}　の形式である必要がある。
# 例: tag_name="update-jbtob-looker-kyorindo-stg-20200801-1"
tag_name="[ダグ名]"

gcloud builds submit --project=${project_id} \
--config=${config_file} \
--substitutions=TAG_NAME=${tag_name}  .
```
