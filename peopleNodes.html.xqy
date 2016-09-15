xquery version "1.0-ml";

import module namespace sem = "http://marklogic.com/semantics" at "/MarkLogic/semantics.xqy";

declare option xdmp:mapping "false";

let $personBindings := sem:sparql('
  SELECT ?personId ?name ?mbox
  WHERE {
    ?personId <http://www.w3.org/1999/02/22-rdf-syntax-ns#type> <http://xmlns.com/foaf/0.1/Person> .
    ?personId <http://xmlns.com/foaf/0.1/name> ?name .
    ?personId <http://xmlns.com/foaf/0.1/mbox> ?mbox
  }
')

let $people := map:map()
let $_ :=
    for $personBinding in $personBindings
    let $personId := map:get($personBinding,"personId")
    let $person := map:map()
    let $_ := map:put($person, "name", map:get($personBinding,"name"))
    let $_ := map:put($person, "mbox", map:get($personBinding,"mbox"))

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

let $personNodeStrings :=
    for $personId in map:keys($people)
    let $person := map:get($people, $personId)
    let $personName := map:get($person, "name")
    let $mbox := map:get($person, "mbox")
    let $tip := fn:concat($personId, ", ", $mbox)
    return fn:concat("{ group: 'nodes', data: { id: '", $personName, "', personId: '", $personId, "', ring: 2, tip: '", $tip, "' } }")

let $childOfEdgeStrings :=
    for $personId in map:keys($people)
    let $person := map:get($people, $personId)
    let $personName := map:get($person, "name")
    let $parentIds := map:get($person, "parents")
    for $parentId in $parentIds
    let $parent := map:get($people, $parentId)
    let $parentName := map:get($parent,"name")
    let $childOfNodeId := fn:replace(fn:concat($personName, " ChildOf ", $parentName), " ", "_")
    return fn:concat("{ group: 'edges', data: { id: '", $childOfNodeId, "', source: '", $parentName, "', predicate:'Parent Of', target: '", $personName, "' } }")

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
let $spouseOfEdgeStrings :=
    for $personId in map:keys($spouses)
    let $spouseId := map:get($spouses, $personId)
    let $person := map:get($people, $personId)
    let $personName := map:get($person, "name")
    let $spouse := map:get($people, $spouseId)
    let $spouseName := map:get($spouse, "name")
    let $spouseOfNodeId := fn:replace(fn:concat($personName, " SpouseOf ", $spouseName), " ", "_")
    return fn:concat("{ group: 'edges', data: { id: '", $spouseOfNodeId, "', source: '", $personName, "', predicate:'', target: '", $spouseName, "' }, classes: 'foobar' }")

let $personNodeInsertScript := fn:concat("
            cy.add([", fn:string-join(($personNodeStrings, $childOfEdgeStrings, $spouseOfEdgeStrings), ","), "]);
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
               cy.elements().qtip({ 
                  content: function(){ return this._private.data.tip}, 
                  position: { 
                      my: 'top center', 
                      at: 'bottom center' 
                  }, 
                  style: { 
                      classes: 'qtip-green qtip-rounded', 
                      tip: { 
                          width: 16, 
                          height: 8 
                  }},
                  hide: {
                    event: 'mouseout'
                  },
                  show: {
                    event: 'mouseover'
                  }
              }); 
          ")

return
(
  xdmp:set-response-content-type("text/html"),
  "<!DOCTYPE html>",
  <html xmlns="http://www.w3.org/1999/xhtml">
    <head>
      <title>Person Nodes</title>
      <link rel="stylesheet" type="text/css" href="http://cdnjs.cloudflare.com/ajax/libs/qtip2/2.2.0/jquery.qtip.css" />
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
          <script src="lib/jquery-1.7.1.min.js"></script>
          <script src="lib/jquery.qtip.min.js"></script>
          <script src="lib/cytoscape.js"></script>
          <script src="lib/cytoscape-qtip.js"></script>
          <script src="js/emptyGraph.js"></script>
          <script>{$personNodeInsertScript}</script>
        </div>
    </body>
  </html>
)