def wineprice(rating, age)
  peak_age = (rating-50).to_f
  price = rating/2.0
  if age > peak_age
    price = price * (5-(age - peak_age))
  else
    price = price * (5 * ((age + 1)/peak_age))
  end
  
  price < 0 ? 0.0 : price
end

def wineset_1
  rows = []
  (0..300).each do |i|
    rating = rand(50) + 50
    age = rand * 50
    price = wineprice(rating, age)
    price *= rand * 0.4 + 0.8
    rows << {:input => [rating, age], :result => price}
    
  end
  rows
end
puts wineset_1.first.inspect
  

  
  
