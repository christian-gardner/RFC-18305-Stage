set lines 180
set pages 400
set echo on
set feedback on

spool rdm_rfc_18305_build.log

SET DEFINE OFF;


ALTER TABLE RDM.SQA_ICC_PRIOR_LOAN_HISTORY
 ADD (HISTORY_PID  NUMBER)
/



drop SEQUENCE SQA_ICC_PRIOR_LOAN_HISTORY_SEQ;

CREATE SEQUENCE SQA_ICC_PRIOR_LOAN_HISTORY_SEQ
  START WITH 400000
  MAXVALUE 9999999999999999999999999999
  MINVALUE 1
  NOCYCLE
  NOCACHE
  NOORDER
/

CREATE OR REPLACE TRIGGER SQA_ICC_PRIOR_LOAN_HISTORY_BI
BEFORE INSERT ON RDM.SQA_ICC_PRIOR_LOAN_HISTORY
FOR EACH ROW
DECLARE
  P_ID       number;
BEGIN

        SELECT SQA_ICC_PRIOR_LOAN_HISTORY_SEQ.NEXTVAL
        INTO P_ID
        FROM DUAL;
       :new.HISTORY_PID := P_ID;


END;
/

show errors

DECLARE 

--   TYPE SQA_DATA_ARCH IS RECORD (
--  PID    DBMS_SQL.NUMBER_TABLE,
--  ROWIDS  rowidArray
--)

R                  SQA_LOVS.SQA_DATA_ARCH;
GC                 SQA_LOVS.GenRefCursor;
SQL_STMT           VARCHAR2(32000 BYTE);
UPT_STMT           VARCHAR2(32000 BYTE);
CNT                NUMBER;

BEGIN



CNT := 0;
UPT_STMT := 'update SQA_ICC_PRIOR_LOAN_HISTORY set HISTORY_PID = :A WHERE ROWID = :B';

SQL_STMT := 'SELECT rownum as PID, ROWID';
SQL_STMT := SQL_STMT||' FROM SQA_ICC_PRIOR_LOAN_HISTORY ';


OPEN GC FOR SQL_STMT;
      LOOP

            FETCH GC BULK COLLECT INTO
                                   R.PID,
                                   R.ROWIDS;
            EXIT WHEN R.PID.count = 0;

               CNT := CNT + R.PID.COUNT;

               FOR  k in 1..R.PID.COUNT LOOP
                    EXECUTE IMMEDIATE UPT_STMT USING R.PID(k), R.ROWIDS(k);                                  
               END LOOP;
              commit;
                
              INSERT INTO BOA_PROCESS_LOG
                    (
                      PROCESS,
                      SUB_PROCESS,
                      ENTRYDTE,
                      ROWCOUNTS,
                      MESSAGE
                    )
             VALUES ( 'SQA_LOVS', 'SQA_ICC_LOAN_HISTORY ',SYSDATE, CNT, 'SETTING HISTORY_ID');
             COMMIT;


      END LOOP;

          INSERT INTO BOA_PROCESS_LOG
                (
                  PROCESS,
                  SUB_PROCESS,
                  ENTRYDTE,
                  ROWCOUNTS,
                  MESSAGE
                )
         VALUES ( 'SQA_LOVS', 'SQA_ICC_LOAN_HISTORY',SYSDATE, CNT, 'Complete');
         COMMIT;


END;
/

spool off;

