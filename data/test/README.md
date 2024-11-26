# Ground-Truth Data

* `benchmark_data_records.jsonl` includes 2,261 records as JSON-Lines. The
  `record` string includes only non-null fields. Individual fields are recorded 
  in the JSON object with null values as appropriate. Relevant fields are:
  * record (combined string)
  * person
  * roles
  * title
  * attribution
  * provision
  * subjects
  * genres
  * recordId
  * id (ID for the person) 
* `benchmark_data_matches.csv` lists perfect matches for all person entities in 
  the data file, in an undirected edge list in the columns **Source** and
  **Target**, which reference the **id** values from the data.



