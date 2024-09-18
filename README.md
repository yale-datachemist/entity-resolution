# Entity Resolution in the Yale Library Catalog

<!-- See the [project planning document](https://docs.google.com/document/d/1AmMHoyixGhvvwqIwh97yxw3B94yUBwzn2YTmVewLBXw/edit?usp=sharing) for details.

Project server: **10.5.38.152** -->

## NOTES

This project was done with TerminusDB 11.1.12 and VectorLink tag
`preview-20240918`.

Our Rust build uses SIMD instructions, so it needs to be on the
nightly toolchain, and ensuring the rust compile flags enable
avx2. The easiest way to get this right is to use nix, which builds
vectorlink in a predefined environment.

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

## Obtain results from TerminusDB

To get the operations files from terminusdb, first we need to get
record files, and then apply them to a template. This can be done as
follows:

```shell
~/src/entity-resolution/bin/authority-records | pv > authority_records.json
```

This command, `authority-records` is a python file which generates the
authority records with a WOQL query.

The results of this can then be applied to a template with `record2ops`.

```shell
cat authority_records.json | ~/src/entity-resolution/bin/record2ops ~/src/entity-resolution/data/authority.handlebars | pv > authority_ops.json
```

Similarly we can apply this approach to marc records, using the python
command `marc-records`:

```shell
~/src/entity-resolution/bin/marc-records | pv > marc-records.json
cat marc_records.json | ~/src/entity-resolution/bin/record2ops ~/src/entity-resolution/data/marc.handlebars | pv > marc-ops.json
```

## Convert Results file to CSV of matches

`~/src/entity-resolution/bin/matches_table -m
marc-searches-in-loc-data-2.json -i authority_ops.json -u
marc-ops.json | pv > matches.csv`

## Run indexing

Set the open AI key in the environment: `export OPENAI_KEY=...`

And then you can run the indexer against an operations file.

To run the indexing for library of congress data:

```shell
vectorlink load -k $OPENAI_KEY -c fakecommit --domain loc -d vector_storage -i authority_ops.json -m small3
```
To run the indexing for marc records:

```shell
vectorlink load -k $OPENAI_KEY -c fakecommit --domain marc -d vector_storage -i marc_ops.json -m small3
```

## Use Web API to obtain "on-the-fly" results

Set the open AI key in the environment: `export OPENAI_KEY=...`

First, start the server from the data directory with the following invocation (for the Library of Congress dataset):

```shell
vectorlink search-server --key $OPENAI_KEY --directory ~/data/vector_storage --domain 'loc' --commit fakecommit -o ~/data/authority_ops.json
```

To search the Yale records instead, use:

```shell
vectorlink search-server --key $OPENAI_KEY --directory ~/data/vector_storage --domain 'marc' --commit fakecommit -o ~/data/marc-ops.json
```

NOTE: The port can be specified with `--port`.

After starting the server, we can invoke a search for an embedding
string via the web, for instance with the following command:

```shell
curl --get 'http://localhost:8080' --data-urlencode 'string=my search string here'
```
