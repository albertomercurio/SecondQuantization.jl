module SecondQuantization

using SymbolicUtils
using SymbolicUtils: Sym, Symbolic, Mul, Term, Add, @ordered_acrule
using SymbolicUtils: isliteral, is_literal_number, needs_sorting, 
hasrepeats, merge_repeats, sort_args, has_trig_exp, _name_type
using Symbolics
using TermInterface
using Latexify
import Base: +, -, *, /, ^

export simplify, expand

hilbert_space_iterator = 0
include("qoperators.jl")

include("normal_ordering.jl")

include("simplify_rules.jl")
export default_simplifier, serial_simplifier, threaded_simplifier, serial_expand_simplifier

include("latexify_recipes.jl")

export @boson

end
