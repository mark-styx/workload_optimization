SELECT * FROM "src"."main" LIMIT 1000;
SELECT * FROM "src"."summary" LIMIT 1000;
SELECT * FROM "src"."score" LIMIT 1000;
SELECT * FROM "src"."r_scores" LIMIT 1000;
/*
Group by the associates to determine the volume of work
units that each associate will max out efficiency at.

minimize the td_days
and maximize the volume units
*/
--stdev is a measure of variance and cannot be compared to another st dev
--Employee category comparison
Create Table src.employee_score (
    business_unit text,
    client text,
    vendor text,
    trans_month timestamp without time zone,
    employee text,
    purchase_score double precision,
    invoice_score double precision,
    ord_score double precision,
    time_score double precision
);
Insert Into src.employee_score
Select
    business_unit,client,vendor,trans_month,employee,
    (avg(purchases) - (Select avg(purchases) From src.summary))/(Select stddev_pop(purchases) From src.summary) as purchase_score,
    (avg(invoices) - (Select avg(invoices) From src.summary))/(Select stddev_pop(invoices) From src.summary) as invoice_score,
    (avg(ord_value) - (Select avg(ord_value) From src.summary))/(Select stddev_pop(ord_value) From src.summary) as ord_score,
    (avg(avg_days) - (Select avg(avg_days) From src.summary))/(Select stddev_pop(avg_days) From src.summary) as time_score
From (
    Select
        count(rkey) as purchases,
        sum(invoices) as invoices,
        sum(price) as ord_value,
        avg(td_days) as avg_days,
        business_unit,
        client,
        vendor,
        employee,
        date_trunc('month',t_date) as trans_month
    From src.main
    Group By business_unit, client, vendor, date_trunc('month',t_date),employee
) a
Group By business_unit,client,vendor,trans_month,employee
;

Create Table src.employee_vs_category (
    business_unit text,
    client text,
    vendor text,
    trans_month timestamp without time zone,
    employee text,
    purchase_score_vs_category double precision,
    invoice_score_vs_category double precision,
    ord_score_vs_category double precision,
    time_score_vs_category double precision
);
Insert Into src.employee_vs_category
Select
    e.business_unit,e.client,e.vendor,e.trans_month,e.employee,
    e.purchase_score - s.purchase_score as purchase_score_vs_category,
    e.invoice_score - s.invoice_score as invoice_score_vs_category,
    e.ord_score - s.ord_score as ord_score_vs_category,
    e.time_score - s.time_score as time_score_vs_category 
From src.employee_score e
Left Join src.score s
On e.business_unit = s.business_unit
    and e.client = s.client
    and e.vendor = s.vendor
    and e.trans_month = s.trans_month
;

