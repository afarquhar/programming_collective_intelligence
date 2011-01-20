class BiCluster
    attr_reader :vec, :id, :left, :right
    def initialize(vec, id, left = nil, right = nil, distance = 0.0)
      @vec, @left, @right, @distance, @id = vec, left, right, distance, id
    end  
  
  end

  def pearson(a1, a2)
    sum1 = a1.inject(:+)
    sum2 = a2.inject(:+)
    
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

  cluster_range = (0...k)
  max_col = rows.first.size
  col_range = (0...max_col)

  ranges = []
  
  #find min max for each col
  col_range.each do |col|
    colvals = rows.map do |row|
      row[col]
    end
    ranges << [colvals.min, colvals.max]
  end

  #create k centroids
  centroids = []
  cluster_range.each do
    centroids << col_range.map do |i|
      (rand() * (ranges[i][1] - ranges[i][0])) + ranges[i][0]
    end
  end
  
  lastmatches = nil
  matching_rows = nil

  (0..100).each do |x|
    puts "iteration #{x}"
    
    matching_rows = Array.new(k) { Array.new }
    
    #for each centroid, find the nearest rows
    rows.each_index do |j|
      row = rows[j]
      bestmatch = 0
      cluster_range.each do |i|
        dist = pearson(centroids[i], row)
        bestmatch = i if(dist < pearson(centroids[bestmatch], row))
      end
      
      matching_rows[bestmatch] << j
    end
    
    break if(matching_rows == lastmatches)
    lastmatches = matching_rows
    
    cluster_range.each do |i|
      avgs = [0.0] * max_col
      if(matching_rows[i].size > 0)
        matching_rows[i].each do |row|
          col_range.each do |col|
            avgs[col] += rows[row][col]
          end
          avgs.each_index do |j|
            avgs[j] /= matching_rows[i].size
          end
          centroids[i] = avgs
        end
      end
    end
  end
  
  
  return matching_rows
  
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
  rownames << toks.first.strip
  data << toks[1..-1].map {|t| t.strip.to_i }
end

# clust = hcluster(data)
# print_cluster(clust, rownames)
kclust = kcluster(data, 10)
kclust.each_with_index do|clust, i|
  puts "cluster #{i}"
  clust.each do |row_id|
    puts "\t#{rownames[row_id]}"
  end
end
  