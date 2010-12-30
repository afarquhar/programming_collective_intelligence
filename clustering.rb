class BiCluster
    attr_reader :vec, :id, :left, :right
    def initialize(vec, id, left = nil, right = nil, distance = 0.0)
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

  distances = {}
  current_cluster_id = -1
  
  clusters = []
  rows.each_index {|i| clusters << BiCluster.new(rows[i], i)}
    
  while(clusters.size > 1)
    closest_pair = [clusters[0], clusters[1]]
    closest_distance = pearson(clusters[0].vec, clusters[1].vec)
    
    (0...clusters.size).each do |i|
      ((i+1)...clusters.size).each do |j|
        key = [clusters[i].id, clusters[j].id]
        if(!distances[key]) 
          distances[key] = pearson(clusters[i].vec, clusters[j].vec)
        end
        
        dist = distances[key]
        if(dist < closest_distance)
          closest_distance = dist
          closest_pair = [clusters[i], clusters[j]]
        end
      end
    end
    
    mergevec = []
    
    closest_pair.first.vec.each_with_index do |vec1val, i|
      mergevec << (vec1val + closest_pair.last.vec[i])/2.0
    end
    
    newcluster = BiCluster.new(mergevec, current_cluster_id, closest_pair.first, closest_pair.last, closest_distance)
    current_cluster_id -= 1
    clusters.delete closest_pair.last
    clusters.delete closest_pair.first
    clusters << newcluster
  end
  
  clusters[0]
end

def kcluster(rows, k=4)
  ranges = []
  
  rows.first.each_index do |col|
    colvals = rows.map do |row|
      row[col]
    end
    ranges << [colvals.min, colvals.max]
  end
  
  # puts ranges.inspect
  
  clusters = []
  (0...k).each do |k|
    clusters << (0...rows.first.size).map do |i|
      (rand() * (ranges[i][1] - ranges[i][0])) + ranges[i][0]
    end
  end
  
  lastmatches = nil
    
end

def print_cluster(clust, labels, n=0)
  msg = ""
  msg << " " * n
  if(clust.id < 0)
    msg << "-"
  else
    msg << labels[clust.id]
  end
  puts msg
   print_cluster(clust.left, labels, n +1) if(clust.left)
   print_cluster(clust.right, labels, n +1) if(clust.right)
end


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

# clust = hcluster(data)
# print_cluster(clust, rownames)
kcluster(data)
  