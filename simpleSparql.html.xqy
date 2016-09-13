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
        </div>
    </body>
  </html>
)