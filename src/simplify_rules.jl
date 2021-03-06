using SymbolicUtils.Rewriters

_iszero(x) = x isa Number && iszero(x)
_isone(x) = x isa Number && isone(x)
_isinteger(x) = (x isa Number && isinteger(x)) || (x isa Symbolic && symtype(x) <: Integer)
_isreal(x) = (x isa Number && isreal(x)) || (x isa Symbolic && symtype(x) <: Real)

begin
    PLUS_RULES = [
        @rule(~x::isnotflat(+) => flatten_term(+, ~x))
        @rule(~x::needs_sum_ordering => order_sum(~x))
        @ordered_acrule(~a::is_literal_number + ~b::is_literal_number => ~a + ~b)
        @rule(+(~~x::hasrepeats_qterms) => +(merge_sum_common_factors(~~x)...))
        @acrule((~z::_iszero + ~x) => ~x)
        @rule(+(~x) => ~x)
        @acrule( ~x - +(~~a, ~x, ~~b) => -(0, (~~a)..., (~~b)...) )
        @acrule( +(~~a, ~x, ~~b) + -1*~x => +(0, (~~a)..., (~~b)...) )
        @acrule( ~x + -1 * ~x => zero(symtype(~x)) )
        @acrule( *(~~x) + *(-1, ~~x) => 0 )
        @rule(+(~~a, *(~~x), ~~b, *(-1, ~~x), ~~c) => +((~~a)..., (~~b)..., (~~c)...))
    ]

    TIMES_RULES = [
        @rule(~x::isnotflat(*) => flatten_term(*, ~x))
        @rule(~x::needs_hilbert_order_sorting(*) => sort_hilbert_args(*, ~x)) ## beacuse they may not commute
        @rule(*(~~x::hasrepeats) => *(merge_repeats(^, ~~x)...))
        @rule( *(~~a, ~y, (~y)^(~n::is_literal_number), ~~b) => *((~~a)..., (~y)^(~n+1), (~~b)...) )
        @rule( *(~~a, (~y)^(~n::is_literal_number), ~y, ~~b) => *((~~a)..., (~y)^(~n+1), (~~b)...) )
        @rule( *(~~a, (~y)^(~n::is_literal_number), (~y)^(~m::is_literal_number), ~~b) => *((~~a)..., (~y)^(~n+~m), (~~b)...) )
        @ordered_acrule((~z::_isone  * ~x) => ~x)
        @ordered_acrule((~z::_iszero *  ~x) => ~z)
        @rule(*(~x) => ~x)
        @rule( *(~~x, +(~α, ~β), ~~y) => *((~~x)..., ~α, (~~y)...) + *((~~x)..., ~β, (~~y)...) )

        @rule( *(~α, +(~~y)) => +([~α * ζ for ζ in (~~y)]...) )
        @rule( *(+(~~x), ~α, +(~~y)) => +([ξ * ~α * ζ for ξ in (~~x) for ζ in (~~y)]...) )

        @rule( *(~~a, ~x::sym_isa(Number), ~~b) / ~y::sym_isa(Number) => *((~~a)..., ~x / ~y, (~~b)...) )
        @rule( *(~~a, ^(~x::istree, ~n::is_literal_number), ~~b) => *((~~a)..., [~x for i in 1:~n]..., (~~b)...) )

        @rule( *(~~a, ~x::is_boson_destroy, ~y::is_boson_create, ~~b) => *((~~a)..., swap_boson(~x, ~y), (~~b)...) )
        @rule( *(~~a, ~x::is_boson_destroy, (~y::is_boson_create)^(~n::is_literal_number), ~~b) => *((~~a)..., swap_boson(~x, ~y), (~y)^(~n - 1), (~~b)...) )
        @rule( *(~~a, (~x::is_boson_destroy)^(~n::is_literal_number), ~y::is_boson_create, ~~b) => *((~~a)..., (~x)^(~n - 1), swap_boson(~x, ~y), (~~b)...) )
        @rule( *(~~a, (~x::is_boson_destroy)^(~n::is_literal_number), (~y::is_boson_create)^(~m::is_literal_number), ~~b) => *((~~a)..., (~x)^(~n - 1), swap_boson(~x, ~y), (~y)^(~m - 1), (~~b)...) )
    ]


    POW_RULES = [
        @rule( ^(~x::istree, ~n::is_literal_number) => *([~x for i in 1:~n]...) )
        @rule( (((~x)^(~p::_isinteger))^(~q::_isinteger)) => (~x)^((~p)*(~q)) )
        @rule(^(~x, ~z::_iszero) => 1)
        @rule(^(~x, ~z::_isone) => ~x)
        @rule(inv(~x) => 1/(~x))
    ]

    ASSORTED_RULES = [
        @rule(identity(~x) => ~x)
        @rule(-(~x) => -1*~x)
        @rule(-(~x, ~y) => ~x + -1(~y))
        @rule(~x::_isone \ ~y => ~y)
        @rule(~x::_iszero \ ~y => zero(symtype(~y)))
        @rule(~x \ ~y => ~y / (~x))
        @rule(~x / ~x => one(symtype(~x)))
        @rule(~x / 1 => ~x)
        @rule(one(~x) => one(symtype(~x)))
        @rule(zero(~x) => zero(symtype(~x)))
        @rule(conj(~x::_isreal) => ~x)
        @rule(real(~x::_isreal) => ~x)
        @rule(imag(~x::_isreal) => zero(symtype(~x)))
        @rule(ifelse(~x::is_literal_number, ~y, ~z) => ~x ? ~y : ~z)
    ]

    TRIG_EXP_RULES = [
        # @acrule(~r*~x::has_trig_exp + ~r*~y => ~r*(~x + ~y))
        # @acrule(~r*~x::has_trig_exp + -1*~r*~y => ~r*(~x - ~y))
        @acrule(sin(~x)^2 + cos(~x)^2 => one(~x))
        @acrule(sin(~x)^2 + -1        => -1*cos(~x)^2)
        @acrule(cos(~x)^2 + -1        => -1*sin(~x)^2)

        @acrule(cos(~x)^2 + -1*sin(~x)^2 => cos(2 * ~x))
        @acrule(sin(~x)^2 + -1*cos(~x)^2 => -cos(2 * ~x))
        @acrule(cos(~x) * sin(~x) => sin(2 * ~x)/2)

        @acrule(tan(~x)^2 + -1*sec(~x)^2 => one(~x))
        @acrule(-1*tan(~x)^2 + sec(~x)^2 => one(~x))
        @acrule(tan(~x)^2 +  1 => sec(~x)^2)
        @acrule(sec(~x)^2 + -1 => tan(~x)^2)

        @acrule(cot(~x)^2 + -1*csc(~x)^2 => one(~x))
        @acrule(cot(~x)^2 +  1 => csc(~x)^2)
        @acrule(csc(~x)^2 + -1 => cot(~x)^2)

        # @acrule(exp(~x) * exp(~y) => _iszero(~x + ~y) ? 1 : exp(~x + ~y))
        # @rule(exp(~x)^(~y) => exp(~x * ~y))
    ]

    BOOLEAN_RULES = [
        @rule((true | (~x)) => true)
        @rule(((~x) | true) => true)
        @rule((false | (~x)) => ~x)
        @rule(((~x) | false) => ~x)
        @rule((true & (~x)) => ~x)
        @rule(((~x) & true) => ~x)
        @rule((false & (~x)) => false)
        @rule(((~x) & false) => false)

        @rule(!(~x) & ~x => false)
        @rule(~x & !(~x) => false)
        @rule(!(~x) | ~x => true)
        @rule(~x | !(~x) => true)
        @rule(xor(~x, !(~x)) => true)
        @rule(xor(~x, ~x) => false)

        @rule(~x == ~x => true)
        @rule(~x != ~x => false)
        @rule(~x < ~x => false)
        @rule(~x > ~x => false)

        # simplify terms with no symbolic arguments
        # e.g. this simplifies term(isodd, 3, type=Bool)
        # or term(!, false)
        @rule((~f)(~x::is_literal_number) => (~f)(~x))
        # and this simplifies any binary comparison operator
        @rule((~f)(~x::is_literal_number, ~y::is_literal_number) => (~f)(~x, ~y))
    ]

    function quantum_normal_order_simplifier()
        rule_tree = [If(istree, Chain(ASSORTED_RULES)),
                     If(is_operation(+),
                        Chain(PLUS_RULES)),
                     If(is_operation(*),
                        Chain(TIMES_RULES)),
                     If(is_operation(^),
                        Chain(POW_RULES))] |> RestartedChain

        rule_tree
    end

    trig_exp_simplifier(;kw...) = Chain(TRIG_EXP_RULES);

    bool_simplifier() = Chain(BOOLEAN_RULES);

    global normal_order_simplifier
    global serial_normal_order_simplifier
    global threaded_normal_order_simplifier

    function normal_order_simplifier(; kw...)
        IfElse(has_trig_exp,
               Postwalk(IfElse(x->symtype(x) <: QOperator,
                               Chain((quantum_normal_order_simplifier(),
                                      trig_exp_simplifier())),
                               If(x->symtype(x) <: Bool,
                                  bool_simplifier()))
                        ; kw...),
               Postwalk(Chain((If(x->symtype(x) <: QOperator,
                                  quantum_normal_order_simplifier()),
                               If(x->symtype(x) <: Bool,
                                  bool_simplifier())))
                        ; kw...))
    end

    serial_normal_order_simplifier = If(istree, Fixpoint(normal_order_simplifier()))

    threaded_normal_order_simplifier(cutoff) = Fixpoint(normal_order_simplifier(threaded=true,
                                                              thread_cutoff=cutoff));
end