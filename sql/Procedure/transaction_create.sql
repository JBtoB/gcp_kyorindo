CREATE OR REPLACE PROCEDURE `looker_procedure.transaction_create`()
BEGIN    
    
    # 中間テーブルから売上テーブルを作成
    CREATE OR REPLACE TABLE
      `looker.transaction`
    PARTITION BY
      DATE(purchase_timestamp) 
      AS
    WITH tmp AS(
    SELECT
      TIMESTAMP_SUB(PARSE_TIMESTAMP('%Y%m%d%H%M%S', CONCAT(purchase_date, purchase_time)), INTERVAL 9 hour) AS purchase_timestamp,
      * EXCEPT(purchase_date, purchase_time)
    FROM
      looker.transaction_source
      )  
    SELECT
       purchase_timestamp,
      DATE(purchase_timestamp) AS purchase_date,
      TIME(purchase_timestamp) AS purchase_time,
      * EXCEPT(purchase_timestamp)
    FROM
      tmp;
END;      