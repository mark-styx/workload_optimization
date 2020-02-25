--------------------------------
--Workload Capacity Evaluation--
--------------------------------

Declare @date_start as date
Declare @date_end as date
Set @date_start = '12/31/2018'
Set @date_end = '07/01/2019'

--Dump data into memory
IF OBJECT_ID('tempdb..#dig') IS NOT NULL DROP TABLE #dig
IF OBJECT_ID('tempdb..#prt') IS NOT NULL DROP TABLE #prt
IF OBJECT_ID('tempdb..#brd') IS NOT NULL DROP TABLE #brd
IF OBJECT_ID('tempdb..#spt') IS NOT NULL DROP TABLE #spt
IF OBJECT_ID('tempdb..#staff') IS NOT NULL DROP TABLE #staff
Select * Into #dig From [DDS].[Digital_P100P]
Select * Into #prt From [DDS].[Print_P100]
Select * Into #brd From [BRD].[NAT_PAYERSREPORT_Output]
Select * Into #spt From [SPO].[SpotPayersReport_Output]
Select * Into #staff From [DDS].[StaffANA]

--Lookup Table
IF OBJECT_ID('tempdb..#MediaLU') IS NOT NULL DROP TABLE #MediaLU
Create Table #MediaLU (
    [source] nvarchar(50),
    [normalized] nvarchar(50)
)
Insert Into #MediaLU
Values
    ('FEE','Fee'),
    ('NETWK CABLE','Network'),
    ('PRINT INT.','Internet'),
    ('PRINT SOCIAL','Social'),
    ('PRINT MAG','Magazine'),
    ('NETWK NETWK','Network'),
    ('PRINT NEWS','Newspaper'),
    ('NETWK OTHER','Network'),
    ('PRINT O/D','Outdoor'),
    ('PRODUCTION','Production'),
    ('SPOT RADIO','Radio'),
    ('NETWK SYND','Network'),
    ('PRINT SEARCH','Search'),
    ('PRINT TRADE','Trade Mag'),
    ('SPOT TV','Local TV'),
    ('NET RADIO','Net Radio'),
    ('TRAVEL','Travel'),
    ('PAYMENT','Payment'),
    ('REFUND','Refund'),
    ('PAG','Credit'),
    ('Social','Social'),
    ('Search','Search'),
    ('Interactive','Internet'),
    ('NET','Network'),
    ('CABLE','Network'),
    ('OTHER','Network'),
    ('SYND','Network'),
    ('T','Local TV'),
    ('R','Radio'),
    ('X','Net Radio'),
    ('Outdoor','Outdoor'),
    ('Magazine','Magazine'),
    ('Newspaper','Newspaper'),
    ('Trade','Trade Mag'),
    ('L SOCIAL','Social'),
    ('S SEARCH','Search'),
    ('I INTERACTIVE','Internet'),
    ('M MAGAZINE','Magazine'),
    ('N NETWORK PAYEES','Network'),
    ('R SPOT RADIO PAYEES','Radio'),
    ('X NETWORK RADIO PAYEES','Net Radio'),
    ('N NEWSPAPER','Newspaper'),
    ('O OUTDOOR','Outdoor'),
    ('T TRADE','Trade Mag'),
    ('T SPOT TV PAYEES','Local TV'),
    ('02 LOS ANGELES','Fee'),
    ('I PRINT INT.','Internet'),
    ('S PRINT SEARCH','Search'),
    ('L PRINT SOCIAL','Social'),
    ('M PRINT MAG','Magazine'),
    ('N PRINT NEWS','Newspaper'),
    ('T PRINT TRADE','Trade Mag'),
    ('C NETWK NETWK','Network'),
    ('N NETWK NETWK','Network'),
    ('O PRINT O/D','Outdoor'),
    ('O SPOT RADIO','Radio'),
    ('R SPOT RADIO','Radio'),
    ('S SPOT TV','Local TV'),
    ('T SPOT TV','Local TV'),
    ('X NET RADIO','Net Radio'),
    ('I','Internet'),
    ('S','Search'),
    ('L','Social')

--Create main table
IF OBJECT_ID('tempdb..#Invoices') IS NOT NULL DROP TABLE #Invoices
Create Table #Invoices (
    --DDS Open Payable Data
    [Buy_Key] int,
    [PKey] nvarchar(max),
    [Media] nvarchar(max),
    [Client_Code] nvarchar(max),
    [Prod_Code] nvarchar(max),
    [Est_Num] nvarchar(max),
    [Cli] nvarchar(25),
    [Prd] nvarchar(25),
    [Est] nvarchar(25),
    [Pub_Number] nvarchar(max),
    [Publication] nvarchar(max),
    [Insertion_Date] date,
    [Buy_Stat] nvarchar(max),
    [Paid_Net] float,
    [Payable_Net] float,
    [Invoice_Number] nvarchar(max),
    [CAMPAIGN_ID] nvarchar(max),
    [Insertion_Order] nvarchar(max),
    [IDESKRECONStatus] nvarchar(max),
    [Changes_To_Buy] nvarchar(max),
    [Check_Number] nvarchar(max),
    [Clearance_Date] date,
    [Clearance_Invoice_Number] nvarchar(max),
    [Parent_Buy] int
    )

--______________________________________
--______________DDS Data________________
--______________________________________

--Delete temp tables if exist
IF OBJECT_ID('tempdb..#BuyLines') IS NOT NULL DROP TABLE #BuyLines
IF OBJECT_ID('tempdb..#DDS_Data') IS NOT NULL DROP TABLE #DDS_Data
IF OBJECT_ID('tempdb..#Ind_Inv') IS NOT NULL DROP TABLE #Ind_Inv

--Dump DDS Data Into Temp Table
Select
    [Buy_Key] = Null,
    [PKey] = Concat(Trim(Substring(Client_Code,1,3)), Trim(Substring(Prod_Code,1,3)), Trim(Pub_Number), Format(Cast(Insertion_Date_Converted as Date),'MM/yyyy'),Trim([CAMPAIGN_ID])),
    [Media] = Trim([Media]),
    [Client_Code] = Trim([Client_Code]),
    [Prod_Code] = Trim([Prod_Code]),
    [Est_Num] = Trim([Est_Num]),
    [Pub_Number] = Trim([Pub_Number]),
    [Publication] = Trim([Publication]),
    [Insertion_Date_Converted],
    [Buy_Stat] = Trim([Buy_Stat]),
    [Paid_Net],
    [Payable_Net],
    [Invoice_Number] = Trim(Cast([Invoice_Number] as NVARCHAR)),
    [CAMPAIGN_ID] = Trim([CAMPAIGN_ID]),
    [Insertion_Order] = Trim([Insertion_Order]),
    [IDESKRECONStatus] = Trim([IDESKRECONStatus]),
    [Changes_To_Buy] = Trim([Changes_To_Buy]),
    [Check_Number] = Trim([Check_Number]),
    [Paid_Date] = Cast(Case  
                    When Substring([Paid_Date],1,3) = 'JAN' Then Replace([Paid_Date],'JAN', '01/')
                    When Substring([Paid_Date],1,3) = 'FEB' Then Replace([Paid_Date],'FEB', '02/')
                    When Substring([Paid_Date],1,3) = 'MAR' Then Replace([Paid_Date],'MAR', '03/')
                    When Substring([Paid_Date],1,3) = 'APR' Then Replace([Paid_Date],'APR', '04/')
                    When Substring([Paid_Date],1,3) = 'MAY' Then Replace([Paid_Date],'MAY', '05/')
                    When Substring([Paid_Date],1,3) = 'JUN' Then Replace([Paid_Date],'JUN', '06/')
                    When Substring([Paid_Date],1,3) = 'JUL' Then Replace([Paid_Date],'JUL', '07/')
                    When Substring([Paid_Date],1,3) = 'AUG' Then Replace([Paid_Date],'AUG', '08/')
                    When Substring([Paid_Date],1,3) = 'SEP' Then Replace([Paid_Date],'SEP', '09/')
                    When Substring([Paid_Date],1,3) = 'OCT' Then Replace([Paid_Date],'OCT', '10/')
                    When Substring([Paid_Date],1,3) = 'NOV' Then Replace([Paid_Date],'NOV', '11/')
                    When Substring([Paid_Date],1,3) = 'DEC' Then Replace([Paid_Date],'DEC', '12/')
                    Else Null End as date),
    [Clearance_Invoice_Number] = Trim(Cast([Clearance_Invoice_Number] as NVARCHAR)),
    [Parent_Buy] = Null
Into #DDS_Data
From #dig
Where   [Insertion_Date_Converted] > @date_start
    and [Insertion_Date_Converted] < @date_end

--Separate Invoice Lines That do not Represent a Buy Line
Select
    [Check_Number],
    [Paid_Date],
    [Clearance_Invoice_Number],
    [Client_Code],
    [Prod_Code],
    [Est_Num],
    [Pub_Number],
    [Publication],
    [Insertion_Date_Converted]
Into #Ind_Inv
From #DDS_Data
Where ([Changes_To_Buy] is Null or Len([Changes_To_Buy]) = 0)
    and ([Invoice_Number] is Null or Len(Trim([Invoice_Number])) = 0)

--Delete Cleared Invoice Lines From DDS_Data
Delete 
From #DDS_Data
Where   ([Changes_To_Buy] is Null or Len([Changes_To_Buy]) = 0)
    and ([Invoice_Number] is Null or Len(Trim([Invoice_Number])) = 0)

--Update Check/Cleared Date/Clearance Inv Number From DDS_Data.Cleared_Invoices
Update #DDS_Data
Set [Check_Number] = clrd.[Check_Number],
    [Paid_Date] = clrd.[Paid_Date],
    [Clearance_Invoice_Number] = clrd.[Clearance_Invoice_Number]
From (
    Select *
    From #Ind_Inv
) clrd
Where   Cast([Invoice_Number] as NVARCHAR) = cast(clrd.[Clearance_Invoice_Number] as NVARCHAR)
    and #DDS_Data.[Client_Code] = clrd.[Client_Code]
    and #DDS_Data.[Prod_Code] = clrd.[Prod_Code]
    and #DDS_Data.[Est_Num] = clrd.[Est_Num]
    and #DDS_Data.[Pub_Number] = clrd.[Pub_Number]
    and #DDS_Data.[Publication] = clrd.[Publication]
    and #DDS_Data.[Insertion_Date_Converted] = clrd.[Insertion_Date_Converted]

--Release memory
Drop Table #Ind_Inv

--Create Buy Line Key # and assign only lines that represent a buy (contains buy change data)
Select *
Into #BuyLines
From #DDS_Data
Where ([Changes_To_Buy] is not Null and Len([Changes_To_Buy]) > 0)

ALTER TABLE #BuyLines DROP COLUMN [Buy_Key]
ALTER TABLE #BuyLines ADD [Buy_Key] INT IDENTITY(1,1)

Update #DDS_Data
Set [Buy_Key] = cnt.[Buy_Key]
From (
    Select *
    From #BuyLines
) cnt
Where #DDS_Data.[Media] = cnt.[Media]
    and #DDS_Data.[Client_Code] = cnt.[Client_Code]
    and #DDS_Data.[Prod_Code] = cnt.[Prod_Code]
    and #DDS_Data.[Est_Num] = cnt.[Est_Num]
    and #DDS_Data.[Pub_Number] = cnt.[Pub_Number]
    and #DDS_Data.[Publication] = cnt.[Publication]
    and #DDS_Data.[Insertion_Date_Converted] = cnt.[Insertion_Date_Converted]
    and #DDS_Data.[Buy_Stat] = cnt.[Buy_Stat]
    and #DDS_Data.[Paid_Net] = cnt.[Paid_Net]
    and #DDS_Data.[Payable_Net] = cnt.[Payable_Net]
    and #DDS_Data.[Invoice_Number] = cnt.[Invoice_Number]
    and #DDS_Data.[CAMPAIGN_ID] = cnt.[CAMPAIGN_ID]
    and #DDS_Data.[Insertion_Order] = cnt.[Insertion_Order]
    and #DDS_Data.[IDESKRECONStatus] = cnt.[IDESKRECONStatus]
    and #DDS_Data.[Changes_To_Buy] = cnt.[Changes_To_Buy]

--Update lines for invoices that dont represent buys lines
Update #DDS_Data
Set [CAMPAIGN_ID] = bl.[CAMPAIGN_ID],
    [Insertion_Order] = bl.[Insertion_Order],
    [IDESKRECONStatus] = bl.[IDESKRECONStatus],
    [Changes_To_Buy] = bl.[Changes_To_Buy],
    [Parent_Buy] = bl.[Buy_Key]
From (
    Select * From #BuyLines
) bl
Where #DDS_Data.[Media] = bl.[Media]
    and #DDS_Data.[Client_Code] = bl.[Client_Code]
    and #DDS_Data.[Prod_Code] = bl.[Prod_Code]
    and #DDS_Data.[Est_Num] = bl.[Est_Num]
    and #DDS_Data.[Pub_Number] = bl.[Pub_Number]
    and #DDS_Data.[Publication] = bl.[Publication]
    and #DDS_Data.[Insertion_Date_Converted] = bl.[Insertion_Date_Converted]
    and (#DDS_Data.[Changes_To_Buy] is Null or Len(#DDS_Data.[Changes_To_Buy]) = 0)
    and (#DDS_Data.[Invoice_Number] is not Null and Len(Trim(#DDS_Data.[Invoice_Number])) > 0)

--Release memory
Drop Table #BuyLines

--__________End of DDS Data_____________
--______________________________________

--Insert Values
Insert Into #Invoices
(
    [Buy_Key],
    [PKey],
    [Media],
    [Client_Code],
    [Prod_Code],
    [Est_Num],
    [Pub_Number],
    [Publication],
    [Insertion_Date],
    [Buy_Stat],
    [Paid_Net],
    [Payable_Net],
    [Invoice_Number],
    [CAMPAIGN_ID],
    [Insertion_Order],
    [IDESKRECONStatus],
    [Changes_To_Buy],
    [Check_Number],
    [Clearance_Date],
    [Clearance_Invoice_Number],
    [Parent_Buy]
)
Select 
    [Buy_Key],
    [PKey],
    [Media],
    [Client_Code],
    [Prod_Code],
    [Est_Num],
    [Pub_Number],
    [Publication],
    [Insertion_Date_Converted],
    [Buy_Stat],
    [Paid_Net],
    [Payable_Net],
    [Invoice_Number],
    [CAMPAIGN_ID],
    [Insertion_Order],
    [IDESKRECONStatus],
    [Changes_To_Buy],
    [Check_Number],
    [Paid_Date],
    [Clearance_Invoice_Number],
    [Parent_Buy]
From #DDS_Data

Update #Invoices
Set [Cli] = Trim(Substring([Client_Code],1,Charindex(' ',[Client_Code])-1)),
    [Prd] = Trim(Substring([Prod_Code],1,Charindex(' ',[Prod_Code])-1)),
    [Est] = Case When Substring([Est_Num],1,Charindex(' ',[Est_Num])-1) Not Like '[A-Za-z]%' Then Trim(Cast(Cast(Substring([Est_Num],1,Charindex(' ',[Est_Num])-1) as integer) as nvarchar)) Else Substring([Est_Num],1,Charindex(' ',[Est_Num])-1) End

--Add Fields
Alter Table #Invoices
Add
    [Key] int,
    [Cl_Status] nvarchar(50)

--Update Key
Update #Invoices
Set 
    [Key] = Case When [Buy_Key] is Not Null Then [Buy_Key] Else [Parent_Buy] End

--Add Clearance Status
Update #Invoices
Set 
    [Cl_Status] = [Status],
    [Clearance_Date] = [Paid_Date]
From (
    Select
        [Key],
        [Payable_Net],
        [Paid_Date],
        [Status] = 'Cleared'
    From(
        Select
            [Key],
            [Payable_Net] = Sum([Payable_Net]),
            [Paid_Date] = max([Clearance_Date])
        From #Invoices
        Group By [Key]) Cl
    Where [Paid_Date] Is Not Null) Cl2
Where Cl2.[Key] = #Invoices.[Key]

--Update data missing from staff
Update #Invoices
Set 
    [Cl_Status] = 'Cleared'
From (
    Select
        [CLIE] = Trim([CLIE]),
        [PROD] = Trim([PROD]),
        [INV_NUMBER] = Trim([INV_NUMBER]),
        [mos] = Format([MOSDATE2],'MM/yyyy'),
        [ACTIVDATE2]
    From #staff
    Where Len([INV_NUMBER]) > 0 and [INV_NUMBER] is Not Null
) s
Where [Invoice_Number] = [INV_NUMBER]
    and [Cli] = [CLIE]
    and [Prd] = [PROD]
    and Format([Insertion_Date],'MM/yyyy') = [mos]

Update #Invoices
Set 
    [Clearance_Date] = [ACTIVDATE2]
From (
    Select
        [CLIE] = Trim([CLIE]),
        [PROD] = Trim([PROD]),
        [INV_NUMBER] = Trim([INV_NUMBER]),
        [mos] = Format([MOSDATE2],'MM/yyyy'),
        [ACTIVDATE2]
    From #staff
    Where Len([INV_NUMBER]) > 0 and [INV_NUMBER] is Not Null
) s
Where [Clearance_Date] is Null
    and [Invoice_Number] = [INV_NUMBER]
    and [Cli] = [CLIE]
    and [Prd] = [PROD]
    and Format([Insertion_Date],'MM/yyyy') = [mos]

--Insert into effort/volume table
Select
    [Media] = [normalized],
    [Client] = [ClName_O],
    [Vendor] = [Publication],
    [Invoice_Number],
    [Insertion_Date],
    [Clearance_Date],
    [Days_to_Clear] = Datediff(day, [Clearance_Date], [Insertion_Date])
Into #effort
From #Invoices inv
    Left Join CFM.ClientDetail cd
    On Trim(inv.CLI) = Trim(cd.CLI)
    Left Join #MediaLU
    On Trim([Media]) = [source]

--Release Memory
Drop Table #Invoices
-------------------------------------------------------------------------
--Get new date parameter
Declare @mindate as date
set @mindate = (Select min(Insertion_Date) From #effort)

--Staff Analysis
Insert Into #effort
Select
    [Media],
    [Client],
    [Vendor],
    [Inv_Number],
    [Insertion_Date] = Cast([MOSDATE2] as Date),
    [Clearance_Date] = Cast([ACTIVDATE2] as Date),
    [Days_to_Clear]
From (
    Select
        [Media] = [normalized],
        [INV_NUMBER] = Trim([INV_NUMBER]),
        [Client] = [ClName_O],
        [Vendor] = Trim([VENDOR_NAME]),
        [Days_to_Clear] = Datediff(day,[MOSDATE2],[ACTIVDATE2]),
        [ACTIVDATE2],
        [MOSDATE2]
    From #staff
        Left Join [CFM].[ClientDetail]
        On Trim([CLIE]) = Trim([CLI])
        Left Join #MediaLU
        On Trim([Media]) = [source]
    Where [CURRENTCREDIT] <> 0 
        and Len([INV_NUMBER]) > 0 and [INV_NUMBER] is not null
        and [MOSDATE2] >= @mindate
        and [normalized] not in ('Internet','Search','Social')
) sa

--Normalize vendors
Create Table #VendNorm (
    [media] nvarchar(50),
    [vendor] nvarchar (255),
    [inv] nvarchar (255),
    [client] nvarchar (255),
    [prd] nvarchar (255),
    [mos] nvarchar (255),
    [sa_vend] nvarchar(255)
)
Insert Into #VendNorm ([media],[vendor],[inv],[client],[prd],[mos])
Select *
From (
    Select 
        [media] = trim(cast([Media] as nvarchar)),
        [vendor] = trim(cast([Network] as nvarchar)),
        [inv] = trim(cast([Inv_Number] as nvarchar)),
        [client] = trim(cast([Client] as nvarchar)),
        [prd] = trim(cast([Product] as nvarchar)),
        [mos] = Format([Mos],'MM/yyyy')
    From #brd
        union
    Select 
        [media] = trim(cast([Media] as nvarchar)),
        [vendor] = trim(cast([Publication] as nvarchar)),
        [inv] = trim(cast([Invoice_Number] as nvarchar)),
        [client] = trim(cast([Client_Code] as nvarchar)),
        [prd] = trim(cast([Prod_Code] as nvarchar)),
        [mos] = Format([Insertion_Date_Converted],'MM/yyyy')
    From #dig
        union
    Select 
        [media] = trim(cast([Media] as nvarchar)),
        [vendor] = trim(cast([Publication] as nvarchar)),
        [inv] = trim(cast([Invoice_Number] as nvarchar)),
        [client] = trim(cast([Client_Code] as nvarchar)),
        [prd] = trim(cast([Prod_Code] as nvarchar)),
        [mos] = Format([Insertion_Date_Converted],'MM/yyyy')
    From #prt
        union
    Select 
        [media] = trim(cast([Med] as nvarchar)),
        [vendor] = trim(cast([Station] as nvarchar)),
        [inv] = trim(cast([Invoice_Number] as nvarchar)),
        [client] = trim(cast([ClientCode] as nvarchar)),
        [prd] = trim(cast([Product] as nvarchar)),
        [mos] = Format([MOSDATE2],'MM/yyyy')
    From #spt
) as op

--clean up
Update #VendNorm
Set 
    media = normalized
From (Select * From #MediaLU) mlu
Where media = source

Update #VendNorm
Set
    [client] = substring([client],1,charindex(' ',[client]))
Where Len([client]) > 3

Update #VendNorm
Set
    [prd] = substring([prd],1,charindex(' ',[prd]))
Where Len([prd]) > 3

Update #VendNorm
Set 
    [sa_vend] = [sav]
From (
    Select
        [Media] = [normalized],
        [CLIE] = trim([CLIE]),
        [PROD] = trim([PROD]),
        [sav] = trim([VENDOR_NAME]),
        [m] = Format([MOSDATE2],'MM/yyyy'),
        [INV_NUMBER] = trim([INV_NUMBER])
    From #staff
    Left Join #MediaLU
    On [Media] = [source]
    Group by [normalized],trim([CLIE]),trim([PROD]),
        trim([VENDOR_NAME]),Format([MOSDATE2],'MM/yyyy'),
        trim([INV_NUMBER])
) sa
Where [mos] = [m]
    and [client] = [CLIE]
    and [prd] = [PROD]
    and [mos] = [m]
    and [inv] = [INV_NUMBER]

--Release Memory
Drop Table #staff

--Summarize effort
Select
    [Media],
    [Client],
    [Vendor],
    [Invoices] = count([Invoice_Number]),
    [Mos] = Format([Insertion_Date],'MM/yyyy'),
    [Avg_Clr_Days] = avg([Days_to_Clear])
Into #esum
From #effort
Group By [Media],[Client],[Vendor],Format([Insertion_Date],'MM/yyyy')

--Release memory
Drop Table #effort

--Get opr summary data
Select
    [Media],
    [cnt],
    [amt],
    [cc],
    [vn],
    [ms]
Into #opsum
From (
    Select
        [Media],
        [cnt] = count(*),
        [amt] =sum([Payable_Net] + [Paid_Net]),
        [cc] = [CLNAME_O],
        [vn] = trim([Publication]),
        [ms] = Format(Insertion_Date_Converted,'MM/yyyy')
    From #dig
    Left Join CFM.ClientDetail
        On substring([Client_Code],1,charindex(' ', [Client_Code])-1) = trim([Cli])
    Where Len(Changes_To_Buy) > 0
    Group By [CLNAME_O],trim([Publication])
Fix This ====>
Union
    Select
        [Media],
        [cnt] = count(*),
        [amt] = sum([Paid_Net] + [Payable_Net]),
        [cc] = [ClName_O],
        [vn] = trim([Publication]),
        [ms] = Format(Insertion_Date_Converted,'MM/yyyy')
    From #prt
    Left Join CFM.ClientDetail
        On substring([Client_Code],1,charindex(' ', [Client_Code])-1) = trim([Cli])
    Group By [CLNAME_O],trim([Publication])
Union 
    Select 
        [Media],
        [cnt] = count(*),
        [amt] = sum([Total_UnPaid] + [NetCleared]),
        [cc] = [ClName_O],
        [vn] = trim([Network]),
        [ms] = Format(MOS,'MM/yyyy')
    From #brd
    Left Join CFM.ClientDetail
        On substring([Client],1,charindex(' ', [Client])-1) = trim([Cli])
    Group By [CLNAME_O],trim([NETWORK])
Union 
    Select 
        [Media] = [MED],
        [cnt] = count(*),
        [amt] = sum([Total_UnPaid] + [NET_PAID]),
        [cc] = [CLNAME_O],
        [vn] = trim([Station]),
        [ms] = Format([MOSDATE2],'MM/yyyy')
    From #spt
    Left Join CFM.ClientDetail
        On substring([Client],1,charindex(' ', [Client])-1) = Trim([Cli])
    Group By [CLNAME_O],trim([Station])
) opr

--Release memory
Drop Table #brd
Drop Table #dig
Drop Table #prt
Drop Table #spt

--normalize media
Update #opsum
Set
    [Media] = [normalized]
From (
    Select * From #MediaLU
) mlu

--Vendor normalization operation
Update #esum
Set [Vendor] = vn.[vendor]
From (
    Select
        [media],
        [client],
        [vendor],
        [sa_vend],
        [mos]
    From #VendNorm
    Group By [media],[client],[vendor],[sa_vend],[mos]
) vn
Where #esum.[Vendor] = [sa_vend]

--Combine summaries
Select
    [m] = #opsum.[Media],
    [cnt],
    [amt],
    [acd] = [Avg_Clr_Days],
    [inv] = [Invoices],
    [cc],
    [vn],
    [ms]
Into #emag
From #opsum
Left Join #esum
On #opsum.[Media] = #esum.[Media]
    and [cc] = [Client]
    and [vn] = [Vendor]
    and [ms] = [Mos]

--Release memory
Drop Table #opsum
Drop Table #esum

--Calculate r
Alter Table #emag
Add
    [r_cnt] float,
    [r_amt] float,
    [r_inv] float
-------------------------------------------
-------------------------------------------
-------------------------------------------
Update #emag
Set
    [r_cnt] = r.[r_cnt],
    [r_amt] = r.[r_amt],
    [r_inv] = r.[r_inv]
From (
    Select
        [m],[cc],[vn],[ms],
        [r_cnt] = (Avg([acd] * [cnt]) – (Avg([acd]) * Avg([cnt]))) / (StDevP([acd]) * StDevP([cnt])),
        [r_amt] = (Avg([acd] * [amt]) – (Avg([acd]) * Avg([amt]))) / (StDevP([acd]) * StDevP([amt])),
        [r_inv] = (Avg([acd] * [inv]) – (Avg([acd]) * Avg([inv]))) / (StDevP([acd]) * StDevP([inv]))
    From #emag
    Group By [m],[cc],[vn],[ms]
) r
Where [m] = r.[m]
    and [cc] = r.[cc]
    and [vn] = r.[vn]
    and [ms = r.[ms

Select * From #emag

/*
    Drop Table #Test
    Create Table #Test ([C] nvarchar,[N] int)
    Insert Into #Test
    Values
        ('A',89),
        ('A',54),
        ('A',213),
        ('B',22),
        ('B',584),
        ('A',892),
        ('A',542)

    Select
        Av = avg([N]),
        SDN = STDEVP(N)
    From #Test
    Select 
        [C], 
        X = ((Select avg(N) From #Test) - Avg([N]))/(Select stdevp(N) From #Test),
        A = Avg([N]),
        H = (Select avg(N) From #Test),
        I = (Select stdevp(N) From #Test)
    From #Test
    Group By [C]




    Select
        [Client],
        [StDev] = Stdev([Average])
    Into #cdev
    From (
        Select
            [Client],
            [Average] = avg([Days_to_Clear])
        From #effort
        Group By [Client]
    ) avg

    Select
        [Vendor],
        [StDev] = Stdev([Average])
    Into #vdev
    From (
        Select
            [Vendor],
            [Average] = avg([Days_to_Clear])
        From #effort
        Group By [Vendor]
    ) avg

*/
