--Create Summary
Create Table src.summary (
    purchases float,
    invoices float,
    ord_value float,
    avg_days float,
    business_unit text,
    client text,
    vendor text,
    trans_month timestamp without time zone
);

Insert Into src.summary
Select
    count(rkey) as purchases,
    sum(invoices) as invoices,
    sum(price) as ord_value,
    avg(td_days) as avg_days,
    business_unit,
    client,
    vendor,
    date_trunc('month',t_date) as trans_month
From src.main
Group By business_unit, client, vendor, date_trunc('month',t_date)
;

Select * From src.summary Limit 5;

--Generate normalization scores
Create Table src.score (
    business_unit text,
    client text,
    vendor text,
    trans_month timestamp without time zone,
    purchase_score float,
    invoice_score float,
    ord_score float,
    time_score float
);
Insert Into src.score
Select
    business_unit,client,vendor,trans_month,
    (avg(purchases) - (Select avg(purchases) From src.summary))/(Select stddev_pop(purchases) From src.summary) as purchase_score,
    (avg(invoices) - (Select avg(invoices) From src.summary))/(Select stddev_pop(invoices) From src.summary) as invoice_score,
    (avg(ord_value) - (Select avg(ord_value) From src.summary))/(Select stddev_pop(ord_value) From src.summary) as ord_score,
    (avg(avg_days) - (Select avg(avg_days) From src.summary))/(Select stddev_pop(avg_days) From src.summary) as time_score
From src.summary
Group By business_unit,client,vendor,trans_month
;

Select * From src.score
;

--Get r values
Create Table src.r_scores (
    business_unit text,
    client text,
    vendor text,
    purchase_corr float,
    invoice_corr float,
    ord_corr float
);

Insert Into src.r_scores
Select
    business_unit,client,vendor,
    corr(purchase_score,time_score) as purchase_corr,
    corr(invoice_score,time_score) as inv_corr,
    corr(ord_score,time_score) as ord_corr
From src.score
Group By business_unit,client,vendor
;

Alter Table src.r_scores
Add Column optimal_category text
;

Update src.r_scores
Set optimal_category = Case
                        When purchase_corr > invoice_corr and purchase_corr > ord_corr Then 'purchases'
                        When invoice_corr > purchase_corr and invoice_corr > ord_corr Then 'invoices'
                        When ord_corr > purchase_corr and ord_corr > invoice_corr Then 'ord_value'
                        Else Null End
;

Select * From src.r_scores Limit 5
;

Alter Table src.summary
    Add Column norm_purchases float,
    Add Column norm_invoices float,
    Add Column norm_ord_value float
;

Update src.summary
Set
    norm_purchases = purchases/(Select max(purchases) From src.summary),
    norm_invoices = invoices/(Select max(invoices) From src.summary),
    norm_ord_value = ord_value/(Select max(ord_value) From src.summary)
;

Select
    s.business_unit,
    s.client,
    s.vendor,
    trans_month,
    optimal_category,
    Case
        When optimal_category = 'purchases' Then norm_purchases
        When optimal_category = 'invoices' Then norm_invoices
        When optimal_category = 'ord_value' Then norm_ord_value
    Else Null End as volume_contribution
From src.summary s
Left Join src.r_scores r
On s.business_unit = r.business_unit
    and s.client = r.client
    and s.vendor = r.vendor
;

Alter Table src.summary
    Add Column optimal_category text,
    Add Column volume_contribution float
;

Update src.summary
Set
    optimal_category = b.optimal_category,
    volume_contribution = b.volume_contribution
From (
    Select
        s.business_unit,
        s.client,
        s.vendor,
        trans_month,
        r.optimal_category,
        Case
            When r.optimal_category = 'purchases' Then norm_purchases
            When r.optimal_category = 'invoices' Then norm_invoices
            When r.optimal_category = 'ord_value' Then norm_ord_value
        Else Null End as volume_contribution
    From src.summary s
    Left Join src.r_scores r
    On s.business_unit = r.business_unit
        and s.client = r.client
        and s.vendor = r.vendor
) b
Where src.summary.business_unit = b.business_unit
    and src.summary.client = b.client
    and src.summary.vendor = b.vendor
    and src.summary.trans_month = b.trans_month
;

Select * From src.summary
;

Select sum(volume_contribution) From src.summary
;