var cy = cytoscape({

  container: document.getElementById('cytoscape-container'),

  elements: [],

  style: [
    {
      selector: 'node',
      style: {
        'background-color': '#C33',
        'color': '#C33',
        'label': 'data(id)'
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
