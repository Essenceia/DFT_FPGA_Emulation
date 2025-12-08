puts "Hello" 
set code [glob ../src/*.v] 
puts $code

read -sv {$code}


