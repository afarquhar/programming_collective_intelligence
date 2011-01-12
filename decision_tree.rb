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


class DecisionTree
  def initialize(data)
    @data = data
  end
  
  def divide_set(col_index, value)
    part = @data.partition do |ar| 
      x = ar[col_index]
      x.is_a?(Numeric) ? x >= value : x == value
    end
    {:true => part.first, :false => part.last}
  end
  
  def unique_counts
    results = Hash.new {|h, k| h[k] = 0 }
    @data.each do |row|
      res = row.last
      results[res] += 1
    end
    results
  end
  
  def gini_impurity
    total = @data.size
    counts = unique_counts
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
  
  def entropy
    ent = 0.0
    unique_counts.each do |res, count|
      p = count.to_f/@data.size
      ent = ent - p * (Math.log(p)/Math.log(2))
    end
    ent
  end
end

if __FILE__ == $0
  tree = DecisionTree.new(data)
  # puts tree.divide_set(2, 'yes').inspect  
  puts tree.gini_impurity
  puts tree.entropy
  set1 = tree.divide_set(2, 'yes')[:true]
  set2 = tree.divide_set(2, 'yes')[:false]
  
  puts DecisionTree.new(set1).entropy
  puts DecisionTree.new(set1).gini_impurity
  
end


