require 'pstore'
require 'fileutils'

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
    FileUtils.rm('network.pstore')
    @word_ids = []
    @hidden_ids = []
    @url_ids = []
    
    #node outputs
    @activation_inputs = [1.0] * @word_ids.size
    @activation_hidden = [1.0] * @hidden_ids.size
    @activation_outputs = [1.0] * @url_ids.size    
    
    
    @network = PStore.new('network.pstore')
    @network.transaction do |store|
      unless store[:hidden]
        store[:hidden] = []
        store[:input_hidden] = {}
        store[:hidden_output] = {}
      end
    end
  end

  def generate_hidden_node(word_ids, url_ids)
    create_key = word_ids.sort.join("_")
    
    @network.transaction do |store|

      # unless store[:hidden].include? create_key
        store[:hidden] << create_key 
        word_ids.each do |word_id|
          store[:input_hidden][word_id] ||= []
          store[:input_hidden][word_id] << Link.new(word_id, create_key, 1.0/word_ids.size)
        end
        url_ids.each do |url_id|
          store[:hidden_output][create_key] ||= []
          store[:hidden_output][create_key] << Link.new(create_key, url_id, 0.1)
        end
      # end
    end
    
  end
  
  def get_input_hidden_strength(word_id, hidden_id)
    @network.transaction do |store|
      store[:input_hidden][word_id].find {|l| l.to == hidden_id }.strength
    end
  end
  
  def get_hidden_output_strength(hidden_id, output_id)
    @network.transaction do |store|
      store[:hidden_output][hidden_id].find {|l| l.to == output_id }.strength
    end    
  end
  
  def set_input_hidden_strength(word_id, hidden_id, strength)
    @network.transaction do |store|
      store[:input_hidden][word_id].find {|l| l.to == hidden_id }.strength = strength
    end
    
  end
  
  def set_hidden_output_strength(hidden_id, output_id, strength)
    @network.transaction do |store|
      store[:hidden_output][hidden_id].find {|l| l.to == output_id }.strength = strength
    end    
  end

  
  def get_all_hidden_ids(word_ids, url_ids)
    hidden = []

    @network.transaction do |store|
      hidden = word_ids.map do |w|
        store[:input_hidden][w].map {|l| l.to }
      end
      
      store[:hidden_output].each do |h, links|
        links.each do |link|
          hidden << link.from if url_ids.include? link.to
        end
      end
      
    end
    # puts hidden.flatten.uniq
    hidden.flatten.uniq
  end
  
  def setup_network(word_ids, url_ids)
    @word_ids = word_ids
    @hidden_ids = get_all_hidden_ids(word_ids, url_ids)
    @url_ids = url_ids
    
    #node outputs
    # @activation_inputs = [1.0] * @word_ids.size
    # @activation_hidden = [1.0] * @hidden_ids.size
    # @activation_outputs = [1.0] * @url_ids.size
    
    @weights_input = @word_ids.map do |w|
      @hidden_ids.map {|h|  get_input_hidden_strength(w, h) }
    end

    @weights_output = @hidden_ids.map do |h|
      @url_ids.map {|u|  get_hidden_output_strength(h, u) }
    end
    
    # puts @weights_input.inspect
    # puts @weights_output.inspect
  end
  
  def feed_forward
    @word_ids.each_index do |w|
      #is this necessary? setting it above
      @activation_inputs[w] = 1.0
    end
    
    
    @hidden_ids.each_index do |h|
      sum  = 0.0
      @word_ids.each_index do |w|
        sum += @activation_inputs[w] * @weights_input[w][h]
      end
      @activation_hidden[h] = Math.tanh(sum)
    end
    
    @url_ids.each_index do |u|
      sum  = 0.0
      @hidden_ids.each_index do |h|
        sum += @activation_hidden[h] * @weights_output[h][u]
      end
      @activation_outputs[u] = Math.tanh(sum)
    end
    
    @activation_outputs
    
  end
  

  
  def update
    @word_ids.each_index do |i|
      @hidden_ids.each_index do |j|
        set_input_hidden_strength(@word_ids[i], @hidden_ids[j], @weights_input[i][j])
      end
    end
    @hidden_ids.each_index do |j|
      @url_ids.each_index do |k|
        set_hidden_output_strength(@hidden_ids[j], @url_ids[k], @weights_output[j][k])
      end
    end
  end
  
  def get_result(word_ids, url_ids)
    setup_network(word_ids, url_ids)
    feed_forward
  end
  
  def dtanh(y)
    1.0 - y ** 2
  end
  
  def back_propagate(targets, n = 0.5)

    #errors for output
    output_deltas = [0.0] * @url_ids.size
    @url_ids.each_index do |k|
      error = targets[k] - @activation_outputs[k]
      output_deltas[k] =  dtanh(@activation_outputs[k]) * error
    end
    
    #errors for hidden
    hidden_deltas = [0.0] * @hidden_ids.size
    @hidden_ids.each_index do |j|
      error = 0.0
      @url_ids.each_index do |k|
        error = error += output_deltas[k] * @weights_output[j][k]
      end
      hidden_deltas[j] = dtanh(@activation_hidden[j]) * error
    end
    
    #update output weights
    @hidden_ids.each_index do |j|
      @url_ids.each_index do |k|
        change = output_deltas[k] * @activation_hidden[j]
        @weights_output[j][k] += n * change
      end
    end
    
    @word_ids.each_index do |i|
      @hidden_ids.each_index do |j|
        change = hidden_deltas[j] * @activation_inputs[i]
        @weights_input[i][j] += n * change
      end
    end
    
  end
  
  def train_query(word_ids, url_ids, selected_url_id)
    generate_hidden_node(word_ids, url_ids)
    setup_network(word_ids, url_ids)
    feed_forward
    targets = [0.0] * url_ids.size
    i = url_ids.index(selected_url_id)
    targets[i] = 1.0
    back_propagate(targets)
    update
  end
  
  def print_network
    
    @network.transaction do |store|
      puts "input hidden:"
      @word_ids.each do |w|
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
test_urls = [uWorldBank, uRiver, uEarth]

n = Network.new
# n.generate_hidden_node(test_words, test_urls, 0.0)
# n.setup_network(test_words, test_urls)
# n.print_network

# puts n.get_all_hidden_ids([wWorld], [uRiver]).inspect
# 
# puts n.get_result(test_words, test_urls)
n.train_query([wWorld, wBank], [uWorldBank, uRiver, uEarth], uWorldBank)
puts n.get_result([wWorld, wBank], [uWorldBank, uRiver, uEarth])
n.print_network

