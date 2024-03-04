# Entity Resolution in the Yale Library Catalog

See the [project planning document](https://docs.google.com/document/d/1AmMHoyixGhvvwqIwh97yxw3B94yUBwzn2YTmVewLBXw/edit?usp=sharing) for details.

Project server: **10.5.38.152**

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

This process was done with a mixture of the tool `bin/owl2terminus`
and some hand modification of input TTL files and the final Schema.

The final, TerminusDB ingestable schema is at
`schema/yale.json`. This schema merges MADS and BIBFRAME and
BIBFRAME-LC extensions and should be useable with all three, or a
mixture.

## Marc Data pipeline

We have a data pipeline that transforms Marc into ttl files which are
loadable into TerminusDB.

Schematically the process is something like this:

Marc => Marc XML => Bibframe => Triples => add rdf:List to lists.

From the command line, one can initiate the process of tranformation
by envoking `terminus_load_marc` starting in the `~DataChemist/data`
folder.

```shell
terminus_load_marc
```

This command will attempt to process all files in the marc/ folder in
parallel and finally merge them into TerminusDB. The entire process
takes less than one hour from a full data load.

## LoC MADS Data pipeline

First run:

`~/src/entity-resolution/bin/loc-data`

This will get the data from the Library of Congress name resources.

Then you can run:

`~/src/entity-resolution/bin/terminus_load_mads`

This will load the data into a TerminusDB.

## Generate embeddings from Data

We generate embeddings with a GraphQL query and a handlebars
template. These can be changed over-time as data processing improves
or we learn better prompting for the embedding strings.

The process involves adding annotations to the schema on the data
types we want to index. (see ...)

## Obtain results

Get the data out of Terminusdb as embedding records

## Run indexing

???

## Obtain all matches as result file

???

## Convert Results file to CSV of matches

`~/src/entity-resolution/bin/matches_table -m marc-searches-in-loc-data-2.json -i authority_ops.json -u marc-ops.json | pv > matches.csv`

## Use Web API to obtain "on-the-fly" results

How do we set up on the fly web requests with matches?
