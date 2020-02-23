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

--Create Summary
Create Table src.employee_summary (
    purchases float,
    invoices float,
    ord_value float,
    avg_days float,
    business_unit text,
    client text,
    vendor text,
    employee text,
    trans_month timestamp without time zone
);
Insert Into src.employee_summary
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
Group By business_unit, client, vendor, employee, date_trunc('month',t_date)
;

Alter Table src.employee_summary
    Add Column optimal_category text,
    Add Column volume_contribution float
;

Update src.employee_summary
    Set
        optimal_category = s.optimal_category
From (
    Select
        business_unit,client,vendor,trans_month,optimal_category
    From src.summary
) s
Where src.employee_summary.business_unit = s.business_unit
    and src.employee_summary.client = s.client
    and src.employee_summary.vendor = s.vendor
    and src.employee_summary.trans_month = s.trans_month
;

Alter Table src.employee_summary
    Add Column norm_purchases float,
    Add Column norm_invoices float,
    Add Column norm_ord_value float
;

Update src.employee_summary
Set
    norm_purchases = purchases/(Select max(purchases) From src.employee_summary),
    norm_invoices = invoices/(Select max(invoices) From src.employee_summary),
    norm_ord_value = ord_value/(Select max(ord_value) From src.employee_summary)
;

Update src.employee_summary as o
Set
    norm_purchases = n.norm_purchases,
    norm_invoices = n.norm_invoices,
    norm_ord_value = n.norm_ord_value
From (
    Select
        e.business_unit,e.client,e.vendor,e.trans_month,e.employee,
        (e.norm_purchases / purchase_sum) * s.norm_purchases as norm_purchases,
        (e.norm_invoices / invoice_sum) * s.norm_invoices as norm_invoices,
        (e.norm_ord_value / ord_sum) * s.norm_ord_value as norm_ord_value
    From src.employee_summary e
    Left Join src.summary s
    On e.business_unit = s.business_unit
        and e.client = s.client
        and e.vendor = s.vendor
        and e.trans_month = s.trans_month
    Left Join (
        Select
            business_unit,client,vendor,trans_month,
            sum(norm_purchases) as purchase_sum,
            sum(norm_invoices) as invoice_sum,
            sum(norm_ord_value) as ord_sum
        From src.employee_summary
        Group By business_unit,client,vendor,trans_month
    ) es
    On e.business_unit = es.business_unit
        and e.client = es.client
        and e.vendor = es.vendor
        and e.trans_month = es.trans_month
) n
Where o.business_unit = n.business_unit
    and o.client = n.client
    and o.vendor = n.vendor
    and o.trans_month = n.trans_month
    and o.employee = n.employee
;

Update src.employee_summary as es
Set
    optimal_category = b.optimal_category,
    volume_contribution = b.volume_contribution
From (
    Select
        s.business_unit,
        s.client,
        s.vendor,
        trans_month,
        employee,
        r.optimal_category,
        Case
            When r.optimal_category = 'purchases' Then norm_purchases
            When r.optimal_category = 'invoices' Then norm_invoices
            When r.optimal_category = 'ord_value' Then norm_ord_value
        Else Null End as volume_contribution
    From src.employee_summary s
    Left Join src.r_scores r
    On s.business_unit = r.business_unit
        and s.client = r.client
        and s.vendor = r.vendor
) b
Where es.business_unit = b.business_unit
    and es.client = b.client
    and es.vendor = b.vendor
    and es.trans_month = b.trans_month
    and es.employee = b.employee
;

--Efficiency measure
Select
    employee,trans_month,max(efficiency) as optimal_efficiency
From (
    Select
        trans_month,employee,
        sum(volume_contribution)/avg(avg_days) as efficiency
    From src.employee_summary
    Group by trans_month,employee
) eff
Group By employee,trans_month
Order By optimal_efficiency desc
Limit 3
;

Create Table src.employee_efficiency (
    employee text,
    volume_contribution float,
    trans_month timestamp without time zone,
    efficiency float
);
Insert Into src.employee_efficiency (volume_contribution,employee,trans_month)
Select
    sum(volume_contribution) as volume,
    employee,
    trans_month
From src.employee_summary
Group by employee,trans_month
;

Update src.employee_efficiency as ee
Set
    efficiency = eff.efficiency
From (
    Select
        trans_month,employee,
        sum(volume_contribution)/avg(avg_days) as efficiency
    From src.employee_summary
    Group by trans_month,employee
) eff
Where ee.trans_month = eff.trans_month
    and ee.employee = eff.employee
;

--Get best efficiency volume
Select volume_contribution,employee From src.employee_efficiency
Where efficiency in (Select max(efficiency) From src.employee_efficiency Group By employee)
;

--get avg effiency and return avg volume where above avg efficiency
Select
    avg(volume_contribution) as avg_vol
From src.employee_efficiency
Where efficiency between
    (Select avg(efficiency) From src.employee_efficiency) - (Select stddev_pop(avg_eff) From (
        Select employee,avg(efficiency) as avg_eff
        From src.employee_efficiency Group by employee) avg_by_emp)
and (Select avg(efficiency) From src.employee_efficiency) + (Select stddev_pop(avg_eff) From (
        Select employee,avg(efficiency) as avg_eff
        From src.employee_efficiency Group by employee) avg_by_emp)
;

Select * From src.employee_efficiency;


/*
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
*/