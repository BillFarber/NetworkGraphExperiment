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

let $people := sem:sparql('
  SELECT ?personId ?name
  WHERE {
    ?personId <http://www.w3.org/1999/02/22-rdf-syntax-ns#type> <http://xmlns.com/foaf/0.1/Person> .
    ?personId <http://xmlns.com/foaf/0.1/name> ?name
  }
')

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
                    for $person in $people
                    return <tr><td>{map:get($person,"personId")}</td><td>{map:get($person,"name")}</td></tr>
                }
            </table>
          </div>
          <p><b>Person-Person Links:</b></p>
          <div>
            <table>
                {
                    for $person in $people
                    let $personName := map:get($person, "name")
                    let $personId := map:get($person, "personId")
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
                    for $parent in $parents
                    return <tr><td>{map:get($parent, "name")}</td><td>-></td><td>{$personName}</td></tr>
                }
            </table>
          </div>
        </div>
    </body>
  </html>
)