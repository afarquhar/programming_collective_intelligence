require 'pstore'

class Link
  attr_reader :strength, :from, :to
  
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
    @network = PStore.new('network.pstore')
    @network.transaction do |store|
      unless store[:hidden]
        store[:hidden] = []
        ih_hash = {}
        ho_hash = {}
        ih_hash.default = []
        ho_hash.default = []
        
        store[:input_hidden] = ih_hash
        store[:hidden_output] = ho_hash
      end
    end
  end

  def generate_hidden_node(word_ids, url_ids, strength)
    create_key = word_ids.sort.join("_")

    @network.transaction do |store|
      unless store[:hidden].include? create_key
        store[:hidden] << create_key 
        word_ids.each do |word_id|
          store[:input_hidden][word_id] << Link.new(word_id, create_key, 1.0/word_ids.size)
        end
        url_ids.each do |url_id|
          store[:hidden_output][url_id] << Link.new(create_key, url_id, 0.1)
        end
      end
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

  
  def get_all_hidden_ids(word_ids, url_ids)
    hidden = []

    @network.transaction do |store|
      hidden = word_ids.map do |w|
        store[:input_hidden][w].map {|l| l.to }
      end
      hidden << url_ids.map do |u|
        store[:hidden_output][u].map {|l| l.from }
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
    @activation_inputs = [1.0] * @word_ids.size
    @activation_hidden = [1.0] * @hidden_ids.size
    @activation_outputs = [1.0] * @url_ids.size
    
    @weights_input = @word_ids.map do |w|
      @hidden_ids.map {|h|  get_input_hidden_strength(w, h) }
    end

    @weights_output = @hidden_ids.map do |h|
      @url_ids.map {|u|  get_hidden_output_strength(h, u) }
    end
    
    puts @weights_input.inspect
    puts @weights_output.inspect
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
  
  def get_result(word_ids, url_ids)
    setup_network(word_ids, url_ids)
    feed_forward
  end
  
  def print_network
    @network.transaction do |store|
      store[:input_hidden].each do |link|
        puts "\t#{link}"
      end
      
      puts "hidden:"
      store[:hidden].each do |hidden|
        puts "\t#{hidden}"
      end
      
      puts "hidden output"
      store[:hidden_output].each do |link|
        puts "\t#{link}"
      end

    end
  end

end

wWorld, wRiver, wBank = 101, 102, 103
uWorldBank, uRiver, uEarth =  201, 202, 203
test_words = [wWorld, wBank]
test_urls = [uWorldBank, uRiver, uEarth]

n = Network.new
n.generate_hidden_node(test_words, test_urls, 0.0)
# n.print_network
# puts n.get_all_hidden_ids([wWorld], [uRiver]).inspect
# n.setup_network(test_words, test_urls)
puts n.get_result(test_words, test_urls)

