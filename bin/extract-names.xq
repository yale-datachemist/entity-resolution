xquery version "4.0";

(:~ 
 :
 : Module name: BIBFRAME Contributor Personal Name Extractor
 : Module version: 0.1
 : Date: October 11, 2024
 : License: Apache-2.0
 : Proprietary XQuery extensions used: BaseX DB and File modules
 : XQuery specification: 4.0
 : Module overview: Scrapes BIBFRAME resources for person names and metadata 
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
declare function local:process-contribs(
  $Resource as element()*, 
  $InstanceTitle as xs:string*,
  $bib as xs:string*,
  $WorkTitles as xs:string*,
  $attr as xs:string*,
  $prov as xs:string*,
  $subject as xs:string*,
  $genre as xs:string*,
  $relation as xs:string* := (),
  $HubTitle as xs:string* := ()
) as element()* {
  
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
    then 
      if (db:attribute("relators", $Contribution/bf:role/bf:Role/@rdf:about)/../data(madsrdf:authoritativeLabel))
      then db:attribute("relators", $Contribution/bf:role/bf:Role/@rdf:about)/../data(madsrdf:authoritativeLabel)
      else
        if (db:attribute("relators", $Contribution/bf:role/bf:Role/@rdf:about)/../data(madsrdf:variantLabel))
        then db:attribute("relators", $Contribution/bf:role/bf:Role/@rdf:about)/../data(madsrdf:variantLabel)
        else "Contributor"
    else 
      if (exists($Contribution/bf:role/bf:Role))
      then 
        for $r in $Contribution/bf:role/bf:Role/rdfs:label
        return normalize-space(upper-case(substring($r, 1, 1)) || substring($r, 2))
      else "Contributor"
  return local:serialize(
    $id,
    $key,
    $name,
    $role,
    $InstanceTitle,
    $bib,
    $WorkTitles,
    $attr,
    $prov,
    $subject,
    $genre,
    $relation,
    $HubTitle
  )
    
 
};

declare function local:process-subjects(
  $Resource as element()*, 
  $InstanceTitle as xs:string*,
  $bib as xs:string*,
  $WorkTitles as xs:string*,
  $attr as xs:string*,
  $prov as xs:string*,
  $subject as xs:string*,
  $genre as xs:string*,
  $relation as xs:string* := (),
  $HubTitle as xs:string* := ()
) as element()* {
  
  (: Find all the People who are contributors. 
     Note: this excludes People as subjects. :)
  for $PersonalName in $Resource/bf:subject//bf:Agent[rdf:type/@rdf:resource = "http://www.loc.gov/mads/rdf/v1#PersonalName"]
  
    
  
  (: The ID for the Person :)
  let $id := 
    if (contains($PersonalName/@rdf:about, "iri://d/"))
    then $PersonalName/substring-after(@rdf:about, "iri://d/")
    else $PersonalName/data(@rdf:about)
  let $name := $PersonalName/data(madsrdf:authoritativeLabel)
  
  let $subj := 
    for $s in $subject
    where not($s = $name)
    return $s
  
  (: The bflc:marcKey contains the original MARC-encoded data as a string. :)
  let $key := $PersonalName/data(bflc:marcKey)
  
  (: `$2` in the MARC indicates that this is not an LC name, so we skip it. :)
  where not(contains($key, "$2"))
  let $role := "Subject"
  
    
  return local:serialize(
    $id,
    $key,
    $name,
    $role,
    $InstanceTitle,
    $bib,
    $WorkTitles,
    $attr,
    $prov,
    $subj,
    $genre,
    $relation,
    $HubTitle
  )
    
 
};

declare function local:serialize(
  $id as xs:string*,
  $key as xs:string*,
  $name as xs:string*,
  $role as xs:string*,
  $InstanceTitle as xs:string*,
  $bib as xs:string*,
  $WorkTitles as xs:string*,
  $attr as xs:string*,
  $prov as xs:string*,
  $subject as xs:string*,
  $genre as xs:string*,
  $relation as xs:string* := (),
  $HubTitle as xs:string* := ()
) as element() {
  
  
    <record>
      <entry name="op">Inserted</entry>
      <entry name="string">{
        let $rec := (
          string-join(distinct-values($role), "; ") || ": " || $name,
          "Title: " || $InstanceTitle,
          if (exists($WorkTitles)) then "Variant titles: " || normalize-space(string-join($WorkTitles, "; ")) else (),
          if (exists($relation)) then $relation || ": " || $HubTitle else (),
          if (exists($attr)) then "Attribution: " || $attr else (),
          if (exists($subject)) then "Subjects: " || string-join(distinct-values($subject), "; ") else (),
          if (exists($genre)) then "Genres: " || string-join(distinct-values($genre), "; ") else (),
          if (exists($prov)) then "Provision information: " || string-join(distinct-values($prov), "; ") else ()
        )
        return string-join($rec, "&#10;")
        
      }</entry>
      <entry name="marcKey">{$key}</entry>
      <entry name="person">{$name}</entry>
      <entry name="roles">{string-join(distinct-values($role), "; ")}</entry>
      <entry name="title">{$InstanceTitle}</entry>
      {
        if (exists($attr))
        then <entry name="attribution">{$attr}</entry>
        else <entry name="attribution">NaN</entry>
      }
      {
        if (exists($prov))
        then <entry name="provision">{$prov}</entry>
        else <entry name="provision">NaN</entry>
      }        
      {
        if (exists($subject))
        then <entry name="subjects">{$HubTitle}</entry>
        else <entry name="subjects">NaN</entry>
      }
      {
        if (exists($genre))
        then <entry name="genres">{string-join(distinct-values($genre), "; ")}</entry>
        else <entry name="genres">NaN</entry>
      }      
      {
        if (exists($relation))
        then <entry name="relatedWork">{$HubTitle}</entry>
        else <entry name="relatedWork">NaN</entry>
      }
      <entry name="recordId">{$bib}</entry>
      <entry name="id">{$id}</entry>
    </record>
  
  
};

let $db := "BF"||$N
let $d := db:get($db)
return

  file:write-text($PATH || lower-case($db) || ".json",
  
  csv:serialize(<csv>{
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
    let $attr := $Instance/bf:responsibilityStatement/data()
    let $prov := distinct-values($Instance/*[ends-with(name(), "Statement") and not(name() = "bf:responsibilityStatement")]/data())
    let $C := (
      local:process-contribs($Work, $InstanceTitle, $bib, $WorkTitles, $attr, $prov, $subject, $genre)
      ,
      local:process-subjects($Work, $InstanceTitle, $bib, $WorkTitles, $attr, $prov, $subject, $genre)
            
    )
    let $H :=
      for $Hub in $Hubs
      let $relation := 
        if (exists($Hub/../../bf:relationship[bf:Relationship/rdfs:label]))
        then 
          let $_ := replace(ft:normalize(($Hub/../../bf:relationship/bf:Relationship/rdfs:label)[1]), "\p{P}", "")
          return upper-case(substring($_, 1, 1)) || substring($_, 2)
        else "Related work"
      let $HubTitle := $Hub/bf:title/*/bf:mainTitle
      return (
        local:process-contribs($Hub, $InstanceTitle, $bib, $WorkTitles, $attr, $prov, $subject, $genre, $relation, $HubTitle)
        ,
        local:process-subjects($Hub, $InstanceTitle, $bib, $WorkTitles, $attr, $prov, $subject, $genre, $relation, $HubTitle)
      )
        
    
    let $E :=
      for $Hub in $Expressions
      let $relation := "Version of"  
      let $HubTitle := $Hub/bf:title/*/bf:mainTitle
      return (
        local:process-contribs($Hub, $InstanceTitle, $bib, $WorkTitles, $attr, $prov, $subject, $genre, $relation, $HubTitle)
        ,
        local:process-subjects($Hub, $InstanceTitle, $bib, $WorkTitles, $attr, $prov, $subject, $genre, $relation, $HubTitle)
      )
        
      
    return ($C, $H, $E)
 }</csv>, {"header": true(), "format": "attributes"})
)