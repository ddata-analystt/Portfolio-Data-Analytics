create database customer_transaction;

update customer set gender=NULL where gender='';
update customer set age=NULL where age='';
alter table customer modify age int null;

select * from customer;

create table transaction
(
date_new date,
Id_check int,
ID_client int,
Count_products decimal(10,3),
Sum_payment decimal(10,2));

drop table transaction;

load data infile "C:\\ProgramData\\MySQL\\MySQL Server 8.0\\Uploads\\TRANSACTIONS_NEW.csv"
into table transaction
fields terminated by ','
lines terminated by '\n'
ignore 1 rows;

select * from customer;
select * from transaction;

-- 1.список клиентов с непрерывной историей за год, то есть каждый месяц на регулярной основе без пропусков 
-- за указанный годовой период, средний чек за период с 01.06.2015 по 01.06.2016, средняя сумма покупок за месяц, 
-- количество всех операций по клиенту за период;
select c.Id_client
from customer c join transaction t
on c.Id_client=t.ID_client
where t.date_new between '2015-06-01' and '2016-06-01'
group by c.Id_client
having count(date_format(t.date_new,'%Y-%m'))=12;

select avg(c.total_amount) as avg_total_amout
from customer c join transaction t
on c.Id_client=t.ID_client
where t.date_new between '2015-06-01' and '2016-06-01';

select avg(t.Sum_payment) as avg_sum_payment
from customer c join transaction t
on c.Id_client=t.ID_client
where t.date_new between '2015-06-01' and '2016-06-01';

select avg(total_amount) AS average_monthly_purchase
from 
	(
    select sum(c.Total_amount) as total_amount, month(t.date_new) as month, year(t.date_new) as year 
    from customer c join transaction t
    on c.Id_client=t.ID_client
    group by year, month) AS monthly_totals;
    
select c.id_client, 
       count(distinct DATE_FORMAT(t.date_new, '%Y-%m')) AS months_active,
       avg(t.sum_payment) as avg_check,
       avg(t.sum_payment) * COUNT(t.Id_check) / COUNT(distinct DATE_FORMAT(t.date_new, '%Y-%m')) as avg_monthly_payment,
       count(t.Id_check) as total_transactions
from customer c join transaction t 
on c.id_client = t.Id_client
where t.date_new between '2015-06-01' and '2016-06-01'
group by c.id_client
having months_active = 12;


-- 2.информацию в разрезе месяцев:
-- средняя сумма чека в месяц;
select date_format(date_new, '%Y-%m') as month, avg(sum_payment) as avg_check
from transaction
group by month
order by month;

-- среднее количество операций в месяц;
select date_format(date_new, '%Y-%m') as month, count(ID_client) as avg_count_operations
from transaction
group by month
order by month;

-- среднее количество клиентов, которые совершали операции;
select date_format(date_new, '%Y-%m') as month, 
       count(distinct Id_client) as average_clients
from transaction 
group by month;

-- долю от общего количества операций за год и долю в месяц от общей суммы операций;

select date_format(date_new, '%Y-%m') AS transaction_month,
    (cast(sum(case when date_format(date_new, '%Y') = (select date_format(min(date_new), '%Y') from transaction) then 1 else 0 end) as real) / (select count(*) from (select distinct date_format(date_new, '%Y') as DistinctYears from transaction) as T3)) * 100  as percent_of_yearly_operations,
    (cast(sum(case when date_format(date_new, '%Y') = (select date_format(min(date_new), '%Y') from transaction) then sum_payment else 0 end) as real) / (select sum(sum_payment) from transaction where date_format(date_new, '%Y') = (select date_format(min(date_new), '%Y') from transaction))) * 100 as percent_of_yearly_payment_sum
from transaction
group by 1
order by 1;

-- вывести % соотношение M/F/NA в каждом месяце с их долей затрат;
select date_format(t.date_new, '%Y-%m') as month,
    sum(case when c.gender = 'M' then 1 else 0 end) * 100.0 / COUNT(c.id_client) as male_percent,
    sum(case when c.gender = 'F' then 1 else 0 end) * 100.0 / COUNT(c.id_client) as female_percent,
    sum(case when c.gender is null then 1 else 0 end) * 100.0 / COUNT(c.id_client) as na_percent,
    sum(t.sum_payment) AS total_payment,
    sum(case when c.gender = 'M' then t.sum_payment else 0 end) * 100.0 / SUM(t.sum_payment) as male_payment_percent,
    sum(case when c.gender = 'F' then t.sum_payment else 0 end) * 100.0 / SUM(t.sum_payment) as female_payment_percent,
    sum(case when c.gender is null then t.sum_payment else 0 end) * 100.0 / SUM(t.sum_payment) as na_payment_percent
from transaction t join customer c 
on t.Id_client = c.id_client
group by month
order by month;

-- 3. возрастные группы клиентов с шагом 10 лет и отдельно клиентов, у которых нет данной информации, 
-- с параметрами сумма и количество операций за весь период, и поквартально - средние показатели и %.

select 
    case 
        when age is null then  'Нет информации' 
        when age < 20 then '0-19 old' 
        when age < 30 then '20-29 old' 
        when age < 40 then '30-39 old' 
        when age < 50 then '40-49 old' 
        when age < 60 then '50-59 old' 
        when age < 70 then '60-69 old' 
        when age < 80 then '70-79 old' 
        else '80 и старше' 
    end as age_group,
    count(t.Id_client) as total_transactions,
    sum(t.sum_payment) as total_amount,
    avg(t.sum_payment) as average_payment, 
    (count(t.Id_client) / (select count(Id_client) from customer)) * 100 as percent
from customer c join transaction t 
on c.id_client = t.Id_client
group by age_group
order by age_group;

