/*
#1: 
Installers receive performance based year end bonuses. Bonuses are calculated by taking 10% of the total value of parts installed by the installer.

Calculate the bonus earned by each installer rounded to a whole number. Sort the result by bonus in increasing order.
*/

solution:

SELECT ins.name AS installer_name
		,ROUND(SUM(p.price*o.quantity)/10) AS bonus
FROM installs AS i
INNER JOIN installers AS ins
ON i.installer_id = ins.installer_id
INNER JOIN orders o
ON i.order_id = o.order_id 
INNER JOIN parts p
ON o.part_id = p.part_id
GROUP BY ins.name 
ORDER BY bonus
;


/*
#2: 
RevRoll encourages healthy competition. The company holds a “Install Derby” where installers face off to see who can change a part the fastest in a tournament style contest.

Derby points are awarded as follows:

- An installer receives three points if they win a match (i.e., Took less time to install the part).
- An installer receives one point if they draw a match (i.e., Took the same amount of time as their opponent).
- An installer receives no points if they lose a match (i.e., Took more time to install the part).

We need to calculate the scores of all installers after all matches. Return the result table ordered by `num_points` in decreasing order. 
In case of a tie, order the records by `installer_id` in increasing order.

*/

--solution:
WITH winner_calculation AS (
    SELECT 
        installer_one_id AS installer_id
        ,CASE
            WHEN installer_one_time < installer_two_time 
            THEN 3
            WHEN installer_one_time = installer_two_time 
            THEN 1
            ELSE 0
        END AS points
    FROM install_derby
    UNION ALL
    SELECT 
        installer_two_id AS installer_id
        ,CASE
            WHEN installer_two_time < installer_one_time 
            THEN 3
            WHEN installer_one_time = installer_two_time 
            THEN 1
            ELSE 0
        END AS points
    FROM install_derby
)

SELECT 
    ins.installer_id
    ,ins.name
    ,COALESCE(SUM(w.points), 0) AS num_points
FROM 
    installers AS ins
LEFT JOIN 
    winner_calculation AS w 
    ON ins.installer_id = w.installer_id
GROUP BY 
    ins.installer_id, ins.name
ORDER BY 
    num_points DESC
 	, ins.installer_id
;

/*
#3:

Write a query to find the fastest install time with its corresponding `derby_id` for each installer. 
In case of a tie, you should find the install with the smallest `derby_id`.

Return the result table ordered by `installer_id` in ascending order.
*/

--solution:

with all_times as 
(
  select
  	derby_id,
  	installer_one_id as installer_id,
  	installer_one_time as install_time
  from
  	install_derby
  union all
  select
  	derby_id,
  	installer_two_id as installer_id,
  	installer_two_time as install_time
  from
  	install_derby
  ),
fast_times as
(
  select 
  	derby_id, 
  	installer_id,
  	install_time,
  	rank() over (partition by installer_id order by install_time,derby_id) as _rank
  from
  	all_times
 )
 select derby_id,installer_id,install_time
 from fast_times
 where _rank = 1
;      
          
/*
#4: 
Write a solution to calculate the total parts spending by customers paying for installs on each Friday of every week in November 2023. 
If there are no purchases on the Friday of a particular week, the parts total should be set to `0`.

Return the result table ordered by week of month in ascending order.
*/
--solution:
with ci as (
select 
	o.customer_id, 
     p.price*o.quantity as part_total, 
    i.install_date
from
	installs i
left join
	orders o
on
	i.order_id = o.order_id
left join
	parts p
on
	o.part_id = p.part_id
),
fridays as (
    select date::date as friday 
    from generate_series('2023-11-01'::date, '2023-11-30', '1 day') as date
    where extract(dow from date) = 5
)
select 
    f.friday as november_fridays, 
    coalesce(sum(ci.part_total), 0) as parts_total 
from
    fridays f
left join
    ci on ci.install_date = f.friday
    and extract(month from ci.install_date) = 11
    and extract(dow from ci.install_date) = 5
group by
    f.friday
order by
    f.friday;

;

