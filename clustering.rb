colnames = []
rownames = []
data = []


lines = IO.readlines("blogdata.txt")
colnames = lines.first.split("\t").map { |x| x.strip}
lines[1..-1].each do |l|
  toks = l.split("\t")
  rownames << toks.first
  data << toks[1..-1].map {|t| t.strip.to_i }
end



  class BiCluster
    attr_reader :vec, :id
    def initialize(vec, left = nil, right = nil, distance = 0.0, id=nil)
      @vec, @left, @right, @distance, @id = vec, left, right, distance, id
    end  
  
  end

  def pearson(a1, a2)
    sum1 = a1.inject(0) {|memo, x| memo += x }
    sum2 = a2.inject(0) {|memo, x| memo += x }
    
    sum1sq = a1.inject(0) {|memo, x| memo += x**2 }
    sum2sq = a2.inject(0) {|memo, x| memo += x**2 }
    
    psum = 0
    a1.each_index do |i|
      psum += a1[i] * a2[i]
    end
    num = psum - ((sum1 * sum2)/a1.size)

    part1 = sum1sq - ((sum1 ** 2)/a1.size)
    part2 = sum2sq - ((sum2 ** 2)/a2.size)
    
    den = Math.sqrt(part1 * part2)
    return 0 if den == 0
    
    1.0 - num/den
  end


def hcluster(rows)
  clusters = []
  distances = {}
  rows.each_index do |i| { clusters << BiCluster.new(rows[i], i)}
    
  while(clusters.size > 1)
    closest_pair_indexes = [0,1]
    closest_distance = pearson(clusters[0].vec, clusters[1].vec)
    
    for(i in 0...clusters.size)
      for(j in (i+1)...clusters.size)
        key = [clusters[i].key, clusters[j].key]
        if(!distances[key]) distances[key] = pearson(clusters[i].vec, clusters[j].vec)
        
        dist = distances[key]
        if(dist < closest)
          closest_distance = dist
          closest_pair_indexes = [i, j]
      end
    end
    
    
  end

end
  