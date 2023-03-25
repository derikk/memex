module Memex
const version = v"0.0.1"

using Dates
import Configurations: @option, Reflect
using Printf
using Unicode: normalize
using StringDistances

""" Content of a memory
E.g. flip card, cloze """
abstract type Card end

@option mutable struct TextCard <: Card
	type::Reflect
	prompt::String
	answer::String
end

@option mutable struct ClozeCard <: Card
	type::Reflect
	sentence::String
end

@option mutable struct FormulaCard <: Card
	type::Reflect
	prompt::String
	variables::NamedTuple  # Map variable names to set to sample from
	formula::Expr  # Calculate the correct answer
end

const CardType = Union{TextCard, ClozeCard, FormulaCard}


@option mutable struct Memory
	repetitions::Int16 = 0   # times correct in a row
	easiness::Float16 = 2.5  # E-Factor, between 1.3 and 2.5
	interval::Int16 = 4      # days until next repetition
	lastreviewed::Date = today()
	cards::Vector{CardType} = [] # ways to test memory 
end

Memory(card::Card) = Memory(cards=[card])
Memory(cards::Vector{<:Card}) = Memory(cards=cards)

@option mutable struct Deck
	version::VersionNumber = Memex.version
	name::String
	lastreviewed::DateTime = now()
	memories::Vector{Memory} = []
end

""" SuperMemo 2 algorithm """
function update!(m::Memory, grade::Real)
	if grade >= 3
		m.repetitions += 1

		m.easiness += -0.8 + 0.28*grade - 0.02*grade^2
		if m.easiness < 1.3
			println("This card seems tough to remember! Try rewriting it.")
			m.easiness = 1.3
		end

		m.interval = floor(m.interval * m.easiness)
	else
		m.repetitions = 0
		m.interval = 1
	end
	m.lastreviewed = now()
end

function review!(deck::Deck)
	toreview = filter(m->m.lastreviewed + Day(m.interval) < today(), deck.memories)
	numtoreview = min(10, length(toreview))
	if numtoreview > 0
		println("Reviewing $numtoreview cards")
		for mem in toreview[1:numtoreview]
			review!(mem)
		end
		deck.lastreviewed = now()
	else
		println("You're up-to-date on this deck. Check back later?")
	end	
end

function review!(mem::Memory)
	card = rand(mem.cards)
	grade = quiz(card)
	update!(mem, grade)
end


function quiz(card::TextCard)
	println(card.prompt)
	return checkanswer(card.answer)
end

function quiz(card::ClozeCard)
	sentence = card.sentence
	deletions = findall(r"{{[^}]*}}", sentence)
	deletion = rand(deletions)
	answer = sentence[deletion.start+2:deletion.stop-2]
	
	print(replace(sentence[1:deletion.start-1], "{{"=>"", "}}"=>""))
	printstyled("[...]", bold=true)
	println(replace(sentence[deletion.stop+1:end], "{{"=>"", "}}"=>""))
	
	return checkanswer(answer)
end

function quiz(card::FormulaCard)
	vals = map(rand, card.variables)
	println(replace(card.prompt, ("{{" * string(k) * "}}" => v for (k, v) in pairs(vals))...))
	func::Function = eval(Expr(:->, Expr(:parameters, keys(card.variables)...), card.formula))
	answer = Base.invokelatest(func; vals...) # TODO: replace with something more elegant
	return checkanswer(answer)
end

# TODO: print full sentence for cloze
function checkanswer(answer)
	response = strip(readline())
	if !(answer isa Number)
		answer = something(tryparse(Int, answer), tryparse(Float64, answer), answer)
	end
	
	if isempty(response)
		print("The correct answer was ")
		printstyled(answer, bold=true)
		println(".")
		print("Score (0-5) [0]: ")
		score = something(tryparse(Int, readline()), 0)
	elseif compare(response, answer) == 1
		printstyled("Correct!\n", color=:green, bold=true)
		print("Score (0-5) [5]: ")
		score = something(tryparse(Int, readline()), 5)
	elseif compare(response, answer) ≥ 0.8
		printstyled("Correct!", color=:green, bold=true)
		print(" (")
		printstyled(answer, bold=true)
		println(")")
		print("Score (0-5) [4]: ")
		score = something(tryparse(Int, readline()), 4)
	else
		print("Nope, the correct answer was ")
		printstyled(answer, bold=true)
		println(".")
		print("Score (0-5) [1]: ")
		score = something(tryparse(Int, readline()), 1)
	end
	return clamp(score, 0, 5)
end


# Helper functions
# TODO: indicate if answer was close but slightly off
function compare(response, answer::String)
	response = normalize(response; casefold=true, stripmark=true)
	answer = normalize(answer; casefold=true, stripmark=true)
	# return OptimalStringAlignment()(response, answer)# ≤ 1
	return StringDistances.compare(response, answer, OptimalStringAlignment())
end

function compare(response, answer::Int)
	return tryparse(Int, response) == answer
end

# TODO: handle fractions?
function compare(response, answer::T) where T <: Number
	return isapprox(parse(T, response), answer, rtol=0.001)
end

#=
gwt = TextCard("Who was the first US President?", "George Washington")
canc = ClozeCard("{{Canberra}} was founded in {{1913}}.")
pit = TextCard("What is pi?", string(float(π)))
areac = ClozeCard("The area of a circle with radius {{2}} is {{$(float(4π))}}")
circf = FormulaCard("What is the circumference of a circle with radius {{r}}?", (r=1:10,), :(2π*r))
compf = FormulaCard("What is ({{a}} + {{b}}i) * ({{c}} + {{d}}i)?", (a=-5:5, b=-5:5, c=-5:5, d=-5:5), :((a+b*im)*(c+d*im)))

pim = Memory([pit, areac, circf])
=#

include("serialize.jl")
include("safe_eval.jl")
include("cli.jl")
# to_toml("cards.toml", [gwt, pit])
end