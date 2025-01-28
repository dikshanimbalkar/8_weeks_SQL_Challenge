create database study_data;

use study_data;

CREATE TABLE sales (
  customer_id varchar(2),
  order_date DATE,
  product_id int
);

INSERT INTO sales
VALUES
  ('A', '2021-01-01', '1'),
  ('A', '2021-01-01', '2'),
  ('A', '2021-01-07', '2'),
  ('A', '2021-01-10', '3'),
  ('A', '2021-01-11', '3'),
  ('A', '2021-01-11', '3'),
  ('B', '2021-01-01', '2'),
  ('B', '2021-01-02', '2'),
  ('B', '2021-01-04', '1'),
  ('B', '2021-01-11', '1'),
  ('B', '2021-01-16', '3'),
  ('B', '2021-02-01', '3'),
  ('C', '2021-01-01', '3'),
  ('C', '2021-01-01', '3'),
  ('C', '2021-01-07', '3');
  
  
  CREATE TABLE menu (
  product_id int,
  product_name VARCHAR(5),
  price int
);

INSERT INTO menu
VALUES
  ('1', 'sushi', '10'),
  ('2', 'curry', '15'),
  ('3', 'ramen', '12');

CREATE TABLE members (
  customer_id VARCHAR(1),
  join_date DATE
);

INSERT INTO members
VALUES
  ('A', '2021-01-07'),
  ('B', '2021-01-09');

  select * from sales;
  
  select * from menu;
  
  select * from members;
  
  
  -- *******************************************
  -- 1. What is the total amount each customer spent at the restaurant?
  
  select s.customer_id,
  sum(m.price) as total_amount_spend
  from sales s
  join menu m
  on s.product_id = m.product_id
  group by s.customer_id;
  
  
  -- 2. How many days has each customer visited the restaurant?
  
  select customer_id,
  count(distinct order_date) as visit_days
  from sales
  group by customer_id;
  
  -- 3. What was the first item from the menu purchased by each customer?
  
  with cte as (
  select s.customer_id, 
  m.product_name, s.order_date,
  row_number() over(partition by s.customer_id order by s.order_date) as rn
  from sales s
  join menu m on s.product_id = m.product_id)
  select customer_id,
  product_name as first_product_purchesed,
  order_date as first_date
  from cte
  where rn = 1;
  
  -- What is the most purchased item on the menu and how many times was it purchased by all customers
  
select m.product_name,
 count(s.product_id) as total_purchases
 from sales s
 join menu m
 on s.product_id = m.product_id
 group by m.product_name
 order by total_purchases desc
 limit 1;
 
 -- Which item was the most popular for each customer
 
 with Cust_Item_count as(
 select 
 s.customer_id,
 m.product_name,
 count(s.product_id) as total_purchases
 from sales s
 join menu m
 on s.product_id = m.product_id
 group by m.product_name, s.customer_id
 ),
 rankItem as (
 select 
	customer_id, 
    product_name,
    total_purchases,
    row_number() over(partition by customer_id order by total_purchases desc) as rn
    from Cust_Item_count
    )
select 
customer_id,
product_name as most_purches_item,
total_purchases
from rankItem
where rn = 1;
 
 
 -- Which item was purchased first by the customer after they became a member
 
 with cte as (
 select s.customer_id, 
 m.product_name,
 s.order_date
 from sales s
 join menu m on s.product_id = m.product_id
 join members mem on s.customer_id = mem.customer_id
 where s.order_date >= mem.join_date
 ),
 rankedPurchases as (
 select 
 customer_id,
 order_date,
 product_name,
 row_number() over(partition by customer_id order by order_date desc) as rnk
 from cte 
 )
select customer_id,
product_name as first_item,
order_date as first_purchase_date
from rankedPurchases
where rnk = 1;

-- Which item was purchased just before the customer became a member?

 with cte as (
 select s.customer_id, 
 m.product_name,
 s.order_date
 from sales s
 join menu m on s.product_id = m.product_id
 join members mem on s.customer_id = mem.customer_id
 where s.order_date <= mem.join_date
 ),
 rankedPurchases as (
 select 
 customer_id,
 order_date,
 product_name,
 row_number() over(partition by customer_id order by order_date desc) as rnk
 from cte 
 )
select customer_id,
product_name as first_item,
order_date as first_purchase_date_befor
from rankedPurchases
where rnk = 1;


-- What is the total items and amount spent for each member before they became a member?

select mem.customer_id,
count(s.product_id) as total_item,
sum(m.price) as total_amount
from sales s
join members mem on s.customer_id = mem.customer_id
join menu m on s.product_id = m.product_id
where s.order_date < mem.join_date
group by mem.customer_id
order by mem.customer_id;


-- If each $1 spent equates to 10 points and sushi has a 2x points multiplier 
-- - how many points would each customer have?


select s.customer_id,
	sum(case when m.product_name = 'Sushi' then m.price * 20
    else m.price * 10
    end)
    as total_points
from sales s
join menu m on s.product_id = m.product_id
group by s.customer_id
order by s.customer_id;

-- ************************************************************************* 

select s.customer_id,
s.order_date,
m.product_name,
m.price,
case 		
	when s.order_date >= mem.join_date then 'Y' 
    else 'N' 
    end as members
from sales s 
join menu m on s.product_id = m.product_id
left join members mem on s.customer_id = mem.customer_id
order by s.customer_id, s.order_date;


-- ***************************************************************

with cte as(
select s.customer_id,
s.order_date,
m.product_name,
m.price,
case 		
	when s.order_date >= mem.join_date then 'Y' 
    else 'N' 
    end as members,
    rank() over(partition by s.customer_id order by s.order_date, m.product_name) 
    as rank_all
from sales s 
join menu m on s.product_id = m.product_id
left join members mem on s.customer_id = mem.customer_id
)
select   
	customer_id,
    order_date,
    product_name,
    price,
    members,
    case
		when members = 'Y' then rank_all -(
				select min(rank_all) - 1
                from cte
                where members = 'Y' and customer_id = cte.customer_id
                )
		else null
		end as ranking
from cte
ORDER BY customer_id, order_date;

-- ********************************************************************************************************************


