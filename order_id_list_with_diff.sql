 drop table if exists  #temp_gw
 drop table if exists  #temp_gross
 drop table if exists  #date_diff
 drop table if exists  #currency_diff

 --amount check 
SELECT g.[MERCHANT_ACCOUNT],g.[BATCH_NUMBER],g.ORDER_REF,sum(cast(GROSS as float)) GROSS 
into #temp_gw 
  FROM [dbfour].[dbo].[combined_csv] g
  GROUP BY  g.[MERCHANT_ACCOUNT],g.[BATCH_NUMBER] ,g.ORDER_REF ;

with netSuite as (
SELECT MERCHANT_ACCOUNT,BATCH_NUMBER,ISNULL(sum(amount_foreign),0) NetSuite,a.ORDER_REF
  FROM [bi].[netsuite].[TRANSACTIONS] a
  left join [bi].[netsuite].[TRANSACTION_LINES] b on a.TRANSACTION_ID=b.TRANSACTION_ID
  left join [bi].[netsuite].[ACCOUNTS] c on b.ACCOUNT_ID=c.ACCOUNT_ID
  where [TRANSACTION_LINE_ID] in (1,2) and c.[ACCOUNTNUMBER] in('315700','315710','315720','315800','548201') and MERCHANT_ACCOUNT is not null
  group by MERCHANT_ACCOUNT,BATCH_NUMBER,ORDER_REF
)
SELECT gw.[MERCHANT_ACCOUNT],gw.[BATCH_NUMBER],gw.ORDER_REF ORDER_REF_GW ,ns.ORDER_REF ORDER_REF_NS,'' CURRENCY_GW, '' CURRENCY_NS,'' DATE_GW, ' ' DATE_NS,
[GROSS] as Payment_Gateway,ISNULL(ns.NetSuite,0) NetSuite 
  into #temp_gross
  FROM #temp_gw gw
  full join netSuite ns on  gw.ORDER_REF=ns.ORDER_REF and gw.MERCHANT_ACCOUNT=ns.MERCHANT_ACCOUNT and gw.BATCH_NUMBER=ns.BATCH_NUMBER 
  where (ISNULL(ns.NetSuite,0)-ISNULL(cast([GROSS] as float),0))<>0;


--currency check 
with netSuite as (
SELECT MERCHANT_ACCOUNT,BATCH_NUMBER,ISNULL(sum(amount_foreign),0) NetSuite,a.ORDER_REF,k.SYMBOL 
  FROM [bi].[netsuite].[TRANSACTIONS] a
  left join [bi].[netsuite].[TRANSACTION_LINES] b on a.TRANSACTION_ID=b.TRANSACTION_ID
  left join [bi].[netsuite].[ACCOUNTS] c on b.ACCOUNT_ID=c.ACCOUNT_ID
  left join [bi].[netsuite].[CURRENCIES] k on a.CURRENCY_ID=k.CURRENCY_ID
  where [TRANSACTION_LINE_ID] in (1,2) and c.[ACCOUNTNUMBER] in('315700','315710','315720','315800','548201')
  group by MERCHANT_ACCOUNT,BATCH_NUMBER,ORDER_REF,k.SYMBOL
)
SELECT gw.[MERCHANT_ACCOUNT],gw.[BATCH_NUMBER],gw.ORDER_REF ORDER_REF_GW ,ns.ORDER_REF ORDER_REF_NS,gw.CURRENCY CURRENCY_GW, ns.SYMBOL CURRENCY_NS,'' DATE_GW, ' ' DATE_NS,
[GROSS] as Payment_Gateway,ISNULL(ns.NetSuite,0) NetSuite 
into #currency_diff
 FROM [dbfour].[dbo].[combined_csv] gw
  full join netSuite ns on gw.MERCHANT_ACCOUNT=ns.MERCHANT_ACCOUNT and gw.BATCH_NUMBER=ns.BATCH_NUMBER and gw.ORDER_REF=ns.ORDER_REF
  where gw.CURRENCY<>ns.SYMBOL;  


 --transaction_date
 with netSuite as (
SELECT MERCHANT_ACCOUNT,BATCH_NUMBER,ISNULL(sum(amount_foreign),0) NetSuite,a.ORDER_REF,k.SYMBOL,a.TRANDATE 
  FROM [bi].[netsuite].[TRANSACTIONS] a
  left join [bi].[netsuite].[TRANSACTION_LINES] b on a.TRANSACTION_ID=b.TRANSACTION_ID
  left join [bi].[netsuite].[ACCOUNTS] c on b.ACCOUNT_ID=c.ACCOUNT_ID
  left join [bi].[netsuite].[CURRENCIES] k on a.CURRENCY_ID=k.CURRENCY_ID
  where [TRANSACTION_LINE_ID] in (1,2) and c.[ACCOUNTNUMBER] in('315700','315710','315720','315800','548201')
  group by MERCHANT_ACCOUNT,BATCH_NUMBER,ORDER_REF,k.SYMBOL,a.TRANDATE 
)
SELECT gw.[MERCHANT_ACCOUNT],gw.[BATCH_NUMBER],gw.ORDER_REF ORDER_REF_GW ,ns.ORDER_REF ORDER_REF_NS,'' CURRENCY_GW, '' CURRENCY_NS,[date] DATE_GW, cast (ns.TRANDATE as varchar) DATE_NS,
[GROSS] as Payment_Gateway,ISNULL(ns.NetSuite,0) NetSuite 
into #date_diff
 FROM [dbfour].[dbo].[combined_csv] gw
  full join netSuite ns on gw.MERCHANT_ACCOUNT=ns.MERCHANT_ACCOUNT and gw.BATCH_NUMBER=ns.BATCH_NUMBER and gw.ORDER_REF=ns.ORDER_REF
  where ns.TRANDATE<> convert(varchar(50),[DATE],104);

  select * from #currency_diff
  union all
  select * from #date_diff
  union all
  select * from #temp_gross;

--Bonus task

--update for currency 
with netSuite as (
SELECT MERCHANT_ACCOUNT,BATCH_NUMBER,ISNULL(sum(amount_foreign),0) NetSuite,a.ORDER_REF,k.SYMBOL 
  FROM [bi].[netsuite].[TRANSACTIONS] a
  left join [bi].[netsuite].[TRANSACTION_LINES] b on a.TRANSACTION_ID=b.TRANSACTION_ID
  left join [bi].[netsuite].[ACCOUNTS] c on b.ACCOUNT_ID=c.ACCOUNT_ID
  left join [bi].[netsuite].[CURRENCIES] k on a.CURRENCY_ID=k.CURRENCY_ID
  where [TRANSACTION_LINE_ID] in (1,2) and c.[ACCOUNTNUMBER] in('315700','315710','315720','315800','548201')
  group by MERCHANT_ACCOUNT,BATCH_NUMBER,ORDER_REF,k.SYMBOL
)
update [bi].[netsuite].[TRANSACTIONS]
set CURRENCY_ID = 1
from [dbfour].[dbo].[combined_csv] gw
  join netSuite ns on gw.MERCHANT_ACCOUNT=ns.MERCHANT_ACCOUNT and gw.BATCH_NUMBER=ns.BATCH_NUMBER and gw.ORDER_REF=ns.ORDER_REF
  where gw.CURRENCY<>ns.SYMBOL; 

--update for date 
   with netSuite as (
SELECT MERCHANT_ACCOUNT,BATCH_NUMBER,ISNULL(sum(amount_foreign),0) NetSuite,a.ORDER_REF,k.SYMBOL,a.TRANDATE 
  FROM [bi].[netsuite].[TRANSACTIONS] a
  left join [bi].[netsuite].[TRANSACTION_LINES] b on a.TRANSACTION_ID=b.TRANSACTION_ID
  left join [bi].[netsuite].[ACCOUNTS] c on b.ACCOUNT_ID=c.ACCOUNT_ID
  left join [bi].[netsuite].[CURRENCIES] k on a.CURRENCY_ID=k.CURRENCY_ID
  where [TRANSACTION_LINE_ID] in (1,2) and c.[ACCOUNTNUMBER] in('315700','315710','315720','315800','548201')
  group by MERCHANT_ACCOUNT,BATCH_NUMBER,ORDER_REF,k.SYMBOL,a.TRANDATE 
)
update [bi].[netsuite].[TRANSACTIONS]
set TRANDATE = convert(varchar(50),[DATE],104)
 FROM [dbfour].[dbo].[combined_csv] gw
  join netSuite ns on gw.MERCHANT_ACCOUNT=ns.MERCHANT_ACCOUNT and gw.BATCH_NUMBER=ns.BATCH_NUMBER and gw.ORDER_REF=ns.ORDER_REF
  where ns.TRANDATE<> convert(varchar(50),[DATE],104);

--update for amounts will requre more analysis or advise from finance department (order_ref is empty in NetSuite or in Payment Gateway)