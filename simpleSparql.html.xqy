xquery version "1.0-ml";

import module namespace sem = "http://marklogic.com/semantics" at "/MarkLogic/semantics.xqy";

declare option xdmp:mapping "false";

let $rootSubject := "Phil Barber"
let $bindings := map:map()
let $_ := map:put($bindings, "rootSubject", $rootSubject)
let $rootTriples := sem:sparql(
    '
        SELECT ?pred ?obj
        WHERE {
            ?subject <http://xmlns.com/foaf/0.1/name> ?rootSubject .
            ?subject ?pred ?obj
        }
    ',
    $bindings
)

let $personBindings := sem:sparql('
  SELECT ?personId ?name
  WHERE {
    ?personId <http://www.w3.org/1999/02/22-rdf-syntax-ns#type> <http://xmlns.com/foaf/0.1/Person> .
    ?personId <http://xmlns.com/foaf/0.1/name> ?name
  }
')

let $people := map:map()
let $_ :=
    for $personBinding in $personBindings
    let $personId := map:get($personBinding,"personId")
    let $person := map:map()
    let $_ := map:put($person, "name", map:get($personBinding,"name"))

    let $bindings := map:map()
    let $_ := map:put($bindings, "personId", $personId)
    let $parents := sem:sparql(
      '
        SELECT ?parentId ?name
        WHERE { 
          ?personId <http://purl.org/vocab/relationship/childOf> ?parentId .
          ?parentId <http://xmlns.com/foaf/0.1/name> ?name
        }
      ',
      $bindings
    )
    let $_ :=
        if (xdmp:describe($parents) = "()") then
            ()
        else
            let $parentIds :=
                for $parent in $parents
                return map:get($parent, "parentId")
            return map:put($person, "parents", $parentIds)

    return map:put($people, $personId, $person)
let $_ := xdmp:log(("$people",$people))

let $spouseBindings := sem:sparql('
  SELECT ?personId ?spouseId
  WHERE {
    ?personId <http://purl.org/vocab/relationship/spouseOf> ?spouseId
  }
')
let $spouses := map:map()
let $_ :=
    for $spouseBinding in $spouseBindings
    let $personId := map:get($spouseBinding,"personId")
    let $spouseId := map:get($spouseBinding,"spouseId")
    return map:put($spouses, $personId, $spouseId)

return
(
  xdmp:set-response-content-type("text/html"),
  "<!DOCTYPE html>",
  <html xmlns="http://www.w3.org/1999/xhtml">
    <head>
      <title>Sparql Queries</title>
    </head>
    <body>
        <div>
          <p><b>Root Subject:</b></p>
          <p>{$rootSubject}</p>
          <p><b>Triples:</b></p>
          <div>
            <table>
                {
                    for $triple in $rootTriples
                    return <tr><td>{map:get($triple,"pred")}</td><td>{map:get($triple,"obj")}</td></tr>
                }
            </table>
          </div>
          <p><b>People:</b></p>
          <div>
            <table>
                {
                    for $personBinding in $personBindings
                    return <tr><td>{map:get($personBinding,"personId")}</td><td>{map:get($personBinding,"name")}</td></tr>
                }
            </table>
          </div>
          <p><b>Person-Person Links:</b></p>
          <div>
            <table>
                {
                    for $personId in map:keys($people)
                    let $person := map:get($people, $personId)
                    let $personName := map:get($person, "name")
                    let $bindings := map:map()
                    let $_ := map:put($bindings, "personId", $personId)
                    let $_ := xdmp:log(("$personId",$personId, $person, map:get($person, "parents")))
                    let $parentIds := map:get($person, "parents")
                    for $parentId in $parentIds
                    let $parent := map:get($people, $parentId)
                    return <tr><td>{map:get($parent,"name")}</td><td>-></td><td>{$personName}</td></tr>
                }
            </table>
          </div>
          <p><b>Spouse Links:</b></p>
          <div>
            <table>
                {
                    for $personId in map:keys($spouses)
                    let $spouseId := map:get($spouses, $personId)
                    let $person := map:get($people, $personId)
                    let $personName := map:get($person, "name")
                    let $spouse := map:get($people, $spouseId)
                    let $spouseName := map:get($person, "name")
                    return <tr><td>{$personName}</td><td>&lt;&gt;</td><td>{$spouseName}</td></tr>
                }
            </table>
          </div>
        </div>
    </body>
  </html>
)