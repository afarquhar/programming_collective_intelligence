require 'rubygems'
require 'pstore'
require 'fileutils'
require 'graphviz'

class Link
  attr_reader :from, :to
  attr_accessor :strength
  
  def initialize(from, to, strength)
    @strength = strength
    @from = from 
    @to = to
  end
  
  def to_s
    "#{@from} >---#{@strength}--> #{@to}"
  end
end

class Network

  def initialize
    FileUtils.rm('network.pstore') if File.exists? 'network.pstore'
    @input_ids = []
    @hidden_ids = []
    @output_ids = []
    
    #node outputs
    @input_activations = [1.0] * @input_ids.size
    @hidden_activations = [1.0] * @hidden_ids.size
    @output_activations = [1.0] * @output_ids.size    
    
    
    @network = PStore.new('network.pstore')
    @network.transaction do |store|
      unless store[:hidden]
        store[:hidden] = []
        store[:input_hidden] = {}
        store[:hidden_output] = {}
      end
    end
  end

  def generate_hidden_node(input_ids, output_ids)
    create_key = "hidden_#{input_ids.sort.join("_")}"

    @network.transaction do |store|
      
      unless store[:hidden].include? create_key
        store[:hidden] << create_key 
        input_ids.each do |input_id|
          store[:input_hidden][input_id] ||= []
          store[:input_hidden][input_id] << Link.new(input_id, create_key, 1.0/input_ids.size)
        end
        output_ids.each do |output_id|
          store[:hidden_output][create_key] ||= []
          store[:hidden_output][create_key] << Link.new(create_key, output_id, 0.1)
        end
      end
    end
    
  end
  
  def get_input_hidden_strength(input_id, hidden_id)
    @network.transaction do |store|
      found = store[:input_hidden][input_id].find {|l| l.to == hidden_id }
      if(!found)
        found = Link.new(input_id, hidden_id, -0.2)
        store[:input_hidden][input_id] << found
      end
      found.strength
        
    end
  end
  
  def get_hidden_output_strength(hidden_id, output_id)
    @network.transaction do |store|
      found = store[:hidden_output][hidden_id].find {|l| l.to == output_id }
      if(!found)
        found = Link.new(hidden_id, output_id, 0.0)
        store[:hidden_output][hidden_id] << found
      end
      
      found.strength
    end    
  end
  
  def set_input_hidden_strength(input_id, hidden_id, strength)
    @network.transaction do |store|
      found = store[:input_hidden][input_id].find {|l| l.to == hidden_id }
      if found
        found.strength = strength 
      else
        store[:input_hidden][input_id] << Link.new(input_id, hidden_id, strength)
      end
    end  
  end
  
  def set_hidden_output_strength(hidden_id, output_id, strength)
    @network.transaction do |store|
      found = store[:hidden_output][hidden_id].find {|l| l.to == output_id }
      if(found)
        found.strength = strength
      else
        store[:hidden_output][hidden_id] << Link.new(hidden_id, output_id, strength)
      end
    end    
  end

  
  def get_all_hidden_ids(input_ids, output_ids)
    hidden = []

    @network.transaction do |store|
      hidden = input_ids.map do |i|
        store[:input_hidden][i].map do |l| 
          l.to if input_ids.include? l.from 
        end 
      end

      store[:hidden_output].each do |h, links|
        links.each do |link|
          hidden << link.from if output_ids.include? link.to
        end
      end
    end

    hidden.flatten.uniq
  end
  
  def setup_network(input_ids, output_ids)
    # puts "setting up network for #{input_ids.inspect}, #{output_ids.inspect}"
    @input_ids = input_ids
    @hidden_ids = get_all_hidden_ids(input_ids, output_ids)
    @output_ids = output_ids
    # puts "found hidden ids: #{@hidden_ids.inspect}"
    

    @weights_input = @input_ids.map do |i|
      @hidden_ids.map {|h|  get_input_hidden_strength(i, h) }
    end

    @weights_output = @hidden_ids.map do |h|
      @output_ids.map {|o|  get_hidden_output_strength(h, o) }
    end

  end
  
  def feed_forward
    @input_ids.each_index do |w|
      @input_activations[w] = 1.0
    end
    
    
    @hidden_ids.each_index do |h|
      sum  = 0.0
      @input_ids.each_index do |i|
        sum += @input_activations[i] * @weights_input[i][h]
      end
      @hidden_activations[h] = Math.tanh(sum)
    end
    
    @output_ids.each_index do |o|
      sum  = 0.0
      @hidden_ids.each_index do |h|
        sum += @hidden_activations[h] * @weights_output[h][o]
      end
      @output_activations[o] = Math.tanh(sum)
    end
    @output_activations
    
  end
  

  
  def update
    @input_ids.each_index do |i|
      @hidden_ids.each_index do |j|
        set_input_hidden_strength(@input_ids[i], @hidden_ids[j], @weights_input[i][j])
      end
    end
    @hidden_ids.each_index do |j|
      @output_ids.each_index do |k|
        set_hidden_output_strength(@hidden_ids[j], @output_ids[k], @weights_output[j][k])
      end
    end
  end
  
  def get_result(input_ids, output_ids)
    setup_network(input_ids, output_ids)
    feed_forward
  end
  
  def dtanh(y)
    1.0 - y ** 2
  end
  
  def back_propagate(targets, n = 0.5)

    #errors for output
    output_deltas = [0.0] * @output_ids.size
    @output_ids.each_index do |k|
      error = targets[k] - @output_activations[k]
      output_deltas[k] =  dtanh(@output_activations[k]) * error
    end
    
    #errors for hidden
    hidden_deltas = [0.0] * @hidden_ids.size
    @hidden_ids.each_index do |j|
      error = 0.0
      @output_ids.each_index do |k|
        error = error += output_deltas[k] * @weights_output[j][k]
      end
      hidden_deltas[j] = dtanh(@hidden_activations[j]) * error
    end
    
    #update output weights
    @hidden_ids.each_index do |j|
      @output_ids.each_index do |k|
        change = output_deltas[k] * @hidden_activations[j]
        @weights_output[j][k] += n * change
      end
    end
    
    @input_ids.each_index do |i|
      @hidden_ids.each_index do |j|
        change = hidden_deltas[j] * @input_activations[i]
        @weights_input[i][j] += n * change
      end
    end
    
  end
  
  def train_query(input_ids, output_ids, selected_url_id)
    generate_hidden_node(input_ids, output_ids)
    setup_network(input_ids, output_ids)
    feed_forward
    targets = [0.0] * output_ids.size
    i = output_ids.index(selected_url_id)
    targets[i] = 1.0
    back_propagate(targets)
    update
  end
  
  def print_network
    
    @network.transaction do |store|
      # Create a new graph
      g = GraphViz.new( :G, :type => :digraph, :rankdir => "LR")
      inputs = g.add_graph("inputs", :rank => 0)
      hidden = g.add_graph("hidden", :rank => 1)
      outputs = g.add_graph("outputs", :rank => 2)
      
      input_hash = {}
      hidden_hash = {}
      output_hash = {}
      
      # Create two nodes
      @input_ids.each do |i|
        store[:input_hidden][i].each do |link|
          input_hash[link] = inputs.add_node(link.from.to_s, :shape => 'box')
        end
      end
      
      store[:hidden].each do |h|
        hidden_hash[h] = hidden.add_node(h, :shape => 'box')
      end
      
      @hidden_ids.each do |h|
        store[:hidden_output][h].each do |link|
          output_hash[link] = outputs.add_node(link.to.to_s, :shape => 'box')
        end
      end
      
      input_hash.each do |link, node|
        g.add_edge(node, hidden_hash[link.to], {:penwidth =>  3 * link.strength, :arrowhead => 'none', :label => sprintf('%.2f', link.strength)})
      end
      
      output_hash.each do |link, node|
        g.add_edge(hidden_hash[link.from], node, {:penwidth =>  3 * link.strength, :arrowhead => 'none', :label => sprintf('%.2f', link.strength)})
      end
      

      g.output( :png => "network.png" )      
      
      
      puts "input hidden:"
      @input_ids.each do |w|
        puts "\t#{store[:input_hidden][w]}"
      end
      
      puts "hidden:"
      store[:hidden].each do |hidden|
        puts "\t#{hidden}"
      end
      
      puts "hidden output"
      @hidden_ids.each do |h|
        puts "\t#{store[:hidden_output][h].join("\n\t")}"
      end
    end
  end

end

wWorld, wRiver, wBank = 101, 102, 103
uWorldBank, uRiver, uEarth =  201, 202, 203
test_words = [wWorld, wBank]

all_urls = [uWorldBank, uRiver, uEarth]

n = Network.new


# n.train_query([wWorld, wBank], all_urls, uWorldBank) 
# puts n.get_result([wWorld, wBank], all_urls)

n.train_query([wWorld, wBank], all_urls, uWorldBank) 
puts "result: #{n.get_result([wWorld, wBank], all_urls).inspect}"

# n.print_network

30.times do
  n.train_query([wWorld, wBank], all_urls, uWorldBank)
  n.train_query([wRiver, wBank], all_urls, uRiver)
  n.train_query([wWorld], all_urls, uEarth)
end

puts n.get_result([wWorld, wBank], all_urls).inspect
puts n.get_result([wRiver, wBank], all_urls).inspect
puts n.get_result([wBank], all_urls).inspect

n.print_network