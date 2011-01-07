class Classifier
  def initialize(filename = nil)
    @feature_counts = Hash.new {|h, feature| h[feature] = Hash.new {|h, category| h[category] = 0 }}
    @category_counts = Hash.new {|h, category| h[category] = 0}
  end
  
  def inc_feature(feature, category)
    @feature_counts[feature][category] += 1
  end
  
  def inc_category(category)
    @category_counts[category] +=1
  end
  
  def feature_count(feature, category)
    return @feature_counts[feature][category] if (@feature_counts[feature] && @feature_counts[feature][category])
    return 0
  end
  
  def category_count(category)
    return @category_counts[category] if @category_counts[category]
    return 0
  end
  
  def total_count
    @category_counts.values.inject(0) {|memo, c| memo += c}
  end
  
  def categories
    @category_counts.keys
  end
  
end

class Filtering
  
  def method_missing(method, *args)
    @classifier.send(method, *args)
  end
  
  def sample_train
    train('Nobody owns the water.', 'good')
    train('the quick rabbit jumps fences', 'good')
    train('buy pharmaceuticals now', 'bad')
    train('make quick money at the online casino', 'bad')
    train('the quick brown fox jumps', 'good')
  end
  
  def initialize
    @classifier = Classifier.new
  end
  
  def get_words(doc)
    doc.split(/\W+/).delete_if {|w| !((2..19) === w.length) }.uniq
  end
  
  def train(doc, category)
    get_words(doc).each do |feature|
      @classifier.inc_feature(feature, category)
    end
    
    @classifier.inc_category(category)
  end
  
  def feature_prob(feature, category)
    feature_count(feature, category).to_f/category_count(category)
  end
  
end