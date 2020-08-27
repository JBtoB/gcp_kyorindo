CREATE OR REPLACE PROCEDURE `looker_procedure.scripting_retry_procedure`()

BEGIN
    # standard SQL
    # 
    # 

    # 
    DECLARE check_error, job_state STRING;
    # 
    CALL looker_procedure.retry(check_error,job_state);

    # 
    # 
    IF (check_error is not null
    OR job_state != 'DONE')
    THEN

        CALL looker_procedure.scripting_procedure();
        
    END IF;
END;