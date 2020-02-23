SELECT
business_unit,client,vendor,trans_month,
sum(volume_contribution)
FROM "src"."employee_summary"
Group By business_unit,client,vendor,trans_month
Order By trans_month,business_unit,client,vendor
LIMIT 1000;

Select
    business_unit,client,vendor,trans_month,employee,
    purchases/(Select max(purchases) From src.employee_summary),
    norm_purchases
FROM "src"."employee_summary"
Where business_unit = 'aerospace'
and client='protoss corporation'
and vendor='brood corp' 
and trans_month<'2/1/2019'
;

SELECT
business_unit,client,vendor,trans_month,norm_purchases,
volume_contribution
FROM "src"."summary"
Order By trans_month,business_unit,client,vendor
LIMIT 1000;


select * from src.employee_summary
order by avg_days 