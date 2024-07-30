WITH recursive cte AS (
	SELECT location_id, location, parent_id, CAST(location_id AS VARCHAR(200)) AS ids, display_order, CAST(LPAD(display_order, 3, 0) AS VARCHAR(200)) AS depth_order, CAST(location AS VARCHAR(1000)) AS path
	FROM locations
	WHERE parent_id = 0
	UNION ALL
	SELECT l.location_id, l.location, l.parent_id, CONCAT(cte.ids, ',', l.location_id) AS ids, l.display_order, CONCAT(cte.depth_order, '-', LPAD(l.display_order, 3, 0)) AS depth_order, CONCAT(cte.path, ' ► ', l.location) AS path
	FROM cte
	INNER JOIN locations AS l ON cte.location_id = l.parent_id
)
SELECT cte.location_id, cte.location, cte.parent_id, cte.path, cte.ids, cte.display_order, cte.depth_order
FROM cte
ORDER BY cte.depth_order;