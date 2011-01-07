require File.join(File.dirname(__FILE__), *%w[.. optimization])

describe Optimize, "" do
  
  before :each do
    @optimize = Optimize.new
    @optimize.init

  end
  
  # it "should do random" do
  #   domain = [[0, 9]] * 12
  #   @optimize.random_optimize(domain)
  # end
  it "should do genetic" do
    domain = [[0, 9]] * 12
    @optimize.genetic_optimize(domain)
  end
  
  # it "should do hillclimb" do
  #   domain = [[0, 9]] * 12
  #   @optimize.hillclimb(domain)
  # end
  # 
  # it "should do annealing" do
  #   domain = [[0, 9]] * 12
  #   @optimize.annealing_optimize(domain)
  # end





end