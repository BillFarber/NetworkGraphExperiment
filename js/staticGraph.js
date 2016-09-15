var cy = cytoscape({

  container: document.getElementById('cytoscape-container'),

  elements: [
    { data: { id: 'Carl', ring: 8 } },
    { data: { id: 'Phil', ring: 4 } },
    { data: { id: 'Phillip', ring: 8 } },
    { data: { id: 'Shari', ring: 4 } },
    { data: { id: 'Joshua', ring: 1 } },
    { data: { id: 'Maria', ring: 1 } },
    { data: { id: 'CarlChild1', source: 'Carl', predicate:'HasASon', target: 'Phil' } },
    { data: { id: 'PhillipChild1', source: 'Phillip', predicate:'HasADaughter', target: 'Shari' } },
    { data: { id: 'PhilSpouse', source: 'Phil', predicate:'IsMarriedTo', target: 'Shari' }, classes: 'foobar' },
    { data: { id: 'ShariSpouse', source: 'Shari', predicate:'IsMarriedTo', target: 'Phil' }, classes: 'foobar' },
    { data: { id: 'PhilChild1', source: 'Phil', predicate:'HasASon', target: 'Joshua' } },
    { data: { id: 'PhilChild2', source: 'Phil', predicate:'HasADaughter', target: 'Maria' } },
    { data: { id: 'ShariChild1', source: 'Shari', predicate:'HasASon', target: 'Joshua' } },
    { data: { id: 'ShariChild2', source: 'Shari', predicate:'HasADaughter', target: 'Maria' }  }
  ],

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
