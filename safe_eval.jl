const i = im
const e = ℯ
const ln(x) = log(x)

# const trig_funcs = Symbol.([sin    cos    tan    cot    sec    csc
# sinh   cosh   tanh   coth   sech   csch
# asin   acos   atan   acot   asec   acsc
# asinh  acosh  atanh  acoth  asech  acsch
# sind   cosd   tand   cotd   secd   cscd
# asind  acosd  atand  acotd  asecd  acscd])



const operations = [:+, :-, :*, :/, :^, :√, :sqrt, :∛, :cbrt]
const constants = [:π, :pi, :e, :im, :i]
const explog = [:exp, :log, :ln, :log2, :log10]
# const operations = Symbol.([+, -, *, /, ^, √, sqrt, ∛, cbrt])
const allowedops = operations ∪ explog ∪ [:binomial, :factorial]

is_safe(::Number; _...) = true
is_safe(::Symbol; _...) = true
is_safe(::Any; _...) = false  # by default, things are dangerous

function is_safe(expr::Expr; safe_ops=allowedops, debug=false)
	if expr.head != :call  # TODO: allow vectors?
		debug && println("Only calls are allowed.")
		return false
	end

	func = expr.args[1]
	if func ∉ safe_ops
		debug && println(func, " is not an allowed operation.")
		return false
	end

	return all(is_safe.(expr.args[2:end]))
end

function safe_eval(expr::Expr; safe_ops=allowedops)
	if is_safe(expr; safe_ops)
		return eval(expr)
	else
		error("Expression contains potentially unsafe operations.")
	end
end
safe_eval(s::String) = safe_eval(Meta.parse(s))



# is_safe(s::Symbol) = s ∈ [:+, :-, :*, :/, :^, :√, :sqrt, :∛, :cbrt, :π, :pi, :e, :im, :i]
# is_safe(e::Expr) = e.head == :call && all(is_safe.(e.args))  # TODO: allow :vect?

# is_safe(e::Expr; safe_ops=allowed_ops) = e.head == :call && e.args[1] ∈ safe_ops && all(is_safe.(e.args[2:end]))

#=function is_safe(expr::Expr)
	if expr.head != :call  # TODO: allow vectors
		println("Only calls are allowed.")
		return false
	end
	# func = expr.args[1]
	# safe_funcs = [:+, :-, :*, :/, :^, :√, :sqrt]
	# if func ∉ safe_funcs
	# 	println(func, " is not an allowed operation.")
	# 	return false
	# end
	return all(is_safe.(expr.args))
end=#