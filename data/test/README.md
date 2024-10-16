# Ground-Truth Data

* `lib_people_benchmark_data.csv` is a list of name clusters with 1+ distinct identities.
* Each distinct identity is indicated by an integer value in the `Identity` column.
* Each identity is also represented by a UUID and is mapped to a Library of Congress IRI when available.
* IRIs/IDs output by the `marc2bibframe2` XSLT converter are recorded in the `Gen_IDs` column. Because a name can appear multiple times on the same catalog record, some names have multiple values in this column (pipe separated): e.g., `9931651#Agent100-13|9931651#Agent700-45`.
* `lib_people_benchmark_data_filtered` is a pruned version of the benchmark sample with 1,274 records across 54 name clusters in which each cluster contains at least two distinct identities.
* Objects with embedding strings were extracted from catalog records for each field representing a person who contributed to a resource. Results for the records in the full benchmark sample are in `lib_people_benchmark_data_for_embedding.json`.
* Strings were embedded using the OpenAI text-embedding-3-small model.
* Using VectorLink, similarity scores were calculated for each entity, with a cutoff threshhold of 0.15.
* Similarity scores are in `lib_people_benchmark_results.json`.
* Similarity scores for each entity were then mapped to IDs for easier comparison. The ID-mapped version is in `lib_people_benchmark_matches.csv`.



