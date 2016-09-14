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
  SELECT ?person ?name
  WHERE {
    ?person <http://www.w3.org/1999/02/22-rdf-syntax-ns#type> <http://xmlns.com/foaf/0.1/Person> .
    ?person <http://xmlns.com/foaf/0.1/name> ?name
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
                    return <tr><td>{map:get($person,"person")}</td><td>{map:get($person,"name")}</td></tr>
                }
            </table>
          </div>
        </div>
    </body>
  </html>
)