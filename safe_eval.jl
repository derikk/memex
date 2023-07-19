const i = im
const e = ℯ
const ln(x) = log(x)

# const trig_funcs = Symbol.([sin    cos    tan    cot    sec    csc
# sinh   cosh   tanh   coth   sech   csch
# asin   acos   atan   acot   asec   acsc
# asinh  acosh  atanh  acoth  asech  acsch
# sind   cosd   tand   cotd   secd   cscd
# asind  acosd  atand  acotd  asecd  acscd])


const basicops = [:+, :-, :*, :/, :^, :√, :sqrt, :∛, :cbrt]
const explog = [:exp, :exp2, :exp10, :log, :ln, :log2, :log10]
const allowedops = Set(basicops ∪ explog ∪ [:binomial, :factorial])

is_safe(::Number; _...) = true
is_safe(::Symbol; _...) = true
is_safe(::Any; _...) = false  # by default, things are dangerous

function is_safe(expr::Expr; safe_ops=allowedops, debug=false)
	if expr.head == :call
		func = expr.args[1]
		if func ∈ safe_ops
			return all(is_safe, expr.args[2:end])
		else
			debug && println(func, " is not an allowed operation.")
			return false
		end
	elseif expr.head ∈ [:vect, :hcat, :vcat, :ncat, :row, :nrow]
		return all(is_safe, expr.args)
	else
		debug && println("Only function calls and arrays are allowed.")
		return false
	end
end

function safe_eval(expr::Expr; safe_ops=allowedops)
	if is_safe(expr; safe_ops)
		return eval(expr)
	else
		error("Expression contains potentially unsafe operations.")
	end
end
safe_eval(s::String) = safe_eval(Meta.parse(s))
