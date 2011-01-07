require File.join(File.dirname(__FILE__), *%w[.. document_filtering])

describe Filtering do
  it "should split words" do
    f = Filtering.new
    f.get_words("aaa bbb   cc d ").should == ['aaa','bbb','cc']
  end

end

describe Classifier do
  it "should store category counts" do
    c = Classifier.new
    c.category_count('good').should == 0
    c.inc_category('good')
    c.category_count('good').should == 1
  end
  
  it "should store feature counts" do
    c = Classifier.new
    c.feature_count('alex', 'good').should == 0
    c.inc_feature('alex', 'good')
    c.feature_count('alex', 'good').should == 1
  end
  
  it "should train correctly" do
    f = Filtering.new
    f.train("the quick brown fox", 'good')
    f.train("the quick brown", 'good')
    
    f.category_count('good').should == 2
    f.feature_count('fox', 'good').should == 1
    f.total_count.should == 2
    f.feature_prob('fox', 'good').should == 0.5
  end
  
  it "should sample train" do
    f = Filtering.new
    f.sample_train
    f.feature_prob('quick', 'good').should be_close 0.66, 0.01
    
  end

  
end