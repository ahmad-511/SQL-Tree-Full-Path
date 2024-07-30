# Building an Ordered Tree Structure
In this tutorial we'll create a location tree where each location can be a child of another location

Our goal is to return the locations with their full path down to the root parent, something like:
**MSX Building ► Floor 03 ► Dev Department ► Manager Office**

We also want to order the result according to a user-defined display order within each level *(this is the tricky part)*

## Creating Location Table
See the `location-table.sql` table structure (*modify it as needed*)

For testing, you can populate your location table using the file `data-example.sql`

## Building the Tree
This task can be easily done using a recursive CTE (*Common Table Expression*)

```sql
WITH recursive cte AS (
	SELECT location_id, location, location AS location_path, display_order
	FROM locations
	WHERE parent_id = 0
	UNION ALL
	SELECT l.location_id, l.location, CONCAT(cte.location_path, ' ► ', l.location) AS location_path, l.display_order
	FROM cte
	INNER JOIN locations AS l ON cte.location_id = l.parent_id
)
SELECT cte.location_id, cte.location, cte.location_path, cte.display_order
FROM cte
ORDER BY cte.display_order;
```

In the query above we start by extracting main locations (*`parent_id = 0`*)

Then we recursively add all locations with `parent_id` equals to the `location_id` of already extracted parent locations

It will return the with full path for each location

|location_id|location|location_path|display_order|
|---|---|---|---|
|13|Reception|Company ► Level 0 ► Reception|0|
|8|Level 0|Agency ► Level 0|0|
|81|Electronic Control Panel |Company ► Basement ► Electronic Control Panel |0|
|79|General Manager|Company ► LEVEL 4 ► General Manager|0|
|1|Company|Company|0|
|7|Basement|Company ► Basement|0|
|20|Chairman|Company ► Level 2 ► Chairman|0|
|15|ISM Department|Company ► LEVEL 3 ► ISM Department|0|
|26|Port Department|Agency ► Level 0 ► Port Department|0|
|16|Technical Department|Company ► Level 1 ► Technical Department|0|
|75|Buffet |Company ► LEVEL 3 ► Buffet |1|
|45|Meeting|Company ► Level 2 ► Meeting|1|
|4|Level 0|Company ► Level 0|1|
|77|IT Inventory |Company ► Basement ► IT Inventory |1|
|14|Crew Department|Company ► Level 0 ► Crew Department|1|
|64|Marine Manager|Company ► LEVEL 4 ► Marine Manager|1|
|9|Level 1|Agency ► Level 1|1|
|2|Agency|Agency|1|
|76|Buffet |Agency ► Level 1 ► Buffet |1|

---

As you can see our result are not ordered as we want.

The goal is to order the result by the location's `display_order` in every nesting level, something like this:

|location_id|location|path|
|---|---|---|
|1|Company|Company|
|7|Basement|Company ► Basement|
|81|Electronic Control Panel |Company ► Basement ► Electronic Control Panel |
|77|IT Inventory |Company ► Basement ► IT Inventory 
|4|Level 0|Company ► Level 0|
|13|Reception|Company ► Level 0 ► Reception|
|14|Crew Department|Company ► Level 0 ► Crew Department|
|46|Hallway|Company ► Level 0 ► Hallway|

## Correcting the Result Order
As you may noticed it's not an easy task (*we don't know how deep the locations are nested, we cannot insert child records in a specific position while the data being extracted...*)

## String Comparison to the Rescue
This may look weird but it actually does exactly what we need

**A quick reminder**:\
When ordering by a column of type String, the following is happening

- The comparison starts from left to right checking both strings letter by letter
- A letter is considered smaller/greater than another according to its code (**ASCII code for example**)
```
'a' < 'b'
'c' < 'd'
```
- Regardless of the length of the strings, the current checked letters determine whether if the string is smaller/greater than the other
```
'abcd' < 'ac'
'000-000-001' < '000-001'
```
- If two strings start with the same identical letters, the shorter one considered the smaller
```
'000-000-001' < '000-000-0010'
```

With that said, we can now build a string that represent the display order of each nesting level, but since the `display_order` can consists of **1,2,3...** digits we need to normalize them.

Here, Im assuming that display_order doesn't exceed **3** digits **0 - 999** (*can be changed*), so we'll left-pad them with **0** like this **000, 002, 045, 999**

## The Solution
We'll left-pad the location display_order and add it to its parent location display_order to get a sequence of 

```sql
WITH recursive cte AS (
	SELECT location_id, location, CAST(location AS VARCHAR(1000)) AS path, CAST(LPAD(display_order, 3, 0) AS VARCHAR(200)) AS level_order
	FROM locations
	WHERE parent_id = 0
	UNION ALL
	SELECT l.location_id, l.location, CONCAT(cte.path, ' ► ', l.location) AS path, CONCAT(cte.level_order, '-', LPAD(l.display_order, 3, 0)) AS level_order
	FROM cte
	INNER JOIN locations AS l ON cte.location_id = l.parent_id
)
SELECT cte.location_id, cte.location, cte.path, cte.level_order
FROM cte
ORDER BY cte.level_order;
```

And this is what the above query returns:

|location_id|location|path|level_order|
|---|---|---|---|
|1|Company|Company|000|
|7|Basement|Company ► Basement|000-000|
|81|Electronic Control Panel |Company ► Basement ► Electronic Control Panel |000-000-000|
|77|IT Inventory |Company ► Basement ► IT Inventory |000-000-001|
|4|Level 0|Company ► Level 0|000-001|
|13|Reception|Company ► Level 0 ► Reception|000-001-000|
|14|Crew Department|Company ► Level 0 ► Crew Department|000-001-001|
|46|Hallway|Company ► Level 0 ► Hallway|000-001-002|
|11|IT Department|Company ► Level 0 ► IT Department|000-001-003|
|12|IT Inventory|Company ► Level 0 ► IT Inventory|000-001-004|
|80|Electric Control Panel |Company ► Level 0 ► Electric Control Panel |000-001-005|
|5|Level 1|Company ► Level 1|000-002|
|16|Technical Department|Company ► Level 1 ► Technical Department|000-002-000|
|6|Level 2|Company ► Level 2|000-003|
|20|Chairman|Company ► Level 2 ► Chairman|000-003-000|
|45|Meeting|Company ► Level 2 ► Meeting|000-003-001|
|19|Marine Manager|Company ► Level 2 ► Marine Manager|000-003-002|
|67|Broker Department |Company ► Level 2 ► Broker Department |000-003-003|
|18|Accounting Department|Company ► Level 2 ► Accounting Department|000-003-004|
|17|Operation Department|Company ► Level 2 ► Operation Department|000-003-005|
|66|Logistics Department |Company ► Level 2 ► Logistics Department |000-003-006|
|47|Insurance|Company ► Level 2 ► Insurance|000-003-007|
|78|Crew Manager |Company ► Level 2 ► Crew Manager |000-003-008|
|68|Reception |Company ► Level 2 ► Reception |000-003-009|
|74|Buffet |Company ► Level 2 ► Buffet |000-003-010|
|43|Operator|Company ► Level 2 ► Operator|000-003-011|
|56|LEVEL 3|Company ► LEVEL 3|000-004|
|15|ISM Department|Company ► LEVEL 3 ► ISM Department|000-004-000|
---

## Notes
`CAST(location AS VARCHAR(1000)) AS path`
- Make sure to increase the **path** column size **1000** to fit the max expected full location path length

`CAST(LPAD(display_order, 3, 0) AS VARCHAR(200)) AS level_order`
- Here we reserved **3** digits (*plus a separator*) for each level, **200** is enough to fit **50** nested levels (*200 / 4 = 50*) each of which has **1000** locations

- You can change the padding from **3** to something higher or lower depending on how many locations a level can have


Had an issue? you know what to do 😎

Regards