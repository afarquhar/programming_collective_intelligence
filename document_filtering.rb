class Filtering
  
  def initialize(filename = nil)
    @feature_counts = Hash.new {|h, feature| h[feature] = Hash.new {|h, category| h[category] = 0 }}
    @category_counts = Hash.new {|h, category| h[category] = 0}
    @thresholds = {}
  end
  
  def inc_feature(feature, category)
    @feature_counts[feature][category] += 1
  end
  
  def inc_category(category)
    @category_counts[category] +=1
  end
  
  def feature_count(feature, category)
    return @feature_counts[feature][category].to_f if (@feature_counts[feature] && @feature_counts[feature][category])
    return 0.0
  end
  
  def category_count(category)
    return @category_counts[category].to_f if @category_counts[category]
    return 0.0
  end
  
  def total_count
    @category_counts.values.inject(0) {|memo, c| memo += c}.to_f
  end
  
  def categories
    @category_counts.keys
  end

  def feature_prob(feature, category)
    feature_count(feature, category).to_f/category_count(category).to_f
  end
  
  def feature_prob_weighted(feature, category, weight = 1.0, assumed_prob = 0.5)
    basicprob = feature_prob(feature, category)
    total_occur = categories.map {|c| feature_count(feature, c) }.inject(0) {|memo, c| memo += c }.to_f
    ((weight * assumed_prob) + (total_occur * basicprob))/(weight + total_occur).to_f
  end
  
  def set_threshold(cat, t)
    @thresholds[cat] = t
  end
  
  def get_threshold(cat)
    @thresholds[cat] || 1.0
  end
  
  def classify(doc, default = 'unknown')
    probs = {}
    max = 0.0
    best = nil
    categories.each do |cat|
      probs[cat] = prob(doc, cat)
      if probs[cat] > max
        max = probs[cat] 
        best = cat
      end
      
    end
    
  
  
    probs.each do |cat, prob|
      next if cat == best
      return default if ((probs[cat] * get_threshold(best)) > probs[best])
    end
    return best
    
  end
  
  def sample_train
    train('Nobody owns the water.', 'good')
    train('the quick rabbit jumps fences', 'good')
    train('buy pharmaceuticals now', 'bad')
    train('make quick money at the online casino', 'bad')
    train('the quick brown fox jumps', 'good')
  end
  
  def doc_prob(doc, category)
    features = get_words(doc)
    features.inject(1) {|memo, w| memo *= feature_prob_weighted(w, category) }
  end
  
  def prob(doc, category)
    cat_prob = category_count(category)/total_count
    doc_prob = doc_prob(doc, category)
    doc_prob.to_f * cat_prob
  end
  
  
  def get_words(doc)
    doc.split(/\W+/).delete_if {|w| !((2..19) === w.length) }.map {|w| w.downcase }.uniq
  end
  
  def train(doc, category)
    get_words(doc).each do |feature|
      inc_feature(feature, category)
    end
    
    inc_category(category)
  end
end


if __FILE__ == $0
f = Filtering.new
100.times do f.sample_train end
  puts f.naive_bayes_prob(doc, 'good')
  puts f.naive_bayes_prob(doc, 'bad')
end