DECLARE @BulkColumn VARCHAR(max)
SELECT @BulkColumn = REPLACE(BulkColumn, NCHAR(10),'|') FROM OPENROWSET (BULK 'C:\AOC2023\day01.txt', SINGLE_CLOB) I
;
WITH CTE AS (
SELECT 
value
,REPLACE(
	REPLACE(
		REPLACE(
			REPLACE(
				REPLACE(
					REPLACE(
						REPLACE(
							REPLACE(
								REPLACE(value, 'one', 'o1e')
									, 'two', 't2o')
								,'three', 't3e')
							,'four', 'f4e')
						,'five', 'f5e')
					,'six', 's6x')
				,'seven', 's7n')
			,'eight', 'e8t')
		,'nine', 'n9e') value2
FROM STRING_SPLIT(@BulkColumn,'|')
)

SELECT 
SUM(CAST(SUBSTRING(Value,PATINDEX('%[0-9]%',value),1)+SUBSTRING(REVERSE(value),PATINDEX('%[0-9]%',REVERSE(value)),1) AS BIGINT)) pt1
,SUM(CAST(SUBSTRING(Value2,PATINDEX('%[0-9]%',value2),1)+SUBSTRING(REVERSE(value2),PATINDEX('%[0-9]%',REVERSE(value2)),1) AS BIGINT)) pt2
FROM CTE
