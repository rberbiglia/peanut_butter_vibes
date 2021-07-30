------------------------------------------------------
-- Berbiglia, Data Analyst
-- Part 2 Write query to answer questions
-- Using Postgres
------------------------------------------------------

------------------------------------------------------
--Q1: Top 5 brands, by spend
--My inital thought was this question was asking for spend on scanned receipts
------------------------------------------------------
WITH receipt_lines AS
(
        SELECT DISTINCT rlf.receiptsid,
                        rlf.item_dim_id
        FROM            receipts_lines_fact rlf 
)
, brands AS
(
       SELECT item_dim_id,
              "rewardsReceiptItemList.brandCode" AS brand
       FROM   items_dim
       WHERE  item_dim_id <> ''
       AND    "rewardsReceiptItemList.brandCode" <> '' 
) 
, receipt_item AS
(
      SELECT DISTINCT r.receiptsid,
                      b.brand
      FROM            receipt_lines r
      INNER JOIN      brands b
      ON              r.item_dim_id = b.item_dim_id 
) 
, filter_data AS
(
           SELECT     rf.totalspent as total_spend,
                      r.*
           FROM       receipt_item r
           INNER JOIN receipts_fact rf
           ON         r.receiptsid = rf.receiptsid
           WHERE      rf.datescanned BETWEEN '2021-01-01' AND '2021-01-31'
)
          
SELECT   brand,
         Sum(total_spend) as total_spend
FROM     filter_data
GROUP BY brand
ORDER BY total_spend DESC 
limit 5

------------------------------------------------------
--Q1: Top 5 brands, by receipt count
--But then I thought maybe it was just the count of receipts scanned
------------------------------------------------------
WITH receipt_lines AS
(
        SELECT DISTINCT rlf.receiptsid,
                        rlf.item_dim_id
        FROM            receipts_lines_fact rlf 
)
, brands AS
(
       SELECT item_dim_id,
              "rewardsReceiptItemList.brandCode" AS brand
       FROM   items_dim
       WHERE  item_dim_id <> ''
       AND    "rewardsReceiptItemList.brandCode" <> '' 
) 
, receipt_item AS
(
      SELECT DISTINCT r.receiptsid,
                      b.brand
      FROM            receipt_lines r
      INNER JOIN      brands b
      ON              r.item_dim_id = b.item_dim_id 
) 
, filter_data AS
(
           SELECT     r.*
           FROM       receipt_item r
           INNER JOIN receipts_fact rf
           ON         r.receiptsid = rf.receiptsid
           WHERE      rf.datescanned BETWEEN '2021-01-01' AND '2021-01-31'
)

SELECT   brand,
         Count(receiptsid) AS total_spend
FROM     filter_data
GROUP BY brand
ORDER BY total_spend DESC limit 5


------------------------------------------------------
--Q3 Accepted/Rejected averge spend
--I don't see a status of 'Accepted' in the data
--So, I used 'Finished' instead
--Finished has a higher spend than Rejected

--Q4 Accepted/Rejected total items purchased
--Finished has more items purchased than Rejected
------------------------------------------------------
WITH numerator AS 
(		SELECT rewardsreceiptstatus,
                SUM(totalspent)::float         AS total_spend,
                SUM(purchaseditemcount)::float AS item_count
         FROM   receipts_fact rf
         GROUP  BY rewardsreceiptstatus
)
, denominator AS 
(
		SELECT rewardsreceiptstatus,
                Count(receiptsid) AS receipt_count
         FROM   receipts_fact rf
         GROUP  BY rewardsreceiptstatus
)
         
SELECT n.rewardsreceiptstatus,
       total_spend / receipt_count AS avg_spend,
       item_count  AS total_items_purchased
FROM   numerator n
       inner join denominator d ON n.rewardsreceiptstatus = d.rewardsreceiptstatus
WHERE  d.rewardsreceiptstatus IN ( 'FINISHED', 'REJECTED' ) 



------------------------------------------------------
-- Part 3 Evaluate Data Quality Issues
------------------------------------------------------

------------------------------------------------------
-- Does the total spent amount on the receipt match the amount of the items totaled together?
-- There are 13 rows (1%) that have differences
------------------------------------------------------

with receipt as (
select receiptsid, totalspent as total_receipt_amt
from receipts_fact rf )
, receipt_lines as (
select receiptsid, sum("rewardsReceiptItemList.finalPrice") as total_line_amt
from receipts_lines_fact rlf
group by receiptsid )
select r.receiptsid, total_receipt_amt, total_line_amt, (total_receipt_amt - total_line_amt) as diff 
from receipt r 
inner join receipt_lines rl on r.receiptsid = rl.receiptsid
where (total_receipt_amt - total_line_amt) <> 0


------------------------------------------------------
--The data has no records with a scanned date in Dec 2020
--Hard to know but I'm wondering how complete the data is because counts are very low for Oct, Nov and March
------------------------------------------------------
select distinct month_start, count(1) as receipt_count
from receipts_fact rf 
inner join date_dim dd on dd.full_date = rf.datescanned 
group by month_start


------------------------------------------------------
--Receipts without a brand associated
-- 1,093 of 1,119 receipts with no brand code
--this seems important for association with brands file but I'm unsure
------------------------------------------------------

select count(distinct receiptsid) from receipts_lines_fact rlf 
inner join items_dim id on rlf.item_dim_id = id.item_dim_id 
where id."rewardsReceiptItemList.brandCode" = ''


