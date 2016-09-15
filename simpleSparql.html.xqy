xquery version "1.0-ml";

import module namespace sem = "http://marklogic.com/semantics" at "/MarkLogic/semantics.xqy";

declare option xdmp:mapping "false";

let $rootSubject := "http://billfarber.org/family/Phil Barber"
let $rootTriples := sem:sparql('
  SELECT ?pred ?obj
  WHERE { 
    <http://billfarber.org/family/Phil\u0020Barber> ?pred ?obj
  }
')

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
        else map:put($person, "parents", map:get($parents, "parentId"))

    return map:put($people, $personId, $person)
let $_ := xdmp:log(("$people",$people))

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
        </div>
    </body>
  </html>
)