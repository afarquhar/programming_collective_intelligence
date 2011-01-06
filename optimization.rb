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
      
      puts "#{name} #{origin} #{out[0]}-#{out[1]} $#{out[2]} #{ret[0]}-#{ret[1]} $#{ret[2]}"
      
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
    
    best_solution

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
    puts "found hillclimb solution: #{sol.inspect}"
    return sol
    
  end
  
  def mins(s)
    t = Time.parse(s)
    (t.hour * 60) + t.min 
  end
  
  private 
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

# latest 1148
# earliest 589
# price 2616
# wait 2019
# 4635


o = Optimize.new
o.init
# puts o.mins("5:00")
s = [1,4,3,2,7,3,6,3,2,4,5,3]
# o.print_schedule s
# puts o.solution_cost(s)
domain = [[0,9]] * 12
# puts o.solution_cost(o.randomoptimize(domain))
o.hillclimb(domain)


