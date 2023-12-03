DECLARE @BulkColumn VARCHAR(max)
SELECT @BulkColumn = REPLACE(BulkColumn, NCHAR(10),'|') FROM OPENROWSET (BULK 'C:\AOC2023\day03.txt', SINGLE_CLOB) I
;
DROP TABLE IF EXISTS #tmp;
SELECT 
	a.value
	,ROW_NUMBER() OVER (PARTITION BY b.value ORDER BY (SELECT 1)) y
	,b.value x
	,SUBSTRING(a.value, b.value, 1) val
	,PATINDEX('[0-9]', SUBSTRING(a.value, b.value, 1)) isnumber
	,PATINDEX('[^0-9]', SUBSTRING(REPLACE(a.value,'.','1'), b.value, 1)) issymbol
	,PATINDEX('[*]', SUBSTRING(a.value, b.value, 1)) isgear
	,b.value-DENSE_RANK() OVER ( PARTITION BY a.value,PATINDEX('[0-9]', SUBSTRING(a.value, b.value, 1)) ORDER BY b.value ) dr
INTO #tmp
FROM STRING_SPLIT(@BulkColumn, '|') a
	--create grid
	CROSS APPLY GENERATE_SERIES(1,140) b;

--create a query to group together the numbers
WITH GRP AS (
SELECT
y,dr,minx,maxx,SUBSTRING(value,minx,maxx-minx+1) number 
FROM (
	SELECT 
	value,dr,y,min(x) minx,max(x) maxx
	FROM #tmp
	WHERE isnumber = 1
	GROUP BY value, y, dr) x
)

--pt1: figure out where the numbers hit a symbol in the grid
SELECT SUM(nbr) 
FROM (
SELECT DISTINCT CTE2.y, grp.dr, cast(grp.number as int) nbr
FROM #tmp CTE
	INNER JOIN #tmp CTE2
		ON CTE2.isnumber = 1
		AND CTE2.y BETWEEN CTE.y-1 AND CTE.y+1
		AND CTE2.x BETWEEN CTE.x-1 AND CTE.x+1
	LEFT JOIN GRP
		ON CTE2.y = grp.y
		AND CTE2.dr = grp.dr
WHERE CTE.issymbol = 1
) x

UNION ALL

--pt2: figure out where the numbers hit a gear in the grid
SELECT SUM(minn*maxn)
FROM (
	SELECT x,y,cast(min(number) as int) minn, cast(max(number) as int) maxn, COUNT(1) CNT
	FROM (
		SELECT DISTINCT number, cte.x, cte.y
		FROM #tmp CTE
			INNER JOIN #tmp CTE2
				ON CTE2.isnumber = 1
				AND CTE2.y BETWEEN CTE.y-1 AND CTE.y+1
				AND CTE2.x BETWEEN CTE.x-1 AND CTE.x+1
			LEFT JOIN GRP
				ON CTE2.y = grp.y
				AND CTE2.dr = grp.dr
		WHERE CTE.isgear = 1
		) x
	GROUP BY x, y
	) x
WHERE CNT = 2
