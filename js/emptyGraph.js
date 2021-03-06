var cy = cytoscape({

  container: document.getElementById('cytoscape-container'),

  elements: [],

  style: [
    {
      selector: 'node',
      style: {
        'background-color': '#C33',
        'color': '#C33',
        'label': 'data(label)'
      }
    },
    {
      selector: 'edge',
      style: {
        'width': 1,
        'line-color': '#3CC',
        'color' : '#3CC',
        'mid-target-arrow-color': '#33C',
        'mid-target-arrow-shape': 'triangle',
        'mid-target-arrow-fill': 'filled',
        'source-label': 'data(predicate)',
        'source-text-offset': 100
      }
    },
    {
      selector: 'edge.foobar',
      style: {
        'width': 1,
        'line-color': '#C33',
        'color' : '#C33',
        'mid-target-arrow-color': '#C33',
        'mid-target-arrow-shape': 'diamond',
        'mid-target-arrow-fill': 'filled',
        'source-label': 'data(predicate)',
        'source-text-offset': 100
      }
    }
  ],

  layout: {
    name: 'circle',
    levelWidth: function() {
        return 4;
    },
    concentric: function( node ){
        console.log(node._private.data.ring);
        return node._private.data.ring;
    }
  }

});
