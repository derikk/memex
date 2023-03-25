import Configurations: to_dict, from_dict
import OrderedCollections: OrderedDict

to_dict(::Type, x::Expr) = string(x)
from_dict(::Type, ::Type{Expr}, x) = Meta.parse(x)
to_dict(::Type, v::VersionNumber) = string(v)

# to_dict(::Type, f::Float16) = round(f, digits=2)

# Configurations.from_dict(::Type, ::Type{Symbol}, x) = Symbol(x)
to_dict(::Type{FormulaCard}, t::NamedTuple) = OrderedDict(v=>OrderedDict("min"=>r.start, "max"=>r.stop) for (v,r) in pairs(t))
# Configurations.to_dict(::Type, r::UnitRange{Int64}) = OrderedDict("min"=>r.start, "max"=>r.stop) # doesn't work

# Configurations.from_dict(::Type, ::Type{UnitRange}, r) = r["min"]:r["max"]
from_dict(::Type{FormulaCard}, ::Type{NamedTuple}, t) = NamedTuple(OrderedDict(Symbol(v)=>r["min"]:r["max"] for (v,r) in t))