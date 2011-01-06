require 'time'

class Optimize
  def initialize
    @people = [['Seymour','BOS'],
            ['Franny','DAL'],
            ['Zooey','CAK'],
            ['Walt','MIA'],
            ['Buddy','ORD'],
            ['Les','OMA']]
          
    @destination = 'LGA'
    @flights = Hash.new {|h, k| h[k] = []}
    @logging = false
  end  
  
  def init
    IO.readlines('optimization_schedule.txt').each do |line|
      origin, dest, depart, arrive, price = line.strip.split(',')
      @flights[[origin, dest]] << [depart, arrive, price.to_i]
    end
    log @flights.inspect
  end
  
  def log(msg)
    puts msg if @logging
  end
  
  
  def print_schedule(schedule)
    range_of(schedule).each do |i|
      name = @people[i].first
      origin = @people[i].last
      out, ret  = flights_for(i, origin, @destination, schedule)
      
      puts "#{name}\t#{origin}\t#{out[0]}-#{out[1]}\t$#{out[2]}\t#{ret[0]}-#{ret[1]}\t$#{ret[2]}"
      
    end
  end
  
  
  def solution_cost(schedule)
    totalprice = 0
    latestarrival = 0
    earliestdep = 24 * 60
    
    range_of(schedule).each do |i|
      origin = @people[i].last
      out, ret = flights_for(i, origin, @destination, schedule)
      totalprice += out[2]
      totalprice += ret[2]
      
      latestarrival = (mins(out[1]) > latestarrival) ? mins(out[1]) : latestarrival
      earliestdep = (mins(ret[0]) < earliestdep) ? mins(ret[0]) : earliestdep
      
    end

    log "latest: #{latestarrival}"
    log "earliest: #{earliestdep}"
    
    totalwait = 0
    range_of(schedule).each do |i|
      origin = @people[i].last
      out, ret = flights_for(i, origin, @destination, schedule)
      totalwait += latestarrival - mins(out[1])
      totalwait += mins(ret[0]) - earliestdep
    end
    
    if(earliestdep > latestarrival)
      totalprice += 50
    end
    totalprice + totalwait
  end
  
  def randomoptimize(domain)
    best_cost = 99999999
    best_solution = nil
    
    (0..10000).each do |i|
      solution = random_from(domain)
      
      cost = solution_cost(solution)
      if(cost < best_cost)
        best_cost = cost
        best_solution = solution
      end
    end
    log_solution(best_solution)
    best_solution

  end
  
  def annealingoptimize(domain, temp = 10000.0, cool = 0.95, step = 1)
    vec = random_from(domain)
    
    while temp > 0.1
      i = rand(domain.size)
      dir = rand.round == 0 ? -1 : 1
      vecb = vec.clone
      vecb[i] = vecb[i] += dir
      
      if(vecb[i]) < domain[i][0]
        vecb[i] = domain[i][0]
      end
      if(vecb[i]) > domain[i][1]
        vecb[i] = domain[i][1]
      end
      
      cost_a = solution_cost(vec)
      cost_b = solution_cost(vecb)
      if(cost_b < cost_a)
        vec = vecb
      else
        p = Math.exp(-(cost_b - cost_a)/temp)
        vec = vecb if rand < p
      end
      
      temp = temp * cool
    end
    log_solution(vec)
    vec
  end
  
  def hillclimb(domain)
    
    sol = random_from(domain)
    
    while(true)
      
      # puts "solution: #{sol.inspect}"
      neighbours = [] 
      domain.each_index do |j|
        if(sol[j]) > domain[j][0]
          neighbours << sol[0...j] + [sol[j] - 1] + sol[j + 1..-1]
        end
        if(sol[j]) < domain[j][1]
          neighbours << sol[0...j] + [sol[j] + 1] + sol[j + 1..-1]
        end
      end
      
      current = solution_cost(sol)
      best = current
      
      neighbours.each do |n|
        cost = solution_cost(n)
        if (cost < best)
          best = cost
          sol = n
        end
      end
      break if best == current
    end
    log_solution(sol)
    return sol
    
  end
  
  def mins(s)
    t = Time.parse(s)
    (t.hour * 60) + t.min 
  end
  
  private 
  
  def log_solution(sol)
    puts "solution: #{sol.inspect}"
    puts "cost: #{solution_cost(sol)}"
    print_schedule(sol)
    
  end
  
  def range_of(schedule)
    (0...(schedule.size / 2 ))
  end
  
  def random_from(domain)
    domain.map do |ar|
      rand(ar.last + 1)
    end
  end
  
  def flights_for(person_index, start, finish, schedule)
    out = @flights[[start, finish]][schedule[person_index * 2]]
    ret = @flights[[finish, start]][schedule[(person_index * 2) + 1]]
    [out, ret]
  end
  
end


o = Optimize.new
o.init
s = [1,4,3,2,7,3,6,3,2,4,5,3]

domain = [[0,9]] * 12
 # sol =  o.randomoptimize(domain)
# sol =  o.hillclimb(domain)
 sol = o.annealingoptimize(domain)



