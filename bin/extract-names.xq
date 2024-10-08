xquery version "4.0";

(:~ 
 :
 : Module name: BIBFRAME Contributor Personal Name Extractor
 : Module version: 0.1
 : Date: October 3, 2024
 : License: Apache-2.0
 : Proprietary XQuery extensions used: BaseX DB and File modules
 : XQuery specification: 4.0
 : Module overview: Scraps BIBFRAME resources for person names and metadata 
 : from the associated resource to generate a JSON object with an string for
 : text embedding, along with specific metadata fields.
 : 
 : @author Tim Thompson
 : @version 0.1
 : @see https://github.com/yale-datachemist/entity-resolution
 :
:)

declare namespace rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#";
declare namespace rdfs="http://www.w3.org/2000/01/rdf-schema#";
declare namespace bf="http://id.loc.gov/ontologies/bibframe/";
declare namespace bflc="http://id.loc.gov/ontologies/bflc/"; 
declare namespace madsrdf="http://www.loc.gov/mads/rdf/v1#";
declare namespace skos="http://www.w3.org/2004/02/skos/core#";
declare namespace local="__extract-contributors__";

declare variable $N as xs:string external := "";
declare variable $PATH as xs:string := "";

(:~ 
 : Processes BIBFRAME RDF/XML to extract names and other associated 
 : metadata.
 : 
 : @param $Resource a bf:Work or bf:Hub associated with a contributor name
 : @param $InstanceTitle the main title for the resource
 : @param $bib the system ID from the originating catalog record
 : @param $WorkTitles variant titles associated with the resource
 : @param $subject subject headings associated with the resource
 : @param $genre genre headings associated with the resource
 : @param $relation a relation from a Work to a Hub resource
 : @param $HubTitle title of a Hub resource
 : @return JSON object
 :
 :)
declare function local:process(
  $Resource as element()*, 
  $InstanceTitle as xs:string*,
  $bib as xs:string*,
  $WorkTitles as xs:string*,
  $subject as xs:string*,
  $genre as xs:string*,
  $relation as xs:string* := (),
  $HubTitle as xs:string* := ()
) as xs:string* {
  
  (: Find all the People who are contributors. 
     Note: this excludes People as subjects. :)
  for $Contribution in $Resource/bf:contribution/bf:Contribution[bf:agent/bf:Agent[rdf:type/@rdf:resource = "http://id.loc.gov/ontologies/bibframe/Person"]]  
  
  (: The ID for the Person :)
  let $id := 
    if (contains($Contribution/bf:agent/bf:Agent[rdf:type/@rdf:resource = "http://id.loc.gov/ontologies/bibframe/Person"]/@rdf:about, "iri://d/"))
    then $Contribution/bf:agent/bf:Agent[rdf:type/@rdf:resource = "http://id.loc.gov/ontologies/bibframe/Person"]/substring-after(@rdf:about, "iri://d/")
    else 
      if (exists($relation))
      then 
        
        (: Note: there is currently a bug in the marc2bibframe2 converter that 
           can cause the LC IRI for a Hub to be assigned to the associated 
           Person as well. As a workaround, generate a UUID and concatenate it 
           to the bad IRI. :)
        random:uuid() || "[" || $Contribution/bf:agent/bf:Agent[rdf:type/@rdf:resource = "http://id.loc.gov/ontologies/bibframe/Person"]/data(@rdf:about) || "]"
      else
        $Contribution/bf:agent/bf:Agent[rdf:type/@rdf:resource = "http://id.loc.gov/ontologies/bibframe/Person"]/data(@rdf:about)
  let $name := $Contribution/bf:agent/bf:Agent[rdf:type/@rdf:resource = "http://id.loc.gov/ontologies/bibframe/Person"]/data(rdfs:label)
  
  (: The bflc:marcKey contains the original MARC-encoded data as a string. :)
  let $key := $Contribution/bf:agent/bf:Agent[rdf:type/@rdf:resource = "http://id.loc.gov/ontologies/bibframe/Person"]/data(bflc:marcKey)
  
  (: `$2` in the MARC indicates that this is not an LC name, so we skip it. :)
  where not(contains($key, "$2"))
  let $role := 
  
    (: If a role is specified, we get the label from the LC Relators 
       vocabulary (https://id.loc.gov/vocabulary/relators.html), or else from 
       a label, if supplied. Default is "Contributor." :)
    if (exists($Contribution/bf:role/bf:Role/@rdf:about))
    then db:attribute("relators", $Contribution/bf:role/bf:Role/@rdf:about)/../data(skos:prefLabel)
    else 
      if (exists($Contribution/bf:role/bf:Role))
      then 
        for $r in $Contribution/bf:role/bf:Role/rdfs:label
        return normalize-space(upper-case(substring($r, 1, 1)) || substring($r, 2))
      else "Contributor"
  return 
    serialize(
      <fn:map>
        <fn:string key="op">Inserted</fn:string>
        <fn:string key="string">{
          string-join(distinct-values($role), "; ") || ": " || $name || "&#10;",
          "Title: " || $InstanceTitle || "&#10;",                  
          if (exists($WorkTitles)) then "Variant titles: " || normalize-space(string-join($WorkTitles, "; ")) || "&#10;" else (),        
          if (exists($relation)) then $relation || ": " || $HubTitle || "&#10;" else (),        
          (: if (exists($resp)) then "Attribution: " || $resp || "&#10;" else (), :)
          if (exists($subject)) then "Subjects: " || string-join(distinct-values($subject), "; ") || "&#10;" else (),
          if (exists($genre)) then "Genres: " || string-join(distinct-values($genre), "; ") || "&#10;" else () (: ,
          if (exists($prov)) then "Provision information: " || string-join(distinct-values($prov), "; ") || "&#10;" else () :)    
        }</fn:string>
        <fn:string key="marcKey">{$key}</fn:string>
        <fn:string key="person">{$name}</fn:string>
        <fn:string key="roles">{string-join(distinct-values($role), "; ")}</fn:string>
        <fn:string key="title">{$InstanceTitle}</fn:string>
        {
          if (exists($WorkTitles))
          then <fn:string key="variant_titles">{normalize-space(string-join($WorkTitles, "; "))}</fn:string>
          else <fn:null key="variant_titles"/>
        }
        {
          if (exists($relation))
          then 
            <fn:map key="hub_title">
              <fn:string key="relation">{$relation}</fn:string>
              <fn:string key="title">{$HubTitle}</fn:string>
            </fn:map>
          else <fn:null key="hub_title"/>
        }
        {
          if (exists($subject))
          then <fn:string key="subjects">{string-join(distinct-values($subject), "; ")}</fn:string>
          else <fn:null key="subjects"/>
        }
        {
          if (exists($genre))
          then <fn:string key="genres">{string-join(distinct-values($genre), "; ")}</fn:string>
          else <fn:null key="genres"/>
        }      
        <fn:string key="record">{$bib}</fn:string>
        <fn:string key="id">{$id}</fn:string>
      </fn:map>, {"method": "json", "escape-solidus": "no", "json": map {
        "format": "basic", "indent": "no"
      }}
    )
 
};

let $db := "BF"||$N
let $d := db:get($db)
return

  file:write-text-lines($PATH || lower-case($db) || ".json",
  
    for $Work at $p in $d/rdf:RDF/bf:Work
    
    let $bib := $Work/bf:adminMetadata/bf:AdminMetadata/bf:identifiedBy/bf:Local[bf:assigner/bf:Agent[bf:code = "DLC"]]/data(rdf:value)
    let $WorkTitles := $Work/bf:title/*[not(self::bf:Title)]/string-join(bf:*[contains(lower-case(name()), "title")], ": ")
    let $Expressions := $Work/bf:expressionOf/bf:Hub
    let $Hubs := $Work/bf:relation/bf:Relation/bf:associatedResource/bf:Hub
    let $Instance := $Work/following-sibling::bf:Instance[@rdf:about = $Work/bf:hasInstance/@rdf:resource]
    let $subject := $Work/bf:subject/*/madsrdf:authoritativeLabel/data()
    let $genre := $Work/bf:genreForm/*/rdfs:label/data()
    let $InstanceTitle := 
      normalize-space(string-join(
        for $main in $Instance/bf:title/bf:Title/bf:mainTitle
        return   
          if ($main/following-sibling::*[1][self::bf:subtitle])
          then $main || ": " || $main/following-sibling::*[1][self::bf:subtitle]
          else $main
        , "; "
      ))
    (: let $resp := $Instance/bf:responsibilityStatement/data()
    let $prov := distinct-values($Instance/*[ends-with(name(), "Statement") and not(name() = "bf:responsibilityStatement")]/data()) :)
    let $C := local:process($Work, $InstanceTitle, $bib, $WorkTitles, $subject, $genre)
      
    let $H :=
      for $Hub in $Hubs
      let $relation := 
        if ($Hub/../../bf:relationship[bf:Relationship/rdfs:label])
        then 
          let $_ := replace(ft:normalize($Hub/../../bf:relationship/bf:Relationship/rdfs:label), "\p{P}", "")
          return upper-case(substring($_, 1, 1)) || substring($_, 2)
        else "Related work"
      let $HubTitle := $Hub/bf:title/*/bf:mainTitle
      return 
        local:process($Hub, $InstanceTitle, $bib, $WorkTitles, $subject, $genre, $relation, $HubTitle)
    
    let $E :=
      for $Hub in $Expressions
      let $relation := "Version of"  
      let $HubTitle := $Hub/bf:title/*/bf:mainTitle
      return 
        local:process($Hub, $InstanceTitle, $bib, $WorkTitles, $subject, $genre, $relation, $HubTitle)
      
    return ($C, $H, $E)
 
)