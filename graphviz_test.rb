require 'rubygems'
require 'graphviz'

  # Create a new graph
  g = GraphViz.new( :G, :type => :digraph, :rankdir => "LR")
  
  # Create two nodes
  c0 = g.add_graph("words", :rank => 0)
  w1 = c0.add_node( "word")
  w2 = c0.add_node( "word2")
  w3 = c0.add_node( "word3")

  c1 = g.add_graph("hidden", :rank => 1)
  h1 = c1.add_node( "hidden1")
  h2 = c1.add_node( "hidden2")

  # Create an edge between the two nodes
  g.add_edge( w1, h1, {:penwidth =>  1.0, :arrowhead => 'none'})
  g.add_edge( w1, h2, {:penwidth =>  1.0})
  g.add_edge( w2, h2, {:penwidth =>  1.0})
  g.add_edge( w2, h1, {:penwidth =>  1.0})
  g.add_edge( w3, h1, {:penwidth =>  1.0})
  g.add_edge( w3, h2, {:penwidth =>  1.0})

  # Generate output image
  g.output( :png => "hello_world.png" )