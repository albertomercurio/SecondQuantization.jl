function normal_order(x; rewriter = serial_normal_order_simplifier)
    !istree(x) && return x
    return simplify(x, rewriter = rewriter)
end

function isterm_op(f)
    function (x)
        if istree(x)
            if typeof(x) <: Term{QOperator}
                return f == operation(x)
            end
        end
        return false
    end
end

needs_hilbert_order_sorting(f) = x -> isterm_op(f)(x) && !issorted(arguments(x), lt = <ₑ)

function sort_hilbert_args(f, t)
    args = arguments(t)
    if length(args) < 2
        return similarterm(t, f, args)
    elseif length(args) == 2
        x, y = args
        return similarterm(t, f, x <ₑ y ? [x,y] : [y,x])
    end
    args = args isa Tuple ? [args...] : args
    similarterm(t, f, sort(args, lt=<ₑ))
end

# For normal order simplification only
function is_boson_destroy(x)
    !(symtype(x) <: QOperator) && return false
    istree(x) && return false
    metadt = getmetadata(x, QOperatorMeta)
    (metadt.type == BosonicDestroy()) && return true
    return false
end

function is_boson_create(x)
    !(symtype(x) <: QOperator) && return false
    istree(x) && return false
    metadt = getmetadata(x, QOperatorMeta)
    (metadt.type == BosonicCreate()) && return true
    return false
end

<ₑ(a::Real,    b::Real) = abs(a) < abs(b)
<ₑ(a::Complex, b::Complex) = (abs(real(a)), abs(imag(a))) < (abs(real(b)), abs(imag(b)))
<ₑ(a::Real,    b::Complex) = true
<ₑ(a::Complex, b::Real) = false

<ₑ(a::Symbolic, b::Number) = false
<ₑ(a::Number,   b::Symbolic) = true
<ₑ(a::Sym{Number},   b::Sym{Number}) = a.name < b.name
<ₑ(a::Sym{Number},   b::Sym{QOperator}) = true
<ₑ(a::Sym{QOperator},   b::Sym{Number}) = false
<ₑ(a::Sym{QOperator}, b::Sym{QOperator}) = getmetadata(a, QOperatorMeta).h_idx < getmetadata(b, QOperatorMeta).h_idx

arglength(a) = length(arguments(a))
function <ₑ(a, b)
    # isequal(a, b) && return false
    if istree(a) && (b isa Symbolic && !istree(b))
        if symtype(b) != QOperator
            return false
        else
            if symtype(a) != QOperator
                return true
            elseif _isthere_h_idx(a, b)
                return false ## Needs to return false, following that for any real number r < r = false
            else
                return getmetadata(b, QOperatorMeta).h_idx > _min_h_idx(a)
            end
        end
    elseif istree(b) && (a isa Symbolic && !istree(a))
        if symtype(a) != QOperator
            return true
        else
            if symtype(b) != QOperator
                return false
            elseif _isthere_h_idx(b, a)
                return true
            else
                return getmetadata(a, QOperatorMeta).h_idx < _min_h_idx(b)
            end
        end
    elseif istree(a) && istree(b)
        if symtype(b) != QOperator
            if symtype(a) != QOperator
                return cmp_term_term(a,b)
            else
                return false
            end
        else
            return false ## Needs to return false, following that for any real number r < r = false
        end
    else
        return a <ₑ b
    end
end

function <ₑ(a::Symbol, b::Symbol)
    # Enforce the order [+,-,\,/,^,*]
    if b === :*
        a in (:^, :/, :\, :-, :+)
    elseif b === :^
        a in (:/, :\, :-, :+) && return true
    elseif b === :/
        a in (:\, :-, :+) && return true
    elseif b === :\
        a in (:-, :+) && return true
    elseif b === :-
        a === :+ && return true
    elseif a in (:*, :^, :/, :-, :+)
        false
    else
        a < b
    end
end

<ₑ(a::Function, b::Function) = nameof(a) <ₑ nameof(b)

<ₑ(a::Type, b::Type) = nameof(a) <ₑ nameof(b)

function cmp_term_term(a, b)
    la = arglength(a)
    lb = arglength(b)

    if la == 0 && lb == 0
        return operation(a) <ₑ operation(b)
    elseif la === 0
        return operation(a) <ₑ b
    elseif lb === 0
        return a <ₑ operation(b)
    end

    na = operation(a)
    nb = operation(b)

    if 0 < arglength(a) <= 2 && 0 < arglength(b) <= 2
        # e.g. a < sin(a) < b ^ 2 < b
        @goto compare_args
    end

    if na !== nb
        return na <ₑ nb
    elseif arglength(a) != arglength(b)
        return arglength(a) < arglength(b)
    else
        @label compare_args
        aa, ab = arguments(a), arguments(b)
        if length(aa) !== length(ab)
            return length(aa) < length(ab)
        else
            terms = zip(Iterators.filter(!is_literal_number, aa), Iterators.filter(!is_literal_number, ab))

            for (x,y) in terms
                if x <ₑ y
                    return true
                elseif y <ₑ x
                    return false
                end
            end

            # compare the numbers
            nums = zip(Iterators.filter(is_literal_number, aa),
                       Iterators.filter(is_literal_number, ab))

            for (x,y) in nums
                if x <ₑ y
                    return true
                elseif y <ₑ x
                    return false
                end
            end

        end
        return na <ₑ nb # all args are equal, compare the name
    end
end

function flatten_term(⋆, x)
    args = arguments(x)
    # flatten nested ⋆
    flattened_args = []
    for t in args
        if istree(t) && operation(t) === (⋆)
            if isnotflat(⋆)(t)
                append!(flattened_args, arguments(flatten_term(⋆, t)))
            else
                append!(flattened_args, arguments(t))
            end
        else
            push!(flattened_args, t)
        end
    end
    similarterm(x, ⋆, flattened_args)
end

function isnotflat(⋆)
    function (x)
        if istree(x)
            if operation(x) === (⋆)
                args = arguments(x)
                for t in args
                    if istree(t) && operation(t) === (⋆)
                        return true
                    end
                end
            end
        end
        return false
    end
end

function _isthere_h_idx(my_term, my_op)
    metadt = getmetadata(my_op, QOperatorMeta)
    h_ind = metadt.h_idx
    op_type = metadt.type
    if symtype(my_term) != QOperator
        return false
    else
        if !istree(my_term)
            return getmetadata(my_term, QOperatorMeta).h_idx == h_ind && getmetadata(my_term, QOperatorMeta).type == op_type
        else
            args = arguments(my_term)
            for arg in args
                _isthere_h_idx(arg, my_op) && return true
            end
        end
    end
    return false
end

function _min_h_idx(my_term::Term{QOperator})
    idxs = _list_h_idxs(my_term)
    return minimum(idxs)
end

function _list_h_idxs(my_term::Term{QOperator})
    args = arguments(my_term)
    idxs = []
    for arg in args
        if istree(arg)
            h_idxs = _list_h_idxs(arg)
        else
            if symtype(arg) == QOperator
                h_idxs = [getmetadata(arg, QOperatorMeta).h_idx]
            else
                h_idxs = []
            end
        end
        for h_idx in h_idxs
            if !(h_idx in idxs)
                push!(idxs, h_idx)
            end
        end
    end
    return sort(idxs)
end