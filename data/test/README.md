# Ground-Truth Data

* `benchmark_data_records.csv` includes 2,354 records as CSV. The
  `record` string includes only non-null fields. Null fields are left blank. Relevant fields are:
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
* `benchmark_data_matches_expanded.csv` lists true matches (38,796) for all person entities in 
  the data file, in an undirected edge list in the columns **left** and
  **right**, which reference the **id** values from the data. It also includes an equal number of false matches.
* `benchmark_data_matches_with_clusters.csv` lists all true matches (38,796) along with name/identity clusters, in an undirected edge list with IDs in the columns `Source` and `Target`. 

