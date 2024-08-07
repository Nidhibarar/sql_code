/*
#1:
return users who have booked and completed at least 10 flights, ordered by user_id.
*/

--Solution:

SELECT 
			u.user_id
FROM 
			users u
LEFT JOIN 
					sessions s 
ON 
		u.user_id = s.user_id
LEFT JOIN 
					flights f 
ON 
		s.trip_id = f.trip_id
WHERE 
      cancellation = FALSE
GROUP BY 
				u.user_id
HAVING 
			SUM(CASE WHEN f.trip_id = s.trip_id THEN 1 ELSE 0 END) >= 10
            
;

/*

Que #2: 
Write a solution to report the trip_id of sessions where:

1. session resulted in a booked flight
2. booking occurred in May, 2022
3. booking has the maximum flight discount on that respective day.

If in one day there are multiple such transactions, return all of them.
*/

--solution:

SELECT trip_id 
FROM (
    SELECT
        *,
        DENSE_RANK() OVER (PARTITION BY date(session_start) ORDER BY flight_discount_amount DESC) AS rnk
    FROM sessions 
  WHERE flight_discount_amount IS NOT NULL
  AND flight_booked
  AND extract(month from session_start) = 5
  and extract(year from session_start) = 2022
) AS t
WHERE rnk = 1
ORDER by 
;

/*
#3: 
Write a solution that will, for each user_id of users with greater than 10 flights, 
find out the largest window of days between 
the departure time of a flight and the departure time 
of the next departing flight taken by the user.
*/

-- q3 solution:

WITH RankedFlights AS (
  SELECT s.user_id, f1.departure_time,
         LAG(f1.departure_time) OVER (PARTITION BY s.user_id ORDER BY f1.departure_time) AS prev_departure
  FROM flights f1
  LEFT JOIN sessions s
  	ON f1.trip_id = s.trip_id
)
SELECT user_id,
       MAX(CAST(departure_time AS DATE) - CAST(prev_departure AS DATE)) AS biggest_window
FROM RankedFlights
GROUP BY user_id
HAVING COUNT(*) > 10;

/*
#4: 
Find the user_id’s of people whose origin airport is Boston (BOS) 
and whose first and last flight were to the same destination. 
Only include people who have flown out of Boston at least twice.
*/

--solution:

with leaving_bos as (
SELECT s.user_id,f.departure_time, f.destination_airport 
FROM flights f
join
	sessions s
on
	f.trip_id = s.trip_id
where f.origin_airport = 'BOS'
and s.cancellation = FALSE
),
ranks as (
select *,
DENSE_RANK() OVER(PARTITION BY user_id ORDER BY departure_time ASC) AS RN,
DENSE_RANK() OVER(PARTITION BY user_id ORDER BY departure_time DESC) AS RK
from leaving_bos
order by departure_time
)
select user_id
from
	ranks
where rn = 1 or rk = 1
group by user_id
having count(distinct destination_airport) = 1 and count(user_id) > 1


/*
#5:
Calculate the number of flights with a departure time during the work week (Monday through Friday) and the number of flights departing during the weekend (Saturday or Sunday).

*/
--solution:

SELECT
    COUNT(CASE WHEN EXTRACT(DOW FROM departure_time) 
          BETWEEN 1 AND 5 
          THEN 1 END) AS working_cnt,
    COUNT(CASE WHEN EXTRACT(DOW FROM departure_time) 
          IN (0, 6) 
          THEN 1 END) AS weekend_cnt
FROM
    flights
    
;

/*

#6 
For users that have booked at least 2  trips with a hotel discount, it is possible to calculate their average hotel discount, and maximum hotel discount. write a solution to find users whose maximum hotel discount is strictly greater than the max average discount across all users.

*/
-- solution:

with max_discount as(
select 
				user_id
  			,avg(hotel_discount_amount) as avg_hotel_discount
       ,max(hotel_discount_amount) as max_hotel_discount
from 
			sessions s 
where 
			cancellation = False 
      and 
      hotel_discount = True
      and 
      hotel_booked = True 
group by 
					user_id
having 
				count(user_id) >= 2
)

select 
			 user_id
from 
			max_discount 
where max_hotel_discount > (select max(avg_hotel_discount) from max_discount)
;          
	
/*
#7: 
when a customer passes through an airport we count this as one “service”.

for example:

suppose a group of 3 people book a flight from LAX to SFO with return flights. In this case the number of services for each airport is as follows:

3 services when the travelers depart from LAX

3 services when they arrive at SFO

3 services when they depart from SFO

3 services when they arrive home at LAX

for a total of 6 services each for LAX and SFO.

find the airport with the most services.

*/
--solution:

with cte as (
select user_id,
    avg(hotel_discount_amount) as avg_discount,
    max(hotel_discount_amount) as max_discount
    from sessions
  	where trip_id is not null
    and not cancellation
  	and hotel_discount
    group by user_id
  	having count(user_id) > 1
)
select user_id from cte where max_discount>(select max(avg_discount) from cte)
; 

/*
#8: 
using the definition of “services” provided in the previous question, we will now rank airports by total number of services. 

write a solution to report the rank of each airport as a percentage, where the rank as a percentage is computed using the following formula: 

`percent_rank = (airport_rank - 1) * 100 / (the_number_of_airports - 1)`

The percent rank should be rounded to 1 decimal place. airport rank is ascending, such that the airport with the least services is rank 1. If two airports have the same number of services, they also get the same rank.

Return by ascending order of rank

E**xpected column names: airport, percent_rank**
*/

--solution:

with cte0 
as (
select 
	origin_airport as airport,
  sum(seats) + sum(seats*return_flight_booked::int) as serviced
from
	flights
group by
	origin_airport
union all
select 
	destination_airport as airport,
  sum(seats) + sum(seats*return_flight_booked::int) as serviced
from
	flights
group by
	destination_airport
),
cte1 as (
select 
	airport,
  sum(serviced) as total_served
from
	cte0
group by
	airport
)
select 
	airport, 
  round(cast(100*percent_rank() over (order by total_served) as numeric),1) as percent_rank 
from cte1
order by percent_rank
;
