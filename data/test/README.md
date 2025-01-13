# Ground-Truth Data

* `benchmark_data_records.csv` includes 2,288 records as CSV. The
  `record` string includes only non-null fields. Individual fields are recorded 
  with `NaN` values for null fields. Relevant fields are:
  * record (combined string)
  * person
  * roles
  * title
  * attribution
  * provision
  * subjects
  * genres
  * relatedWork
  * recordId
  * id (ID for the person) 
* `benchmark_data_matches.csv` lists perfect matches for all person entities in 
  the data file, in an undirected edge list in the columns **Source** and
  **Target**, which reference the **id** values from the data.

