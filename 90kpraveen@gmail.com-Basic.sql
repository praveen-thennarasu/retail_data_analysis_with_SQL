--SQL Case Study 1 (Basic)

--Data Prep & Understanding

--1. Total number of tables in each tables
--BEGIN
select Count(*) from Customer
select count(*) from prod_cat_info
select count(*) from Transactions
--END

--2. Number of transactions that have returns
--BEGIN
select count(*) from Transactions
where qty < 0
--END

--3. convert date variables into date format
--BEGIN
alter table customer
alter column dob date

alter table transactions
alter column tran_date date
--END

--4. Time range of transaction data available for analysis
-- output in number of days, months, years in different columns
--BEGIN
select 
	min(tran_date) min_date, max(tran_date) as max_date,
	datediff(dd ,min(tran_date), max(tran_date)) as [Number of days] ,
	datediff(mm ,min(tran_date), max(tran_date)) as [Number of months] 	,
	datediff(yyyy ,min(tran_date), max(tran_date)) as [Number of years] 
from Transactions
--END

--5. Which product category	does the sub-category "DIY" belong to 
--BEGIN
select prod_cat from prod_cat_info
where prod_subcat = 'DIY'
--END

---------------------------------------------------------------------------------------------

--Data Analysis

--1. Which channel is most used for transactions
--BEGIN
select top 1 store_type from transactions
group by store_type 
order by count(store_type) desc
--END

--2. Count of male & female customers in database
--BEGIN
select Gender, count(*) as [Count of Gender] from customer
where gender in ('M','F')
group by Gender
--END

---3. From which city do we maximum number of customers and how many
--BEGIN
select top 1 city_code, count(*) [count of customers] from customer
group by city_code
order by [count of customers] desc
--END

--4. How many sub category under books category
--BEGIN
select distinct prod_subcat --count(distinct prod_subcat) 
from prod_cat_info
where prod_cat = 'Books'
--END

--5. What is the maximum quantity of products ever ordered
--BEGIN
select max(qty) max_qty from Transactions
--END

--6. What is the net total revenue generated in categories Electroinics and Books
--BEGIN
select b.*, a.net_total_revenue from
	(select prod_cat_code, sum(total_amt) net_total_revenue from Transactions
	group by prod_cat_code) a
inner join
	(select distinct prod_cat_code, prod_cat from prod_cat_info
	where prod_cat in ('Electronics','Books')) b
on a.prod_cat_code = b.prod_cat_code
--END

--7. How many customers have >10 transactions with us, excluding returns
--BEGIN
select count(*) as tot_cus from 
(
	select cust_id, count(cust_id) number_of_tran
	from Transactions
	group by cust_id
	having count(cust_id) > 10
) a
--END

--8. What is the combined revenue earned from the "Electroincs" & "Clothing" categories, from "Flagship stores"
--BEGIN
select sum(total_amt) as tot_comb_rev --total_amt
from Transactions 
where store_type = 'Flagship Store' and prod_cat_code in 
(	select distinct	prod_cat_code
	from prod_cat_info
	where prod_cat in ('Electronics','Clothing')
)
--END

--9. What is the total revenue generated from "Male" customers in "Electronics" category? 
--	 Output should display total revenue by prod sub-cat
--BEGIN
select b.*, a.tot_rev from
	(select prod_subcat_code, sum(total_amt) tot_rev from Transactions
	where prod_cat_code in 
		(select distinct prod_cat_code from prod_cat_info where prod_cat = 'Electronics')
	and cust_id in
		(select customer_Id from Customer where gender = 'M')
	group by prod_subcat_code) a
left join
	(select distinct prod_sub_cat_code, prod_subcat 
	from prod_cat_info 
	where prod_cat = 'Electronics') b
on a.prod_subcat_code = b.prod_sub_cat_code
--END

--10. What is percentage of sales and returns by product sub category; 
--display only top 5 sub categories in terms of sales

--BEGIN
--(i) CTE Query
with sales_percentage_table as (
	select top 5 prod_cat_code, prod_subcat_code, 
	sum(total_amt)/(select sum(total_amt) from Transactions where total_amt > 0)*100 [Sales_percentage] from Transactions
	where total_amt > 0
	group by prod_cat_code, prod_subcat_code
	order by Sales_percentage desc
	),

return_percentage_table as (
	select prod_cat_code, prod_subcat_code, 
	sum(total_amt)/(select sum(total_amt) from Transactions where total_amt < 0)*100 [Return_percentage] from Transactions
	where total_amt < 0
	group by prod_cat_code, prod_subcat_code
),

code_reference as (
	select distinct prod_cat_code, prod_sub_cat_code, prod_subcat from prod_cat_info
)

select code_reference.prod_subcat, sales_percentage_table.Sales_percentage, return_percentage_table.Return_percentage 
from sales_percentage_table 
left join return_percentage_table
on sales_percentage_table.prod_cat_code = return_percentage_table.prod_cat_code and
	sales_percentage_table.prod_subcat_code = return_percentage_table.prod_subcat_code
left join code_reference
on sales_percentage_table.prod_cat_code = code_reference.prod_cat_code and
	sales_percentage_table.prod_subcat_code = code_reference.prod_sub_cat_code;

	select * from Transactions

--(ii)Subquery 
select c.prod_subcat, a.Sales_percentage, b.Return_percentage from
	(select top 5 prod_cat_code, prod_subcat_code, 
	sum(total_amt)/(select sum(total_amt) from Transactions where total_amt > 0)*100 [Sales_percentage] from Transactions
	where total_amt > 0
	group by prod_cat_code, prod_subcat_code
	order by Sales_percentage desc) a
left join
	(select prod_cat_code, prod_subcat_code, 
	sum(total_amt)/(select sum(total_amt) from Transactions where total_amt < 0)*100 [Return_percentage] from Transactions
	where total_amt < 0
	group by prod_cat_code, prod_subcat_code) b
on a.prod_cat_code = b.prod_cat_code and
a.prod_subcat_code = b.prod_subcat_code
left join
	(select distinct prod_cat_code, prod_sub_cat_code, prod_subcat from prod_cat_info) c
on a.prod_cat_code = c.prod_cat_code and
a.prod_subcat_code = c.prod_sub_cat_code;
--END


--11. For all customers aged between 25 to 35 years find what is the net total revenue generated by these 
--	  consumers in last
--	  30 days of transactions from max transaction date available in the data
--BEGIN
select sum(total_amt) tot_rev from Transactions where cust_id in (
	select customer_Id from Customer
	where DATEDIFF(yyyy,dob, (select max(tran_date) from Transactions) ) <= 35 
	and DATEDIFF(yyyy,dob, (select max(tran_date) from Transactions) ) >=25
)
and tran_date <= (select max(tran_date) from Transactions) 
and tran_date > (select dateadd(day,-30,max(tran_date)) from Transactions)
--END

--12. Which product category has seen the max value of returns in the last 3 months of transactions?
--BEGIN
select b.*, a.return_val from
(
	select top 1 prod_cat_code, sum(total_amt) return_val from Transactions
	where qty < 0 
	and tran_date > (select dateadd(day,-90,max(tran_date)) from Transactions)
	group by prod_cat_code
	order by return_val
) a
left join 
(
	select distinct prod_cat_code, prod_cat from prod_cat_info
) b
on a.prod_cat_code = b.prod_cat_code
--END

--13. Which store-type sells the maximum products; by value of sales amount and by quantity sold?
--BEGIN
select * from
(
	select top 1 Store_type, 'More sold amt' as Descriptio from Transactions
	where Qty > 0
	group by Store_type
	order by sum(total_amt) desc
) a

union

select * from
(
	select top 1 Store_type, 'More sold qty' as Descriptio from Transactions
	where Qty > 0
	group by Store_type
	order by sum(qty) desc
) b
--END

--14. What are the categories for which average revenue is above the overall average.
--BEGIN
select b.*,a.average_rev from 
(
	select prod_cat_code, avg(total_amt) average_rev from Transactions
	group by prod_cat_code
	having avg(total_amt) > (select avg(total_amt) from Transactions)
) a
left join
(
	select distinct prod_cat_code, prod_cat from prod_cat_info
) b
on a.prod_cat_code = b.prod_cat_code
--END

--15. Find the average and total revenue by each subcategory for the categories which are among top 5 categories in terms
--	  of quantity sold
--BEGIN
select b.*,a.avg_rev,a.tot_rev from
(
	select prod_cat_code, prod_subcat_code, AVG(total_amt) avg_rev, sum(total_amt) tot_rev from Transactions
	where prod_cat_code in 
	(
		select top 5 prod_cat_code from Transactions
		where qty > 0
		group by prod_cat_code
		order by sum(qty) desc
	)
	group by prod_cat_code, prod_subcat_code
) a
left join 
(
	select * from prod_cat_info
) b
on a.prod_cat_code = b.prod_cat_code
and a.prod_subcat_code = b.prod_sub_cat_code
--END