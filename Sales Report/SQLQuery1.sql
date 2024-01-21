--- inspecting data ---
SELECT *
FROM [Sales_Data].[dbo].[sales_data_sample$]

--- Checking unique values ---
SELECT distinct STATUS FROM [Sales_Data].[dbo].[sales_data_sample$] 
SELECT distinct YEAR_ID FROM [Sales_Data].[dbo].[sales_data_sample$] 
SELECT distinct PRODUCTLINE FROM [Sales_Data].[dbo].[sales_data_sample$] 
SELECT distinct COUNTRY FROM [Sales_Data].[dbo].[sales_data_sample$] 
SELECT distinct DEALSIZE FROM [Sales_Data].[dbo].[sales_data_sample$] 
SELECT distinct TERRITORY FROM [Sales_Data].[dbo].[sales_data_sample$] 

--- Analysis ---
--- lest's start by grouping by productline ---

SELECT PRODUCTLINE,sum(sales) as Revenue 
FROM [Sales_Data].[dbo].[sales_data_sample$]
GROUP BY PRODUCTLINE
ORDER BY 2 Desc

--- grouping by YEAR_ID ---
SELECT YEAR_ID,sum(sales) as Revenue 
FROM [Sales_Data].[dbo].[sales_data_sample$]
GROUP BY YEAR_ID
ORDER BY 2 Desc

--- Checking the difference of revenue per year ---
SELECT distinct MONTH_ID 
FROM [Sales_Data].[dbo].[sales_data_sample$] 
where YEAR_ID = 2003 --- here 12 months

SELECT distinct MONTH_ID 
FROM [Sales_Data].[dbo].[sales_data_sample$] 
where YEAR_ID = 2004 --- here 12 months

SELECT distinct MONTH_ID 
FROM [Sales_Data].[dbo].[sales_data_sample$] 
where YEAR_ID = 2005 --- here just 5 months

--- grouping by DEALSIZE ---
SELECT DEALSIZE,sum(sales) as Revenue 
FROM [Sales_Data].[dbo].[sales_data_sample$]
GROUP BY DEALSIZE
ORDER BY 2 Desc

--- What was the best month for sales in a specific year? How much was earned that month? ---
SELECT MONTH_ID,sum(sales) as Revenue , count(ORDERNUMBER) as Frequency
FROM [Sales_Data].[dbo].[sales_data_sample$]
where YEAR_ID = 2003
GROUP BY MONTH_ID
ORDER BY 2 Desc

SELECT MONTH_ID,sum(sales) as Revenue , count(ORDERNUMBER) as Frequency
FROM [Sales_Data].[dbo].[sales_data_sample$]
where YEAR_ID = 2004
GROUP BY MONTH_ID
ORDER BY 2 Desc

--- November seems to be the month, what product do they sell in November, Classic I believe
SELECT distinct PRODUCTLINE
FROM [Sales_Data].[dbo].[sales_data_sample$]
where MONTH_ID = 11

SELECT distinct PRODUCTLINE, MONTH_ID,sum(sales) as Revenue , count(ORDERNUMBER) as Frequency
FROM [Sales_Data].[dbo].[sales_data_sample$]
where YEAR_ID = 2004 and MONTH_ID = 11 --- change year to see the rest
GROUP BY PRODUCTLINE,MONTH_ID
ORDER BY 3 Desc

--- Who is our best customer (this could be best answered with RFM)
DROP TABLE IF EXISTS #rfm
;with rfm as
(SELECT CUSTOMERNAME,
       sum(SALES) as Monetaryvalue,
	   avg(SALES) as AvgMonetaryvalue,
	   count(ORDERNUMBER) as Frequency,
	   Max(ORDERDATE) as Last_Order_Date,
	   (select max(ORDERDATE) FROM [Sales_Data].[dbo].[sales_data_sample$])as Max_ORDERDATE, 
	   DATEDIFF(DD,Max(ORDERDATE),(select max(ORDERDATE) FROM [Sales_Data].[dbo].[sales_data_sample$])) as Recency
FROM [Sales_Data].[dbo].[sales_data_sample$]
GROUP BY CUSTOMERNAME),
rfm_calc as 
(SELECT rfm.*,
       NTILE(4) OVER(ORDER BY Recency desc) as rfm_Recency,
	   NTILE(4) OVER(ORDER BY Frequency) as rfm_Frequency,
	   NTILE(4) OVER(ORDER BY AvgMonetaryvalue) as rfm_AvgMonetaryvalue
FROM rfm
)
SELECT rfm_calc.*,rfm_Recency+rfm_Frequency+rfm_Frequency AS rfm_cell,
cast(rfm_Recency as varchar)+cast(rfm_Frequency as varchar)+cast(rfm_Frequency as varchar) as rfm_cell_string
into #rfm
FROM rfm_calc

SELECT CUSTOMERNAME, rfm_Recency, rfm_Frequency , rfm_Frequency,
case 
		when rfm_cell_string in (111, 112 , 121, 122, 123, 132, 211, 212, 114, 141) then 'lost_customers'  --lost customers
		when rfm_cell_string in (133, 134, 143, 244, 334, 343, 344, 144) then 'slipping away, cannot lose' -- (Big spenders who haven’t purchased lately) slipping away
		when rfm_cell_string in (311, 411, 331) then 'new customers'
		when rfm_cell_string in (222, 223, 233, 322) then 'potential churners'
		when rfm_cell_string in (323, 333,321, 422, 332, 432) then 'active' --(Customers who buy often & recently, but at low price points)
		when rfm_cell_string in (433, 434, 443, 444) then 'loyal'
	end rfm_segment
FROM #rfm

--- What products are most often sold together? 
--select * from [dbo].[sales_data_sample] where ORDERNUMBER =  10411

select distinct OrderNumber, stuff(

	(select ',' + PRODUCTCODE
	from [Sales_Data].[dbo].[sales_data_sample$] p
	where ORDERNUMBER in 
		(

			select ORDERNUMBER
			from (
				select ORDERNUMBER, count(*) rn
				FROM [Sales_Data].[dbo].[sales_data_sample$]
				where STATUS = 'Shipped'
				group by ORDERNUMBER
			)m
			where rn = 2
		)
		and p.ORDERNUMBER = s.ORDERNUMBER
		for xml path (''))

		, 1, 1, '') ProductCodes

from [Sales_Data].[dbo].[sales_data_sample$] s
order by 2 desc


---EXTRAs----
--What city has the highest number of sales in a specific country
select city, sum (sales) Revenue
from [Sales_Data].[dbo].[sales_data_sample$]
where country = 'UK'
group by city
order by 2 desc



---What is the best product in United States?
select country, YEAR_ID, PRODUCTLINE, sum(sales) Revenue
from [Sales_Data].[dbo].[sales_data_sample$]
where country = 'USA'
group by  country, YEAR_ID, PRODUCTLINE
order by 4 desc