class Similarity
  
  attr_reader :critics, :films
  
  def initialize
    @critics = {
      'lisa rose' => { 
        'lady in the water' => 2.5,
        'snakes on a plane' => 3.5,
        'just my luck' => 3.0,
        'superman returns' => 3.5,
        'you me and dupree' => 2.5,
        'the night listener' => 3.0,
      },
      'gene seymour' => { 
        'lady in the water' => 3.0,
        'snakes on a plane' => 3.5,
        'just my luck' => 1.5,
        'superman returns' => 5.0,
        'you me and dupree' => 3.5,
        'the night listener' => 3.0,
      },
      'michael phillips' => { 
        'lady in the water' => 2.5,
        'snakes on a plane' => 3.0,
        'superman returns' => 3.5,
        'the night listener' => 4.0,
      },
      'claudia puig' => { 
        'snakes on a plane' => 3.5,
        'just my luck' => 3.0,
        'superman returns' => 4.0,
        'you me and dupree' => 2.5,
        'the night listener' => 4.5,
      },
      'mick lasalle' => { 
        'lady in the water' => 3.0,
        'snakes on a plane' => 4.0,
        'just my luck' => 2.0,
        'superman returns' => 3.0,
        'you me and dupree' => 2.0,
        'the night listener' => 3.0,
      },
      'jack matthews' => { 
        'lady in the water' => 3.0,
        'snakes on a plane' => 4.0,
        'just my luck' => 2.0,
        'superman returns' => 5.0,
        'you me and dupree' => 3.5,
        'the night listener' => 3.0,
      },
      'alex' => {
        'snakes on a plane' => 4.5,
        'you me and dupree' => 1.0,
        'superman returns' => 4.0,
      }
    }
    
    @films = transform_map(@critics)
    
  end
  

  def sim_distance(prefs, p1, p2)

    similarities = similarities(p1, p2)
    return 0 if similarities.size == 0
  
    sum_of_squares = similarities.inject(0) do |memo, film|
      memo += ((@critics[p1][film] - @critics[p2][film]) ** 2)
    end
    # puts sum_of_squares
  
    # return 1.0 / (1 + Math.sqrt(sum_of_squares))
    return 1.0 / (1 + (sum_of_squares))
  end  

  def sim_pearson(prefs, p1, p2)
    similarities = similarities(prefs, p1, p2)
    n = similarities.size
    return 0 if n == 0
    
    sum1 = 0
    sum2 = 0
    sum1sq = 0
    sum2sq = 0
    p_sum = 0
    
    similarities.each do |s|
      sum1 += prefs[p1][s]
      sum2 += prefs[p2][s]
      sum1sq += prefs[p1][s] ** 2
      sum2sq += prefs[p2][s] ** 2
      p_sum += prefs[p1][s] * prefs[p2][s]
    end
    
    num = p_sum - ((sum1 * sum2)/n)
    den = Math.sqrt((sum1sq - (sum1 ** 2)/n) * (sum2sq - (sum2 ** 2)/n))
    return 0 if den == 0
    num/den
    
  end


  
  def top_people_matches(person, n=3, func = :sim_pearson)
    mapped = @critics.keys.map do |other|
      [self.send(func, @critics, person, other), other] if person != other
    end.compact.sort_by do |ar|
      ar.first
    end.reverse.slice(0, n)
  end
  
  def top_film_matches(film, n=3, func = :sim_pearson)
    mapped = @films.keys.map do |other|
      [self.send(func, @films, film, other), other] if film != other
    end.compact.sort_by do |ar|
      ar.first
    end.reverse.slice(0, n)    
  end

  
  def recommendations(prefs, item, func = :sim_pearson)
    
      totals = Hash.new {|h, k| h[k] = 0 }
      simsums = Hash.new {|h, k| h[k] = 0 }

      prefs.each do |other, score_hash|
        next if other == item
        sim = send(func, prefs, item, other)
        score_hash.each do |film, score|
          next unless score == 0 or !prefs[item][film]

          totals[film] += sim * score
          simsums[film] += sim
        end
      end
      
      rankings = []
      totals.each do |film, total|
        rankings<< [total/simsums[film], film]
      end
      
      rankings.sort_by do |ar|
        ar.first
      end.reverse
    
  end
  
  def show_all(method)
    @critics.keys.combination(2).each do |x, y|
      puts "#{x}, #{y} #{self.send(method, x, y)}"
    end
  end

  private
  
  def transform_map(m)
    t = Hash.new {|h, k| h[k] = Hash.new {} }
    m.each do |critic, score_map|
      score_map.each do |film, score|
        t[film][critic] = score
      end
    end
    t
    
  end

  def similarities(prefs, p1, p2)
    similarities = []
  
    prefs[p1].each do |item, rating|
      similarities << item if prefs[p2].has_key? item
    end
  
    similarities
  end


end
sim = Similarity.new
# Similarity.new.show_all(:sim_distance)
# Similarity.new.show_all(:sim_pearson)
 # puts sim.top_people_matches('alex', 3).inspect
 # puts sim.top_film_matches('superman returns', 3).inspect
  puts sim.recommendations(sim.critics, 'alex').inspect
  # puts sim.recommendations(sim.films, 'just my luck').inspect











