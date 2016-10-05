xquery version "1.0-ml";

import module namespace sem = "http://marklogic.com/semantics" at "/MarkLogic/semantics.xqy";

declare option xdmp:mapping "false";

declare variable $people as map:map := map:map();
declare variable $defaultRootSubject as xs:string := "Shari Barber";

(: ----------- Local Functions -------------------- :)

declare function local:build-person-from-name($person-name as xs:string) as map:map {
  let $bindings := map:map()
  let $_ := map:put($bindings, "rootSubject", $person-name)
  let $personBindings := sem:sparql(
    '
      SELECT ?personId ?mbox
      WHERE {
        ?personId <http://www.w3.org/1999/02/22-rdf-syntax-ns#type> <http://xmlns.com/foaf/0.1/Person> .
        ?personId <http://xmlns.com/foaf/0.1/name> ?rootSubject .
        ?personId <http://xmlns.com/foaf/0.1/mbox> ?mbox
      }
    ',
    $bindings
  )
  return
    if (xdmp:describe($personBindings) = "()") then
      map:map()
    else
      let $rootPersonId := map:get($personBindings,"personId")
      let $rootPerson := map:map()
      let $_ := map:put($rootPerson, "name", $person-name)
      let $_ := map:put($rootPerson, "personId", $rootPersonId)
      let $_ := map:put($rootPerson, "mbox", map:get($personBindings,"mbox"))
      return $rootPerson
};

declare function local:add-parents-to-person($person as map:map) as empty-sequence() {
  let $bindings := map:map()
  let $_ := map:put($bindings, "personId", map:get($person,"personId"))
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
  return ()
};

declare function local:find-all-people-with-relationships($rootPersonId as sem:blank) as item()* {
  let $bindings := map:map()
  let $_ := map:put($bindings, "rootPersonId", $rootPersonId)
  let $relatedPersonBindings := sem:sparql(
    '
      SELECT ?relatedPersonId ?name ?mbox
      WHERE {
        ?relatedPersonId <http://www.w3.org/1999/02/22-rdf-syntax-ns#type> <http://xmlns.com/foaf/0.1/Person> .
        ?relatedPersonId <http://xmlns.com/foaf/0.1/name> ?name .
        ?relatedPersonId <http://xmlns.com/foaf/0.1/mbox> ?mbox

        {?relatedPersonId ?predicate ?rootPersonId }
        UNION
        {?rootPersonId ?predicate ?relatedPersonId }
      }
    ',
    $bindings
  )
  return $relatedPersonBindings
};

declare function local:add-related-people-to-people-map($relatedPersonBindings as item()*, $people as map:map) as empty-sequence() {
  for $relatedPersonBinding in $relatedPersonBindings
  let $personId := map:get($relatedPersonBinding,"relatedPersonId")
  let $person := map:map()
  let $_ := map:put($person, "name", map:get($relatedPersonBinding,"name"))
  let $_ := map:put($person, "mbox", map:get($relatedPersonBinding,"mbox"))

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
};

declare function local:find-spouse($rootPersonId as sem:blank?) as item()* {
  let $bindings := map:map()
  let $_ := map:put($bindings, "personId", $rootPersonId)
  return sem:sparql('
    SELECT ?spouseId
    WHERE {
      ?personId <http://purl.org/vocab/relationship/spouseOf> ?spouseId
    }',
    $bindings
  )
};

(: ----------- Query Response -------------------- :)

let $rootSubject := xdmp:get-request-field("personName", $defaultRootSubject)

let $rootPerson := local:build-person-from-name($rootSubject)
let $rootPersonId :=
  if ( map:get($rootPerson,"personId") ) then
    let $rootPersonId := map:get($rootPerson,"personId")
    let $_ := local:add-parents-to-person($rootPerson)
    let $_ := map:put($people, $rootPersonId, $rootPerson)
    return $rootPersonId
  else
    ()

let $relatedPersonBindings :=
  if ($rootPersonId) then
    local:find-all-people-with-relationships($rootPersonId)
  else
    ()
let $_ := local:add-related-people-to-people-map($relatedPersonBindings, $people)

let $spouseBindings := local:find-spouse($rootPersonId)
let $spouseOfEdgeStrings :=
  for $spouseBinding in $spouseBindings
  let $spouseId := map:get($spouseBinding,"spouseId")
  let $spouseOfNodeId := fn:replace(fn:concat($rootPersonId, " SpouseOf ", $spouseId), " ", "_")
  let $tip := "is married to"
  return fn:concat("{ group: 'edges', data: { id: '", $spouseOfNodeId, "', source: '", $rootPersonId, "', predicate:'', target: '", $spouseId, "', tip: '", $tip, "' }, classes: 'foobar' }")

let $personNodeStrings :=
  for $personId in map:keys($people)
  let $person := map:get($people, $personId)
  let $personName := map:get($person, "name")
  let $ring :=
    if ($personName = $rootSubject) then
      15
    else 1
  let $mbox := map:get($person, "mbox")
  let $tip := fn:concat($personId, ", ", $mbox)
  return fn:concat("{ group: 'nodes', data: { id: '", $personId, "', ring: ", $ring, ", tip: '", $tip, "', label: '", $personName, "' } }")

let $childOfEdgeStrings :=
  for $personId in map:keys($people)
  let $person := map:get($people, $personId)
  let $parentIds := map:get($person, "parents")
  for $parentId in $parentIds
  let $childOfNodeId := fn:replace(fn:concat($personId, " ChildOf ", $parentId), " ", "_")
  let $tip := "is a parent of "
  return fn:concat("{ group: 'edges', data: { id: '", $childOfNodeId, "', source: '", $parentId, "', predicate:'Parent Of', target: '", $personId, "', tip: '", $tip, "' } }")

let $personNodeInsertScript := fn:concat("
            cy.add([", fn:string-join(($personNodeStrings, $childOfEdgeStrings, $spouseOfEdgeStrings), ","), "]);
            var layout = cy.makeLayout({
              name: 'concentric',
              fit: true,
              levelWidth: function() {
                return 2;
              },
              concentric: function( node ){
                return node._private.data.ring;
              }
            });
            layout.run();
            cy.on('click', function(evt){
                var target = evt.cyTarget._private.data.label;
                console.log( 'navigate to: ' + target);
                window.location.href = '/personCentered.html.xqy?personName=' + target;
            });
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
      <title>{ fn:concat("Person Centered (", $rootSubject, ")") }</title>
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
        <div><h3>Root Person ID: { if ($rootPersonId) then $rootPersonId else fn:concat($rootSubject, " not found") }</h3></div>
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