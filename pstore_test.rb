require 'pstore'

test = PStore.new('test')
test.transaction do
  test << 'hello'
  test << 'world'
end

test.transaction do
  # puts 
end