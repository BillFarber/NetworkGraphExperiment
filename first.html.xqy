xquery version "1.0-ml";

declare option xdmp:mapping "false";
(
  xdmp:set-response-content-type("text/html"),
  "<!DOCTYPE html>",
  <html xmlns="http://www.w3.org/1999/xhtml">
    <head>
      <title>Network Display Experiments</title>
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
          <p>Cytoscape</p>
          <div id="cytoscape-container"></div>
          <script src="lib/cytoscape.js"></script>
          <script src="data.js"></script>
          <script>{"
            cy.add([
                { group: 'nodes', data: { id: 'Jacob', ring: 3 } },
                { group: 'nodes', data: { id: 'Allison', ring: 3 } },
                { group: 'edges', data: { id: 'PhilChild3', source: 'Phil', predicate:'HasASon', target: 'Jacob' } },
                { group: 'edges', data: { id: 'ShariChild3', source: 'Shari', predicate:'HasASon', target: 'Jacob' } },
                { group: 'edges', data: { id: 'PhilChild4', source: 'Phil', predicate:'HasADaughter', target: 'Allison' } },
                { group: 'edges', data: { id: 'ShariChild4', source: 'Shari', predicate:'HasADaughter', target: 'Allison' } }
            ]);
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
          "}</script>
        </div>
    </body>
  </html>
)