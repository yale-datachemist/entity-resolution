Known Problems:

1. `bibframexml/Yale_catalog_export_2024-02-07.8.4.xml` does not generate TTL because of invalid xml
2. The record in the Marc record 8 has a language of '.' specified. The xslt translates this but it is not a valid output for a lang in XML / TTL / RDF 
   The record begins with: "News on the natural history and culture of cotton"
3. The record in 8.5.ttl has the nonsense lang: @eriocampoides limacina.
4. property element 'relatedTo' has multiple object node elements, skipping
