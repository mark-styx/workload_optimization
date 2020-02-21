#Relative_Effort_Score = ∑((μ−x)/σ)
#Relative_Volume = ∑{(Units/Max(Units))|Volume_Category}
#Volume_Category = {max⁡(r)│Category}
#Total_Work_Capacity_Units = (∑((μ−x)/σ) * {max⁡(r)│Category})
#Total_Work_Capacity_Units = Relative_Effort_Score * Relative_Volume_Scalar
#Average_Assigned_Capacity = Total_Work_Capacity_Units/FTE's
#Update Table to include time delta
import pandas as pd

import sqlalchemy 
from sqlalchemy import create_engine 

engine = create_engine('postgresql://postgres:1928@localhost:5432/wlcap_test_env') 

import psycopg2
def excecute_query(query):
    with psycopg2.connect("dbname=wlcap_test_env user=postgres password=1928") as conn:
        cur = conn.cursor()
        cur.execute(query)
        try:
            return cur.fetchall()
        except:
            cur.close()

df = pd.read_sql_table('main',con=engine,schema='src')
df.to_excel('test2.xlsx',index=False)