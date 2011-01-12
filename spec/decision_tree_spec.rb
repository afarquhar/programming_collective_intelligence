require File.join(File.dirname(__FILE__), *%w[.. decision_tree])

describe DecisionTree do
  it "should divide a dataset based on column" do
    data = [["alex", 1],["liz", 2],["someone", 3]]
    DecisionTree.new(data).divide_set(0, "alex").should == {:true => [["alex", 1]], :false => [['liz', 2], ["someone", 3]]}
    DecisionTree.new(data).divide_set(1, 2).should == {:true => [["liz", 2], ["someone", 3]], :false => [['alex', 1]]}
  end
  
  it "should do unique counts" do
    data = [["", 1],["", 2],["", 2],["", 3]]
    DecisionTree.new(data).unique_counts.should == {1 => 1, 2 => 2, 3 => 1}
    
  end
  
end