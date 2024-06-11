WITH pond_area AS (
    SELECT id AS pond_id, length * width AS area, deep
    FROM ponds
),
feed_sums AS (
    SELECT cycle_id, SUM(quantity) AS total_feed
    FROM feeds
    GROUP BY cycle_id
),
harvests_data AS (
    SELECT cycle_id, MAX(harvested_at) AS harvested_at, SUM(weight) AS total_weight, MAX(status) AS status
    FROM harvests
    GROUP BY cycle_id
),
samplings_data AS (
    SELECT cycle_id, MAX(sampled_at) AS sampled_at, AVG(average_weight) AS average_weight
    FROM samplings
    GROUP BY cycle_id
),
cycle_details AS (
    SELECT c.id AS cycle_id, c.pond_id, c.total_seed, c.started_at, c.finished_at, pa.area, pa.deep, 
           fs.total_feed, hd.total_weight, hd.harvested_at, hd.status, sd.sampled_at, sd.average_weight
    FROM cycles c
    JOIN pond_area pa ON c.pond_id = pa.pond_id
    LEFT JOIN feed_sums fs ON c.id = fs.cycle_id
    LEFT JOIN harvests_data hd ON c.id = hd.cycle_id
    LEFT JOIN samplings_data sd ON c.id = sd.cycle_id
),
calculated_data AS (
    SELECT cd.*, 
           EXTRACT(EPOCH FROM AGE(cd.harvested_at, cd.sampled_at)) / 86400 AS days_difference,
           (cd.total_weight - cd.average_weight) / NULLIF(EXTRACT(EPOCH FROM AGE(cd.harvested_at, cd.sampled_at)) / 86400, 0) AS ADG,
           cd.total_feed / NULLIF(cd.total_weight, 0) AS FCR,
           cd.total_seed / NULLIF(cd.area, 0) AS stocking_density
    FROM cycle_details cd
),
final_data AS (
    SELECT cd.*, 
           CASE 
               WHEN cd.stocking_density <= 50 AND cd.area BETWEEN 30000 AND 100000 THEN 'ekstentif'
               WHEN cd.stocking_density <= 100 AND cd.area BETWEEN 10000 AND 30000 THEN 'semi intensif'
               WHEN cd.stocking_density <= 200 AND cd.area BETWEEN 2000 AND 10000 THEN 'intensif'
			   WHEN cd.stocking_density <= 500 AND cd.area BETWEEN 500 AND 2000 THEN 'supra intensif'
               ELSE 'Undefined'
           END AS pond_type
    FROM calculated_data cd
)
SELECT * FROM final_data;
