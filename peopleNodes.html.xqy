xquery version "1.0-ml";

import module namespace sem = "http://marklogic.com/semantics" at "/MarkLogic/semantics.xqy";

declare option xdmp:mapping "false";

let $people := sem:sparql('
  SELECT ?person ?name
  WHERE {
    ?person <http://www.w3.org/1999/02/22-rdf-syntax-ns#type> <http://xmlns.com/foaf/0.1/Person> .
    ?person <http://xmlns.com/foaf/0.1/name> ?name
  }
')

let $personNodeStrings :=
    for $person in $people
    return fn:concat("{ group: 'nodes', data: { id: '", map:get($person,"name"), "', ring: 2 } }")
let $personNodeArray := fn:string-join($personNodeStrings, ",")
let $personNodeInsertScript := fn:concat("
            cy.add([", $personNodeArray, "]);
            var layout = cy.makeLayout({
              name: 'circle',
              levelWidth: function() {
                return 4;
              },
              concentric: function( node ){
                console.log(node._private.data.ring);
                return node._private.data.ring;
              }
            });
            layout.run();
          ")

return
(
  xdmp:set-response-content-type("text/html"),
  "<!DOCTYPE html>",
  <html xmlns="http://www.w3.org/1999/xhtml">
    <head>
      <title>Person Nodes</title>
      <style type="text/css">{'
        #cytoscape-container {
            max-width: 800px;
            height: 700px;
            margin: auto;
        }
      '}</style>
      <meta charset="UTF-8"/>
    </head>
    <body>
        <div>
          <div id="cytoscape-container"></div>
          <script src="lib/cytoscape.js"></script>
          <script src="emptyData.js"></script>
          <script>{$personNodeInsertScript}</script>
        </div>
    </body>
  </html>
)