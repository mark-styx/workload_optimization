import pandas as pd

import sqlalchemy 
from sqlalchemy import create_engine 

engine = create_engine('postgresql://postgres:1928@localhost:5432/wlcap_test_env') 

df = pd.read_sql('select * from src.main;',con=engine,index_col='rkey')
df.head()

#Clean up
td_query = '''Select
    extract(day from (p_date-t_date))
from src.main;'''

#Test postgres time delta
time_delta_test = pd.read_sql(td_query,con=engine)
time_delta_test.head()

df['timedelta'] = df['p_date'] - df['t_date']
df['timedelta'].head()

#Update Table to include time delta
import psycopg2

def excecute_query(query):
    with psycopg2.connect("dbname=wlcap_test_env user=postgres password=1928") as conn:
        cur = conn.cursor()
        cur.execute(query)
        try:
            return cur.fetchall()
        except:
            cur.close()

add_column = '''Alter Table src.main
Add Column td_days float;'''

update_column = '''Update src.main
Set td_days = extract(day from (p_date-t_date));'''

excecute_query(add_column)
excecute_query(update_column)


#Summarize our data
create_summary = '''
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
'''

populate_summary = '''
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
'''

#execute
excecute_query(create_summary)
excecute_query(populate_summary)

#check results
df = pd.read_sql('Select * From src.summary Limit 5;',con=engine)
df.head()


#generate normalized scores
create_scores_table = '''
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
'''

populate_scores = '''
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
'''

#execute
excecute_query(create_scores_table)
excecute_query(populate_scores)

#check results
df = pd.read_sql('Select * From src.score Limit 5;',con=engine)
df.head()


#generate correlation coefficient scores
create_corr_table = '''
    Create Table src.corr_scores (
        business_unit text,
        client text,
        vendor text,
        purchase_corr float,
        invoice_corr float,
        ord_corr float
);
'''

populate_corr = '''
    Insert Into src.corr_scores
    Select
        business_unit,client,vendor,
        corr(purchase_score,time_score) as purchase_corr,
        corr(invoice_score,time_score) as inv_corr,
        corr(ord_score,time_score) as ord_corr
    From src.score
    Group By business_unit,client,vendor
    ;
'''

#execute
excecute_query(create_corr_table)
excecute_query(populate_corr)

#check results
df = pd.read_sql('Select * From src.corr_scores Limit 5;',con=engine)
df.head()


#add field noting the best score
alter_r = '''
    Alter Table src.corr_scores
    Add Column optimal_category text
    ;
'''

update_r = '''
    Update src.corr_scores
    Set optimal_category = Case
                            When purchase_corr > invoice_corr and purchase_corr > ord_corr Then 'purchases'
                            When invoice_corr > purchase_corr and invoice_corr > ord_corr Then 'invoices'
                            When ord_corr > purchase_corr and ord_corr > invoice_corr Then 'ord_value'
                            Else Null End
    ;
'''

#execute
excecute_query(alter_r)
excecute_query(update_r)

#check results
df = pd.read_sql('Select * From src.corr_scores Limit 5;',con=engine)
df


#update summary to normalize the volume measurements
alter_summary = '''
    Alter Table src.summary
        Add Column norm_purchases float,
        Add Column norm_invoices float,
        Add Column norm_ord_value float
    ;
'''

update_summary = '''
    Update src.summary
    Set
        norm_purchases = purchases/(Select max(purchases) From src.summary),
        norm_invoices = invoices/(Select max(invoices) From src.summary),
        norm_ord_value = ord_value/(Select max(ord_value) From src.summary)
    ;
'''

#execute
excecute_query(alter_summary)
excecute_query(update_summary)

#check results
df = pd.read_sql('Select * From src.summary Limit 5;',con=engine)
df

alter_summary2 = '''
--effort adjustment
Alter Table src.summary
    Add Column effort float
;
'''

update_summary2 = '''
Update src.summary
Set
    effort = ((avg_days+(Select Avg(avg_days) From src.summary))/(Select stddev(avg_days) From src.summary))
;
'''

#execute
excecute_query(alter_summary2)
excecute_query(update_summary2)

df = pd.read_sql('Select client,vendor,business_unit,avg_days,effort,trans_month From src.summary Limit 5;',con=engine)
df


#update the summary to note the optimal category we determined and the normalized volume contribution
alter_summary_3 = '''
    Alter Table src.summary
        Add Column optimal_category text,
        Add Column volume_contribution float
    ;
'''

update_summary_3 = '''
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
                When r.optimal_category = 'purchases' Then norm_purchases * effort
                When r.optimal_category = 'invoices' Then norm_invoices * effort
                When r.optimal_category = 'ord_value' Then norm_ord_value * effort
            Else Null End as volume_contribution
        From src.summary s
        Left Join src.corr_scores r
        On s.business_unit = r.business_unit
            and s.client = r.client
            and s.vendor = r.vendor
    ) b
    Where src.summary.business_unit = b.business_unit
        and src.summary.client = b.client
        and src.summary.vendor = b.vendor
        and src.summary.trans_month = b.trans_month
    ;
'''

#execute
excecute_query(alter_summary_3)
excecute_query(update_summary_3)

#check results
df = pd.read_sql('Select client,vendor,business_unit,volume_contribution,optimal_category,trans_month From src.summary Limit 5;',con=engine)
df

#summaries
work_vol_client = excecute_query('Select client,sum(volume_contribution) as volume From src.summary Group By client;')
print(work_vol_client)

work_vol_vend = excecute_query('Select vendor,sum(volume_contribution) as volume From src.summary Group By vendor;')
print(work_vol_vend)

work_vol_bu = excecute_query('Select business_unit,sum(volume_contribution) as volume From src.summary Group By business_unit;')
print(work_vol_bu)

df[['client','volume_contribution']].groupby('client').sum()
df[['vendor','volume_contribution']].groupby('vendor').sum()
df[['business_unit','volume_contribution']].groupby('business_unit').sum()

#get final volume measurement
#pandas
df = pd.read_sql('Select * From src.summary;',con=engine)
print(df['volume_contribution'].sum())
#postgresql
work_vol = excecute_query('Select sum(volume_contribution) as volume From src.summary;')
print(work_vol)


#Relative_Effort_Score = ∑((μ−x)/σ)
#Relative_Volume = ∑{(Units/Max(Units))|Volume_Category}
#Volume_Category = {max⁡(r)│Category}
#Total_Work_Capacity_Units = (∑((μ−x)/σ) * {max⁡(r)│Category})
#Total_Work_Capacity_Units = Relative_Effort_Score * Relative_Volume_Scalar
#Average_Assigned_Capacity = Total_Work_Capacity_Units/FTE's