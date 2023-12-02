DECLARE @BulkColumn VARCHAR(max)
SELECT @BulkColumn = REPLACE(BulkColumn, NCHAR(10),'|') FROM OPENROWSET (BULK 'C:\AOC2023\day02.txt', SINGLE_CLOB) I
;

WITH tbl AS (
SELECT 
CAST(REPLACE(STUFF(LEFT(a.value,CHARINDEX(':',a.value)),1,5,''),':','') AS INT) game
,b.value draws
,c.value cubes
,CAST(LEFT(c.value,CHARINDEX(' ',c.value,2)) AS INT) number
,RIGHT(c.value,LEN(c.value)-CHARINDEX(' ',c.value,2)) color
FROM STRING_SPLIT(@BulkColumn,'|') a
	CROSS APPLY STRING_SPLIT(RIGHT(a.value,LEN(a.value) - CHARINDEX(':',a.value)), ';') b
	CROSS APPLY STRING_SPLIT(b.value,',') c
WHERE c.value <> ''
)

--pt 1
SELECT 
SUM(DISTINCT game)
-SUM(DISTINCT(IIF((number > 12 AND color = 'red') OR (number > 13 AND color = 'green') OR (number > 14 AND color = 'blue'),game,null)))
FROM tbl

UNION ALL

--pt 2
SELECT
SUM(x.x) FROM
(
SELECT 
game
,MAX(IIF(color like '%red%', number, null))
*MAX(IIF(color like '%blue%', number, null))
*MAX(IIF(color like '%green%', number, null)) x
FROM tbl
GROUP BY game
) x
