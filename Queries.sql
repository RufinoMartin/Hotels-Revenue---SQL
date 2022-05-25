
--- FULL SCRIPT ---

-- 1. Full excecution to check columns.

SELECT * FROM [Hotel Revenue].[dbo].[2018]
SELECT * FROM [Hotel Revenue].[dbo].[2019]
SELECT * FROM [Hotel Revenue].[dbo].[2020]

-- 2. Column homogeinity, so we apply Union. 

SELECT * FROM [Hotel Revenue].[dbo].[2018]
UNION
SELECT * FROM [Hotel Revenue].[dbo].[2019]
UNION
SELECT * FROM [Hotel Revenue].[dbo].[2020]

--> We get a unified dataset.

-- 3. Make a Temporary Table out of our previous Query.

SELECT * 
	INTO #HotelsUnions
FROM 
(
SELECT * FROM [Hotel Revenue].[dbo].[2018]
UNION
SELECT * FROM [Hotel Revenue].[dbo].[2019]
UNION
SELECT * FROM [Hotel Revenue].[dbo].[2020]) a

-- 4. TempTable > Permanent Table


SELECT *
INTO dbo.Hotels_Unions
FROM #HotelsUnions

-- Lets print it:

select * from [Hotel Revenue].[dbo].[Hotels_Unions]


-- Before exporting for
--   Further analysis and visualizations, we 
--    try to increase our understanding. 

--- Exploratory Data Analysis (EDA) ---

-- 5. Is the hotel revenue growing by year? 
--    No Revenue column !
--     Instead: "ADR" and "Stays" columns. 

SELECT
arrival_date_year,
hotel,
round(sum((stays_in_week_nights+stays_in_weekend_nights)*adr),2) as Revenue
from [Hotel Revenue].[dbo].[Hotels_Unions]
group by arrival_date_year, hotel
order by Revenue

-- Observation: 2020 is incomplete, so the revenue is reasonable.

-- We also want this column to be present in our table, so 
--   in table>desing, we make a new computed column 'Revenue' with the formula
--     stated above: (stays_in_week_nights+stays_in_weekend_nights)*adr

-- 6. We want to make use of our "Market Segment" Table.

select * 
from [Hotel Revenue].[dbo].[Hotels_Unions]
left join 
[Hotel Revenue].[dbo].[market_segments]
ON
[Hotel Revenue].[dbo].[Hotels_Unions].market_segment = 
[Hotel Revenue].[dbo].[market_segments].market_segment

-- 7. We also want to make use of our "Meal Costs" Table.

select * 
from [Hotel Revenue].[dbo].[Hotels_Unions]
left join 
[Hotel Revenue].[dbo].[market_segments] ON [Hotel Revenue].[dbo].[Hotels_Unions].market_segment = [Hotel Revenue].[dbo].[market_segments].market_segment
left join 
[Hotel Revenue].[dbo].[meal_costs] ON  [Hotel Revenue].[dbo].[meal_costs].[meal] = [Hotel Revenue].[dbo].[Hotels_Unions].meal;

-- > Exported as XLSX and re-imported.

-- Now that we have a full dataset, we proceed to run some exploratory queries
--    which may turn usefull for visualization and potential KPI building. 

-- 1. Gain knowleade over Week vs Weekends stays

select hotel, arrival_date_year, SUM (stays_in_week_nights) as Week , SUM (stays_in_weekend_nights) as Weekend , SUM (revenue) as Revenue
FROM [Hotel Revenue].[dbo].[All]
group by hotel, arrival_date_year
order by arrival_date_year

-- 1.2 This has given information regarding Seasons & Revenue, while we still lack understanding of Week/End Difference.
--     Lets build a new column that sums week and weekends, so we can calculate percentages.
--        We save it in a temporal table.
SELECT * 
	INTO #Stays
FROM 
(
select hotel, arrival_date_year, SUM (stays_in_week_nights) as Week , SUM (stays_in_weekend_nights) as Weekend ,
sum(stays_in_week_nights + stays_in_weekend_nights) as Full_Stays,  SUM (revenue) as Revenue
FROM [Hotel Revenue].[dbo].[All]
group by hotel, arrival_date_year ) a

-- 1.3 Now lets get those percentages from our CTE

select hotel, arrival_date_year, Week , Weekend ,Full_Stays, 
ROUND(Week * 100.0 / Full_Stays, 1) AS Week_Percent, 
ROUND(Weekend * 100.0 / Full_Stays, 1) AS Weekend_Percent,Revenue
from #Stays 

-- 1.4 We can appreciate a clear and constant 3/1 - Week/Weekend relation,
--  Which is usefull for understanding OCCUPATION, but not revenue related. 
--   We dont posses the columns for their respective prices, but it can be infere that 
--     being weekends usually more expensive, it compensates the occupation volume. 

-->  More relationships/Questions

-- 2. Market Segments, Discounts and Revenue.

select hotel, arrival_date_year, market_segment1, Discount , Revenue
FROM [Hotel Revenue].[dbo].[All]
 
 -- Variables look nice. We want to know the Discount distribution, 
 -- but the variable is set in percentage as int dtype. 
 -- We gather more info on "Discount"
 
select COUNT (DISTINCT Discount)
from [Hotel Revenue].[dbo].[All]

--> Only 6 different discounts types applied.

select DISTINCT Discount
from [Hotel Revenue].[dbo].[All]

--> Which are: 0, 0.1, 0.15, 0.2, 0.3, 1. Which we interpret *100. 

select DISTINCT Discount*100 as DiscPerc
from [Hotel Revenue].[dbo].[All]
order by DiscPerc

-- Having sense as percentage discounts. 
-- Which brings the question: why are there rows which 100% discount AND revenue?
-- hipothesis: theres other revenue source...Meal? Lets see.

select *
from [Hotel Revenue].[dbo].[All]
where Discount = 1
order by Revenue DESC

-- 100% Discounts are revelead as Complementary Market Segment. 
-- Revenue may come from Special Requests, Variables influencing lead_time (which we ignore),
-- Or other black-box variables. 
-- Nontheless, we will provide insights on discounts/revenue relationship. 

select market_segment1, Discount*100 as DiscPerc , Sum (Revenue) as Revenue
FROM [Hotel Revenue].[dbo].[All]
group by market_segment1, Discount
order by DiscPerc
-- order by Revenue


-- Cancelations

-- Number of cancelations

select COUNT (is_canceled)
FROM [Hotel Revenue].[dbo].[All]

-- Number of cancelations and non cancelations?

SELECT * 
	INTO #CancelationsCTE
FROM (
select is_canceled, 
	count (case when is_canceled = 1 then 1 END) Canceled,
	count (case when is_canceled = 0 then 1 END) Not_Canceled
FROM [Hotel Revenue].[dbo].[All]
group by is_canceled ) a

-- Noncancs. triple cancels.
-- to answer: What percentages of arrivals had a cancelation? 

select arrival_date_year, is_repeated_guest,
 previous_cancellations, 
 count (case when is_canceled = 1 then 1 END) Canceled,
count (case when is_canceled = 0 then 1 END) Not_Canceled, Revenue
FROM [Hotel Revenue].[dbo].[All]
group by arrival_date_year, is_repeated_guest,
 previous_cancellations, Revenue
 order by Revenue DESC
 


