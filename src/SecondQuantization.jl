module SecondQuantization

using SymbolicUtils
using SymbolicUtils: Sym, Symbolic, Term, Add, Mul, Div, Pow, @ordered_acrule
using SymbolicUtils: isliteral, is_literal_number, needs_sorting, 
hasrepeats, merge_repeats, sort_args, has_trig_exp, _name_type, sym_isa
using Symbolics
using TermInterface
using Latexify
import Base: +, -, *, /, ^

# SymbolicUtils tools
export simplify, arguments, operation

hilbert_space_iterator = 0
include("qoperators.jl")
export @boson, @parameter, commutator

include("normal_ordering.jl")
export normal_order

include("simplify_rules.jl")
export default_simplifier, serial_simplifier, threaded_simplifier, serial_expand_simplifier
export normal_order_simplifier, serial_normal_order_simplifier, threaded_normal_order_simplifier

include("latexify_recipes.jl")

end
