DECLARE @BulkColumn VARCHAR(max)
SELECT @BulkColumn = REPLACE(BulkColumn, NCHAR(10),'§') FROM OPENROWSET (BULK 'C:\AOC2023\day05_example1.txt', SINGLE_CLOB) I
;

--parse, group and fill down
WITH pgf AS (
SELECT 
MAX(src) OVER ( PARTITION BY grp ORDER BY (SELECT 1)) src
,MAX(dst) OVER ( PARTITION BY grp ORDER BY (SELECT 1)) dst
,dst_range
,src_range
,lngth
,val
,grp
FROM (
	SELECT 
	val
	,brk
	,rn
	,COUNT(brk) OVER ( ORDER BY rn ) grp
	,IIF(PATINDEX('%[A-Z]%',val)>0 AND rn>1 , LEFT(val,CHARINDEX('-',val)-1), null) src
	,IIF(PATINDEX('%[A-Z]%',val)>0 AND rn>1 , STUFF(LEFT(val,CHARINDEX(' map:',val)-1), 1, CHARINDEX('to-',val)+2,'') , null) dst
	,CAST(IIF(PATINDEX('%[0-9]%',val)>0 AND rn>1 , REPLACE(REPLACE(PARSENAME(REPLACE(val,' ','.'),3), CHAR(13), ''), CHAR(10), ''), null) as BIGINT) dst_range
	,CAST(IIF(PATINDEX('%[0-9]%',val)>0 AND rn>1 , REPLACE(REPLACE(PARSENAME(REPLACE(val,' ','.'),2), CHAR(13), ''), CHAR(10), ''), null) as BIGINT) src_range
	,CAST(IIF(PATINDEX('%[0-9]%',val)>0 AND rn>1 , REPLACE(REPLACE(PARSENAME(REPLACE(val,' ','.'),1), CHAR(13), ''), CHAR(10), ''), null) as BIGINT) lngth
	FROM (
		SELECT 
			a.value val
			,IIF(LEN(a.value) < 2, '1',null) brk
			,ROW_NUMBER() OVER ( ORDER BY (SELECT 1)) rn
		FROM STRING_SPLIT(@BulkColumn, '§') a
	) x
) x
)

-- seeds
,seeds AS (
SELECT 
CAST(a.value AS BIGINT) val
,'seeds' as cat
FROM pgf
	CROSS APPLY STRING_SPLIT(REPLACE(REPLACE(pgf.val, CHAR(13), ''), CHAR(10), ''),' ') a
WHERE pgf.src is null AND a.value <> 'seeds:'
)

-- order 
,ordr AS (
SELECT DISTINCT src, dst, grp FROM PGF
)

-- prep for recursive query 

,base as (
SELECT 
 ordr.dst dst
,ordr.src as src
,ordr.grp
,CAST(ordr.src+': '+CAST(seeds.val as VARCHAR(10))+' | '+ordr.dst+': '+CAST(COALESCE(seeds.val + pgf.dst_range - pgf.src_range,seeds.val) AS varchar(20)) AS varchar(MAX)) pth
,seeds.val seed_val

,COALESCE(seeds.val + pgf.dst_range - pgf.src_range, seeds.val) newvalue
FROM seeds
	LEFT JOIN pgf
		ON pgf.dst = 'soil' AND seeds.val >= pgf.src_range AND seeds.val <= pgf.src_range + pgf.lngth
	LEFT JOIN ordr
		ON 1 = ordr.grp
)

--pt1 recursive query
,figure_it_out as(
SELECT
 dst
,src
,grp
,CAST(pth as VARCHAR(MAX)) pth
,seed_val
,1 as lvl
,newvalue

FROM base

UNION ALL

SELECT 
 ordr.dst dst
,ordr.src src
,ordr.grp
,fio.pth + ' | ' + ordr.dst+': '+CAST(fio.newvalue + ISNULL(pgf.dst_range,0) - ISNULL(pgf.src_range,0) AS varchar(20)) pth
,fio.seed_val seed_val
,fio.lvl+1 as lvl
,fio.newvalue + ISNULL(pgf.dst_range,0) - ISNULL(pgf.src_range,0) newvalue
FROM figure_it_out fio
	INNER JOIN ordr 
		ON ordr.grp = fio.lvl+1
	OUTER APPLY (select * from pgf where fio.dst = pgf.src 
				AND fio.newvalue >= pgf.src_range 
				AND fio.newvalue <= pgf.src_range + pgf.lngth) pgf
)

SELECT 
MIN(newvalue)
FROM figure_it_out
WHERE lvl = 7