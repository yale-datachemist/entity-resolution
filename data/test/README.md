# Ground-Truth Datasets

* `Yale_catalog_disambiguated_names.csv` is a list of name clusters with 1+ distinct identities. Each identity is represented by a UUID and is mapped to a Library of Congress IRI when available. 
* `Yale_catalog_names_without_dates.csv` is a list of individual names whose string value matches a Library of Congress name authority record, but which may or may not represent the same entity. If the entities are the same, the `Different?` column has a value of `F`. If the entities are different, the `Different?` column has a value of `T` (or `M` for Maybe). Only the first 50 rows have been reviewed.

URIs/IDs output by the `marc2bibframe2` XSLT converter are recorded in the `Gen_ID` column.
