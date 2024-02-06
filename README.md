# Entity Resolution in the Yale Library Catalog

See the [project planning document](https://docs.google.com/document/d/1AmMHoyixGhvvwqIwh97yxw3B94yUBwzn2YTmVewLBXw/edit?usp=sharing) for details.

Project server: 10.5.38.29

>>>>>>> c6ec4fe (Add changes to README)
## Entity Designators

We use the Library of Congress Name Authority as the "ground
truth" for representations of authors of works. The data is available
from their Linked Data Service
https://id.loc.gov/authorities/names.html

Using these named entitites, we can then load data from other sources
as embeddings and compare their distance to obtain a confidence of a
match to the existing named entities.


