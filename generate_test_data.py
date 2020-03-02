#Generate Random Data
import random as rand 
values = {}

def rand_inv(list_to_append,samples,upper_limit): 
    for i in range(samples): 
        r = rand.randint(1,upper_limit) 
        list_to_append.append(r)

samples = 5000
values['invoices'] = [] 
rand_inv(values['invoices'],samples,5) 

values['invoices'] = [rand.randrange(1,5) for i in range(samples)]

def rand_price(list_to_append,samples,upper_limit): 
    for i in range(samples): 
        r = round(rand.uniform(1,upper_limit),2)
        list_to_append.append(r) 


values['price'] = [] 
rand_price(values['price'],samples,1000000.00)

values['price'] = [round(rand.uniform(1,1000000.00),2) for i in range(samples)]

#Create categories and random list 
business_unit = ['supply','mining','aerospace','infantry','defense']
client = ['terran industries','protoss corporation','zerg inc'] 
vendor = ['brood corp','liberty national','swarm llc','void co'] 
employee = ['kerrigan','raynor','fenix']


def create_categories(category,source_list,samples): 
    values[category] = []
    range_limit = len(source_list)-1 
    for i in range(samples): 
        r = rand.randint(0,range_limit) 
        values[category].append(source_list[r]) 

create_categories('business_unit',business_unit,samples)
create_categories('client',client,samples) 
create_categories('vendor',vendor,samples) 
create_categories('employee',employee,samples)

rand_value = lambda a : a[rand.randint(0,(len(a)-1))]
values['business_unit'] = [rand_value(business_unit) for i in range(samples)]
values['employee'] = [rand_value(employee) for i in range(samples)]
values['client'] = [rand_value(client) for i in range(samples)]
values['vendor'] = [rand_value(vendor) for i in range(samples)]


#Generate random dates 
from datetime import datetime 
from datetime import timedelta 


def rand_date(start_limit,end_limit,n): 
    #create empty list in our dictionary
    values['t_date'] = [] 
    values['p_date'] = []

    #get the total seconds between our start and end parameters
    time_delta = end_limit - start_limit 
    seconds_delta = time_delta.total_seconds()

    for i in range(n): 
        #generate random start date within the range 
        random_second = rand.randrange(seconds_delta) 
        start_date = start_limit + timedelta(seconds=random_second) 
        values['t_date'].append(start_date)

        #generate random end date after start date remaining in the range 
        time_delta = end_limit - start_date 
        seconds_delta = time_delta.total_seconds() 
        random_second = rand.randrange(seconds_delta) 
        end_date = start_date + timedelta(seconds=random_second) 
        values['p_date'].append(end_date) 


start_limit = datetime.strptime('1/1/19','%m/%d/%y') 
end_limit = datetime.strptime('12/31/19','%m/%d/%y') 
rand_date(start_limit,end_limit,samples) 

rand_date = lambda start, end : timedelta(seconds=rand.randrange((end - start).total_seconds())) + start
values['t_date'] = [rand_date(start_limit,end_limit) for i in range(samples)]
values['p_date'] = [rand_date(t_date,end_limit) for t_date in values['t_date']]

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

    create_database = 'Create Database wlcap_test_env;' 
    drop_database = 'Drop Database wlcap_test_env;' 

    try: 
        cur.execute(create_database)
        cur.close()
    except:
        cur.execute(drop_database)
        cur.execute(create_database)
        cur.close()


#Function to execute queries
def excecute_query(query):
    with psycopg2.connect("dbname=wlcap_test_env user=postgres password=1928") as conn:
        cur = conn.cursor()
        cur.execute(query)
        try:
            return cur.fetchall()
        except:
            cur.close()
        

#Create schema and main table
create_schema = 'Create Schema src Authorization postgres;'

create_main_table = ''' 
Create Table src.main ( 
    rkey serial, 
    invoices int, 
    price float, 
    business_unit text, 
    client text, 
    vendor text,
    employee text,
    t_date timestamp, 
    p_date timestamp 
); 
''' 

excecute_query(create_schema) 
excecute_query(create_main_table) 

#Import sqlalchemy so we can use pandas to load data 
from sqlalchemy import create_engine
#create the connection engine
engine = create_engine('postgresql://postgres:1928@localhost:5432/wlcap_test_env') 

#Insert records 
df.to_sql('main',schema='src',con=engine,if_exists='append',index=False)

#Test upload
select_records = 'Select * From src.main Limit 5'
data = excecute_query(select_records)
print(data)