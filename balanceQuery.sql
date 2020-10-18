--- delete acount not have receipt and invoices
delete from [Customer Balance] from [Customer Balance] c left outer join [Total_Invoices] t
on c.[Customer Number]=t.[Customer Number]
left outer join CH153 h
on c.[Customer Number]=h.[Customer Number]
where t.[Customer Number] is null 
and h.[Customer Number] is null
---------------------------------------
--delete fiber
delete from c from  TE_Data_Customer_Balance_Detai c left outer join Total_Invoices t 
on c.[Invoice / Receipt Number]=t.[Invoice Number]
where  t.[Invoice Type]='accounting trans' or t.[Invoice Type]='Accountig Trans CR' 
----------------------------------------------------
select * from TE_Data_Customer_Balance_Detai
---------------------------------------------------------------------
select c.[Customer Number] into balance_review  from [Customer Balance] c
---------------------------------------------

 SELECT t1.*, t2.BillingModel,t2.[Consolidation Cycle],t3.[Warranty Days]
  INTO Customer_balance_update 
  from TE_Data_Customer_Balance_Detai as t1 left outer join Bill_Mode as t2 
  on t1.Number = t2.CustID
  left outer join [Account Advanced Find View] as t3
  on t1.Number=t3.[Account Number]
  -----------------------------------------------------------
 
  ----------------------------------
 update Customer_balance_update
 set [Consolidation Cycle]='Every 1 Month'
 where [Consolidation Cycle] is null
 --------------------------------------------
 update Customer_balance_update
 set BillingModel='In Advance'
 where BillingModel is null
 ----------------------------------------------
 select * from Customer_balance_update
 ------------------------------
-- DECLARE @date DATETIME = '8/30/2020';  
-- SELECT DATEPART(QUARTER, @date)
 
--SELECT DATEADD (dd, -1, DATEADD(qq, DATEDIFF(qq, 0, GETDATE()) +1, 0))
----to get last day in aquarter
--SELECT DATEADD (dd, -1, DATEADD(qq, DATEDIFF(qq, 0, '2020-9-2') +1, 0)) from Customer_balance_update
-- ---------------------------------------
-- --To get the last day of the current year:

--SELECT DATEADD (dd, -1, DATEADD(yy, DATEDIFF(yy, 0,[Invoice / Receipt Date] ) +1, 0)) from Customer_balance_update
--------------------------------------------------------
---- to get last day of amonth
--   select EOMONTH([Invoice / Receipt Date]), EOMONTH([Invoice / Receipt Date],1) from Customer_balance_update

--      select EOMONTH([Invoice / Receipt Date],3-MONTH([Invoice / Receipt Date])%3) from Customer_balance_update
--	    select EOMONTH('2020-08-12',3-MONTH('2020-08-12')%3) 
		---------------------------------------------------------------
		--add new column 
	ALTER TABLE Customer_balance_update
ADD End_of_period date;
-----------------------------------------------------------------------------
---insert into end of period
--update t
--set End_of_period=(case
----when t.BillingModel='In advance' then ([Invoice / Receipt Date])
--when t.[Consolidation Cycle]='Every 1 Month' then EOMONTH([Invoice / Receipt Date])
--when t.[Consolidation Cycle]='Every 3 Months' then EOMONTH([Invoice / Receipt Date],3-MONTH([Invoice / Receipt Date])%3)
--when t.[Consolidation Cycle]='Every 6 Months' then EOMONTH([Invoice / Receipt Date],6-MONTH([Invoice / Receipt Date])%6)
--when t.[Consolidation Cycle]='Every 12 Months' then EOMONTH([Invoice / Receipt Date],12-MONTH([Invoice / Receipt Date])%12)
--end)
--from Customer_balance_update t
select End_of_period  from Customer_balance_update
--------------------------------------
update t 
set End_of_period=(case
--when t.BillingModel='In advance' then ([Invoice / Receipt Date])
when t.[Consolidation Cycle]='Every 1 Month' then ([Invoice / Receipt Date])
when t.[Consolidation Cycle]='Every 3 Months' then DATEADD (dd, -1, DATEADD(qq, DATEDIFF(qq, 0, [Invoice / Receipt Date]) +1, 0))
when t.[Consolidation Cycle]='Every 6 Months' then IIF(MONTH([Invoice / Receipt Date])<=6,concat(year([Invoice / Receipt Date]),'-','06-30') ,DATEADD(YEAR, DATEDIFF(YEAR, 0, [Invoice / Receipt Date]) + 1, -1) ) 
when t.[Consolidation Cycle]='Every 12 Months' then DATEADD(YEAR, DATEDIFF(YEAR, 0, [Invoice / Receipt Date]) + 1, -1) 

end)
from Customer_balance_update t

select t.[Invoice / Receipt Date],t.End_of_period,t.DueDate2
 from Customer_balance_update t where t.[Consolidation Cycle]='Every 6 Months'
-- IIF(DATEDIFF(DAY,[Invoice / Receipt Date],@endDatePart1)>=0,@endDatePart1,@endDatePart2)
----------------------------------------------------------------------------------

-------------------------------------------------------------------------------
-- add due date and insert
ALTER TABLE Customer_balance_update ADD DueDate2 date;
--------------------------------
update t
set DueDate2 =(case
when t.BillingModel='In advance' then DATEADD(day,[Warranty Days],t.[Invoice / Receipt Date])
when t.BillingModel='In arrears' then DATEADD(day,[Warranty Days],t.End_of_period)
end)
from Customer_balance_update t
---------------------------------------------------
select sum([Functional Balance]) from Customer_balance_update
--------------------------------------------------------------------
--add due
ALTER TABLE Customer_balance_update ADD Due decimal(20,4);
----------------------------------------------------
update t
set due =(case
when t.Type='payment' then 0
when t.duedate2<='2020-10-11' then [Functional Balance]
else 0
end)
from Customer_balance_update t

select sum(due) from Customer_balance_update
select sum(notdue)+sum(due)+sum([functional balance without onaccount])+sum(OnAccount2) from Customer_balance_update
------------------------------------------------------------------
----add not due
ALTER TABLE Customer_balance_update ADD NotDue decimal(20,4);
--------------------------------------
update t
set NotDue =(case
when t.Type='payment' then 0
when t.duedate2>GETDATE() then [Functional Balance]
else 0
end)
from Customer_balance_update t

--------------------------------------------------------------------
---add function balance with out on account

ALTER TABLE Customer_balance_update ADD [functional balance without onaccount] decimal(20,4);
----------------------------------------------
update t
set [functional balance without onaccount] =(case
when t.Type='payment' then [Functional Balance]+[On Account]
else 0
end)
from Customer_balance_update t
--------------------------------------------------------------------------------------
--add onAccount2
ALTER TABLE Customer_balance_update ADD OnAccount2 decimal(20,2);
----------------------------------------
update t
set OnAccount2 =(case
when t.Type='payment' then [On Account]*-1
else 0
end)
from Customer_balance_update t
-----------------------------------------------
select Number,sum(due) due,sum(notdue) notdue,sum([functional balance without onaccount]) unapplied, sum(OnAccount2) onAccount from Customer_balance_update 
group by Number
 select sum(OnAccount2) from Customer_balance_update
----------------------------------------------------------
----add due to balance review

ALTER TABLE balance_review ADD Due decimal(20,4);
------------------------------
;with tempsum as(
 select sum(due) sumDue,number from Customer_balance_update
 group by Number
)update balance_review
set due =tempsum.sumDue from tempsum inner join balance_review
on tempsum.Number= balance_review.[Customer Number]

-----------------------------------------------------------------------
----add Notdue to balance review

ALTER TABLE balance_review ADD NotDue decimal(20,4);
-----------------------------------------------
;with tempNotDue as(
 select sum(NotDue) sumNotDue,number from Customer_balance_update
 group by Number
)update balance_review
set Notdue =tempNotDue.sumNotDue from tempNotDue inner join balance_review
on tempNotDue.Number= balance_review.[Customer Number]
---------------------------------------------------------------------------
----add UnappliedReceipts to balance review

ALTER TABLE balance_review ADD UnappliedReceipts decimal(20,4);
----------------------------------------
;with tempUnapplied as(
 select sum([functional balance without onaccount]) sumUnapplied,number from Customer_balance_update
 group by Number
)update balance_review
set UnappliedReceipts =tempUnapplied.sumUnapplied from tempUnapplied inner join balance_review
on tempUnapplied.Number= balance_review.[Customer Number]

--------------------------------------------------------------------------
----add OnAccount to balance review

ALTER TABLE balance_review ADD OnAccount decimal(20,4);
--------------------------------------------
;with tempOnaccuont as(
 select sum(OnAccount2) sumOnaccount,number from Customer_balance_update
 group by Number
)update balance_review
set OnAccount =tempOnaccuont.sumOnaccount from tempOnaccuont inner join balance_review
on tempOnaccuont.Number= balance_review.[Customer Number]
----------------------------------------------------------------------------
	--add customer name 
ALTER TABLE balance_review
ADD customer_name nvarchar(255);
---------------------------------------------------------
;with tempName as(select [Account Name (English)]  account_name,[Account Number] from  [Account Advanced Find View] 
)
update balance_review
set customer_name= tempName.account_name from tempName right outer join balance_review
on tempName.[Account Number]=balance_review.[Customer Number]
----------------------------------------------------
ALTER TABLE balance_review
ADD parent_name nvarchar(255);
-------------------------------------
;with tempParent as(select [Parent Account] parent ,[Account Number] from  [Account Advanced Find View] 
)
update balance_review
set parent_name= tempParent.parent from tempParent right outer join balance_review
on tempParent.[Account Number]=balance_review.[Customer Number]
---------------------------------------------------------------------
ALTER TABLE balance_review
ADD [Customer Type]  nvarchar(255);
--------------------------------------------------------
;with tempType as(select [Customer Type] customer_type,[Account Number] from  [Account Advanced Find View] 
)
update balance_review
set [Customer Type]=customer_type  from tempType right outer join balance_review
on tempType.[Account Number]=balance_review.[Customer Number]
--------------------------------------------------------------
ALTER TABLE balance_review
ADD [Customer Category]  nvarchar(255);
----------------------------------------------------
;with tempCategory as(select [Customer Category] customer_category,[Account Number] from  [Account Advanced Find View] 
)
update balance_review
set [Customer Category]=customer_category from tempCategory right outer join balance_review
on tempCategory.[Account Number]=balance_review.[Customer Number]
------------------------------------------------------------------------
ALTER TABLE balance_review
ADD [Market Segment]  nvarchar(255);
-------------------------------------------------------
;with tempMarket as(select [Market Segment] market,[Account Number] from  [Account Advanced Find View] 
)
update balance_review
set [Market Segment] =market from tempMarket right outer join balance_review
on tempMarket.[Account Number]=balance_review.[Customer Number]
---------------------------------------------------------------------------------------
ALTER TABLE balance_review
ADD [Business Line]  nvarchar(255);
-----------------------------------------------
;with tempBusiness as(select [Business Line] business,[Account Number] from  [Account Advanced Find View] 
)
update balance_review
set [Business Line]  =business from tempBusiness right outer join balance_review
on tempBusiness.[Account Number]=balance_review.[Customer Number]
----------------------------------------------------------------------------
ALTER TABLE balance_review
ADD [Warranty Days]  int;
----------------------------------------------
;with tempWarranty as(select [Warranty Days] warranty,[Account Number] from  [Account Advanced Find View] 
)
update balance_review
set [Warranty Days] =warranty from tempWarranty right outer join balance_review
on tempWarranty.[Account Number]=balance_review.[Customer Number]
----------------------------------------------------------
ALTER TABLE balance_review
ADD [Customer Admin Status]  nvarchar(255);
------------------------------------
;with tempAdmin as(select [Customer Admin Status] AdminStatus,[Account Number] from  [Account Advanced Find View] 
)
update balance_review
set [Customer Admin Status] =AdminStatus from tempAdmin right outer join balance_review
on tempAdmin.[Account Number]=balance_review.[Customer Number]
----------------------------------------------------------------------
select * from ch153

---------------------------
ALTER TABLE balance_review
ADD [max date]  date;

;with tempDate as(select [Customer Number] customerNumber,MAX([Receipt Date]) maxDate from  CH153 group by [Customer Number] 
)
update balance_review
set [max date] =maxDate from tempDate right outer join balance_review
on tempDate.customerNumber=balance_review.[Customer Number]
--------------------------------------------------------------
ALTER TABLE balance_review
ADD [Last Receipt Amount]  decimal;

;with tempAmount as(select [Customer Number] customerNumber,[Receipt Date] mDate,sum([Receipt Amount Functional]) amount from  CH153 
group by [Receipt Date],[Customer Number])
update balance_review
set [Last Receipt Amount] =amount from tempAmount right outer join balance_review
on (tempAmount.customerNumber=balance_review.[Customer Number] and tempAmount.mDate=balance_review.[max date])
------------------------------------------------------------------

ALTER TABLE balance_review
ADD [Oldest Unsettled Invoice or Debit Note]  date;

;with tempOldDate as(select Number,min([Invoice / Receipt Date]) OldDate
 from  TE_Data_Customer_Balance_Detai t
 where t.Type !='payment'
group by t.Number )
update balance_review
set [Oldest Unsettled Invoice or Debit Note] =OldDate from tempOldDate right outer join balance_review
on tempOldDate.Number=balance_review.[Customer Number]

----------------------------------------
update balance_review
 set [customer admin status]=' '
 where [customer admin status] is null
--------------------------------------------------
update balance_review
 set due=0
 where due is null
 ----------------------------------------
 update balance_review
 set notdue=0
 where notdue is null
 ------------------------------------
 update balance_review
 set onAccount=0
 where onAccount is null
 --------------------------------------------
select * from balance_review 
 

 select sum(due) from balance_review

 select * from Customer_balance_update t
 where t.[Invoice / Receipt Number]='E-1368773'




 select EOMONTH('2020-3-31',3-MONTH('2020-3-31')%3) from balance_review


 select 
    case when month(GETDATE()) <= 6 
        then 
            datepart(dayofyear , getdate())
        else
            datediff(day, dateadd(month, 6, dateadd(year, datediff(year, 0, getdate()), 0)), getdate()) + 1
    end



	SELECT DATEADD(MONTH, 6, DATEADD(YEAR, DATEDIFF(YEAR, 0, '2010-10-3'), 0)) from Customer_balance_update

	SELECT DATEPART(DAYOFYEAR,GETDATE())

	DEclare  @endDatePart1 date ,@endDatePart2 date 
	set @endDatePart1 ='2020-06-30'
	set @endDatePart2 ='2020-12-31'
	select IIF(DATEDIFF(DAY,[Invoice / Receipt Date],@endDatePart1)>=0,@endDatePart1,@endDatePart2)
	

	DEclare @year date
	set @year=YEAR('2020-02-10')
	select @year+'06-30'

	select sum(t.Due) from Customer_balance_update t where t.Number='S49917'

	select t.[Invoice / Receipt Date],t.[Warranty Days],t.DueDate2 from Customer_balance_update t where t.BillingModel='in advance'
