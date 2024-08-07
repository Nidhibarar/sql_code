/* #1
Write a solution to find the employee_id of managers with at least 2 direct reports.
*/
-- solution:

SELECT 
        em.reports_to as employee_id       
FROM 
		employee e
JOIN 
		employee em 
ON 
		e.employee_id = em.reports_to
group by 
		em.reports_to
HAVING 
		COUNT(*) >= 2
order by 
		em.reports_to

;

/*
#2: 
Calculate total revenue for MPEG-4 video files purchased in 2024.

Expected column names: total_revenue
*/

--solution:

select 
		sum(i.unit_price * i.quantity) as total_revenue        
from 
		track t
join 
		media_type m
on 
		t.media_type_id = m.media_type_id
join 
		invoice_line i
on
		t.track_id = i.track_id
join 
		invoice ic
on 
		i.invoice_id = ic.invoice_id
where 
		extract(year from ic.invoice_date) =  2024
        AND 
        m.name LIKE '%MPEG-4 video%'
group by 
		m.name 

;

/*
#3: 
For composers appearing in classical playlists, count the number of distinct playlists they appear on and 
create a comma separated list of the corresponding (distinct) playlist names.
*/

--solution:

SELECT 
    t.composer,
    COUNT(DISTINCT p.playlist_id) AS distinct_playlists,
    STRING_AGG(DISTINCT p.name, ',') AS list_of_playlists
FROM 
    track t
JOIN 
    playlist_track pt ON t.track_id = pt.track_id
JOIN 
    playlist p ON pt.playlist_id = p.playlist_id
WHERE 
    t.composer IS NOT NULL
    AND p.name LIKE '%Classical%'
GROUP BY 
    t.composer
ORDER BY 
    t.composer
    
;


/*
#4: 
Find customers whose yearly total spending is strictly increasing*.
*/

--solution:

WITH YearlySpending AS (
    SELECT
        customer_id,
        EXTRACT(YEAR FROM invoice_date) AS transaction_year,
        SUM(total) AS yearly_total_spending
       , LAG(SUM(total)) OVER (PARTITION BY customer_id ORDER BY  EXTRACT(YEAR FROM invoice_date)) AS previous_year_spending		
    FROM
        invoice 
    WHERE
        EXTRACT(YEAR FROM invoice_date) < 2025
    GROUP BY
        customer_id, 
  	    EXTRACT(YEAR FROM invoice_date)
)
,
IncreasingSpending AS (
    SELECT
        customer_id,
        transaction_year,
        yearly_total_spending,
        previous_year_spending,
  		Case 
    	When yearly_total_spending > previous_year_spending
      	Then 1
      	Else -100
      	End as Increased_spend
    FROM
        YearlySpending
    where previous_year_spending is not null
)

SELECT DISTINCT
    customer_id
FROM
    IncreasingSpending
Group by customer_id
having SUM(Increased_spend) > 0
Order by customer_id
     
;


				
