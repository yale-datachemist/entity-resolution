# Entity Resolution in the Yale Library Catalog

See the [project planning document](https://docs.google.com/document/d/1AmMHoyixGhvvwqIwh97yxw3B94yUBwzn2YTmVewLBXw/edit?usp=sharing) for details.

Project server: 10.5.38.29

## Entity Designators

We use the Library of Congress Name Authority as the "ground
truth" for representations of authors of works. The data is available
from their Linked Data Service
https://id.loc.gov/authorities/names.html

Using these named entitites, we can then load data from other sources
as embeddings and compare their distance to obtain a confidence of a
match to the existing named entities.


## Initialization

We need to convert the BibFrame ontology into a terminus schema
representation in order to make the GraphQL features available.


## Data pipeline

We have a data pipeline that transforms Marc into ttl files which are
loadable into TerminusDB

Schematically the process is like this:

Marc => Marc XML => Bibframe => Triples => add rdf:List to lists.

From the command line, one can initiate the process of tranformation by envoking `terminus_load_marc` starting in the `~DataChemist/data` folder.

```shell
terminus_load_marc
```


## Generate embeddings from Data

GraphQL query + template

## Obtain results

Best match results.

stand alone web api?


{ "@type" : "Class",
  "@id" : "Document",
  "vector_id" : "xsd:unsignedLong" }
