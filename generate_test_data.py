#Generate Random Data 
import random as rand 

values = {} 


def rand_int(list_to_append,n,upper_limit): 
    for i in range(n): 
        r = rand.randint(1,5) 
        list_to_append.append(r) 

values['invoices'] = [] 
rand_int(values['invoices'],100,5) 


def rand_price(list_to_append,n,upper_limit): 
    for i in range(n): 
        r = rand.randrange(1,upper_limit) 
        list_to_append.append(r) 

values['price'] = [] 
rand_price(values['price'],100,1000000.00) 

 
#Create categories and random list 
business_unit = ['kerrigan','raynor','fenix'] 
client = ['terran industries','protoss corporation','zerg inc'] 
vendor = ['brood corp','liberty national','swarm llc','void co'] 


def create_categories(category,source_list,n): 
    values[category] = []
    range_limit = len(source_list)-1 
    cat_list = [] 

    for i in range(n): 
        r = rand.randint(0,range_limit) 
        values[category].append(source_list[r]) 

create_categories('business_unit',business_unit,100) 
create_categories('client',client,100) 
create_categories('vendor',vendor,100) 


#Generate random dates 
from datetime import datetime 
from datetime import timedelta 

def rand_date(start_date_limit,end_date_limit,n): 
    values['t_date'] = [] 
    values['p_date'] = [] 
    time_delta = end_date_limit - start_date_limit 
    seconds_delta = time_delta.total_seconds()

    for i in range(n): 
        #generate random start date within the range 
        random_second = rand.randrange(seconds_delta) 
        start_date = start_date_limit + timedelta(seconds=random_second) 
        values['t_date'].append(start_date)

        #generate random end date after start date remaining in the range 
        time_delta = end_date_limit - start_date 
        seconds_delta = time_delta.total_seconds() 
        random_second = rand.randrange(seconds_delta) 
        end_date = start_date + timedelta(seconds=random_second) 
        values['p_date'].append(end_date) 

 
start_date_limit = datetime.strptime('1/1/19','%m/%d/%y') 
end_date_limit = datetime.strptime('12/31/19','%m/%d/%y') 
rand_date(start_date_limit,end_date_limit,100) 
rand_date(start_date_limit,end_date_limit,100) 

 
#Add to pandas dataframe 
import pandas as pd
df = pd.DataFrame(values) 
df.head() 


#Create connection 
import psycopg2 
from psycopg2.extensions import ISOLATION_LEVEL_AUTOCOMMIT 


#Create test database
with psycopg2.connect("user=postgres password=1928") as conn:
    conn.set_isolation_level(ISOLATION_LEVEL_AUTOCOMMIT) 
    cur = conn.cursor() 

    create_database = 'Create Database test_env;' 
    drop_database = 'Drop Database test_env;' 

    try: 
        cur.execute(create_database)
        cur.close()
    except:
        cur.execute(drop_database)
        cur.execute(create_database)
        cur.close()

#Function to execute queries
def excecute_query(query):
    with psycopg2.connect("dbname=test_env user=postgres password=1928") as conn:
        cur = conn.cursor()
        cur.execute(query)
        return cur.fetchall()
        

#Create schema and main table
create_schema = 'Create Schema src Authorization postgres;'

create_main_table = ''' 
Create Table src.main ( 
    rkey serial , 
    invoices int, 
    price float, 
    business_unit text, 
    client text, 
    vendor text, 
    t_date timestamp, 
    p_date timestamp 
); 
''' 

excecute_query(create_schema) 
excecute_query(create_main_table) 

#Import sqlalchemy so we can use pandas to load data 
import sqlalchemy 
from sqlalchemy import create_engine 
engine = create_engine('postgresql://postgres:1928@localhost:5432/test_env') 

#Insert records 
df.to_sql('main',schema='src',con=engine,if_exists='append',index=False)

#Test upload
select_records = 'Select * From src.main Limit 5'
data = excecute_query(select_records)