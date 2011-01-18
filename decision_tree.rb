data = [["slashdot","USA","yes",18,"None"],
["google","France","yes",23,"Premium"],
["digg","USA","yes",24,"Basic"],
["kiwitobes","France","yes",23,"Basic"],
["google","UK","no",21,"Premium"],
["(direct)","New Zealand","no",12,"None"],
["(direct)","UK","no",21,"Basic"],
["google","USA","no",24,"Premium"],
["slashdot","France","yes",19,"None"],
["digg","USA","no",18,"None"],
["google","UK","no",18,"None"],
["kiwitobes","UK","no",19,"None"],
["digg","New Zealand","yes",12,"Basic"],
["slashdot","UK","no",21,"None"],
["google","UK","yes",18,"Basic"],
["kiwitobes","France","yes",19,"Basic"]]

class DecisionNode
  attr_reader :col, :value
  attr_accessor :true_branch, :false_branch, :results
  
  def initialize(opts = {})
    
    @col = opts[:col]
    @value = opts[:val]
    @results = opts[:results]
    @true_branch = opts[:true_branch]
    @false_branch = opts[:false_branch]
  end
end

class DecisionTree
  
  def divide_set(data, col_index, value)
    part = data.partition do |ar| 
      x = ar[col_index]
      x.is_a?(Numeric) ? x >= value : x == value
    end
    {:true => part.first, :false => part.last}
  end
  
  def unique_counts(data)
    results = Hash.new {|h, k| h[k] = 0 }
    data.each do |row|
      res = row.last
      results[res] += 1
    end
    results
  end
  
  def gini_impurity(data)
    total = data.size
    counts = unique_counts(data)
    imp = 0
    
    counts.each do |k1, v1|
      p1 = v1.to_f/total
      counts.each do |k2, v2|
        next if k1 == k2
        p2 = v2.to_f/total
        imp += p1 * p2
      end
    end
    imp
  end
  
  def build_tree(data, score_func = :entropy)
    return DecisionNode.new if data.empty?
    current_score = self.send(score_func, data)
    best_gain = 0.0
    best_criteria = nil
    best_sets = nil
    
    column_count = data.first.size - 1
    (0...column_count).each do |col|

      column_values = data.map do |row|
        row[col]
      end.uniq
      
      column_values.each do |value|
        sets = divide_set(data, col, value)
        p = sets[:true].size.to_f / data.size
        set1 = sets[:true]
        set2 = sets[:false]
        set1_score = p * self.send(score_func, set1)
        set2_score = (1.0-p) * self.send(score_func, set2)

        gain = current_score - set1_score - set2_score

        if(gain > best_gain && !set1.empty? && !set2.empty?)
          best_gain = gain
          best_criteria = {:col => col, :value => value}
          best_sets = {:true => set1, :false => set2}
        end
      end
    end
    
    
    if best_gain > 0
      true_branch = build_tree(best_sets[:true])
      false_branch = build_tree(best_sets[:false])
      return DecisionNode.new(:col => best_criteria[:col], :val => best_criteria[:value], :true_branch => true_branch, :false_branch => false_branch)
    else
      return DecisionNode.new(:results => unique_counts(data))
    end
    
  end
  
  def print_tree(root, indent = "  ")
    if(root.results)
      puts root.results.inspect
    else
      puts "#{root.col}: #{root.value}?"
      print "#{indent}T ->"
      print_tree(root.true_branch, indent + "  ")
      print "#{indent}F -> "
      print_tree(root.false_branch, indent + "  ")
    end
  end
  
  def classify(observation, tree)
    return tree.results if tree.results
    v = observation[tree.col]
    branch = nil
    if(v.is_a? Numeric)
      branch = v >= tree.value ? tree.true_branch : tree.false_branch
    else
      branch = v == tree.value ? tree.true_branch : tree.false_branch
    end
    return classify(observation, branch)
  end
  
  def entropy(data)
    ent = 0.0
    u = unique_counts(data)
    u.each do |res, count|
      p = count.to_f/data.size
      ent = ent - p * (Math.log(p)/Math.log(2))
    end
    ent
  end
  
  def prune(tree, mingain)
    # if not leaf node, recurse 
    if(!tree.true_branch.results)
      prune(tree.true_branch, mingain)
    end
    
    if(!tree.false_branch.results)
      prune(tree.false_branch, mingain)
    end
    
    if(tree.true_branch.results && tree.false_branch.results)

      tb, fb = [], []
      tree.true_branch.results.each do |result_key, count|
        count.times do tb << [result_key] end
      end

      tree.false_branch.results.each do |result_key, count|
        count.times do fb << [result_key] end
      end
      # tb.flatten!
      # fb.flatten!
          
      delta = entropy(tb + fb) - (entropy(tb) + entropy(fb)/2)


      if(delta < mingain)

        tree.true_branch, tree.false_branch = nil, nil
        ar = tb + fb

        new_thing = unique_counts(ar)
        tree.results = new_thing
      end
    end
  end
end

if __FILE__ == $0
  tree = DecisionTree.new
  puts tree.gini_impurity(data)
  puts tree.entropy(data)
  set1 = tree.divide_set(data, 2, 'yes')[:true]
  set2 = tree.divide_set(data, 2, 'yes')[:false]
  
  puts DecisionTree.new.entropy(set1)
  puts DecisionTree.new.gini_impurity(set1)
  
  root = tree.build_tree(data)
  tree.print_tree(root)
  # puts tree.classify(['(direct)', "USA", 'yes', 5], root).inspect
  tree.prune(root, 0.1)
  #  tree.print_tree(root)
  tree.prune(root, 1.0)
  tree.print_tree(root)
end


