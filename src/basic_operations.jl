Base.one(::T) where T<:QOperator = one(T)
Base.one(::Type{<:QOperator}) = 1
Base.zero(::T) where T<:QOperator = zero(T)
Base.zero(::Type{<:QOperator}) = 0
Base.isone(::QOperator) = false
Base.iszero(::QOperator) = false

function *(x::Symbolic{QOperator}, y::Symbolic{QOperator})
    args = []
    if istree(x)
        if istree(y)
            if isterm_op(*)(x)
                if isterm_op(*)(y)
                    num_args_x, num_args_y = num_arguments(x), num_arguments(y)
                    if length(num_args_x) > 0 || length(num_args_y) > 0
                        append!(args, [*(vcat(num_args_x, num_args_y)...)])
                    end
                    symnum_args_x, symnum_args_y = symnum_arguments(x), symnum_arguments(y)
                    if length(symnum_args_x) > 0 || length(num_args_y) > 0
                        append!(args, [*(vcat(symnum_args_x, symnum_args_y)...)])
                    end
                    qop_args_x = qop_arguments(x)
                    qop_args_y = qop_arguments(y)
                    qop_args = merge_repeats(^, vcat(qop_args_x, qop_args_y))
                    append!(args, qop_args)
                elseif isterm_op(+)(y)
                    # append!(args, [x, y])
                    append!(args, vcat(arguments(x), [y]))
                elseif isterm_op(/)(y)
                    args_y = arguments(y)
                    append!(args, [x * args_y[1]])
                    append!(args, [args_y[2]])
                    return Term(/, args)
                elseif isterm_op(^)(y)
                    append!(args, vcat(arguments(x), [y]))
                else
                    append!(args, [x, y]) # TODO
                end
            elseif isterm_op(+)(x)
                if isterm_op(*)(y)
                    # append!(args, [x, y])
                    append!(args, vcat([x], arguments(y)))
                elseif isterm_op(+)(y)
                    # args_x, args_y = arguments(x), arguments(y)
                    # for arg_x in args_x
                    #     for arg_y in args_y
                    #         append!(args, [arg_x * arg_y])
                    #     end
                    # end
                    # return Term(+, args)
                    append!(args, [x, y])
                elseif isterm_op(/)(y)
                    # args_x = arguments(x)
                    # append!(args, [arg_x * y for arg_x in args_x])
                    # return Term(+, args)
                    append!(args, [x, y])
                else
                    append!(args, [x, y]) # TODO (MAYBE)
                end
            else
                append!(args, [x, y]) # TODO (MAYBE)
            end
        else
            if isterm_op(*)(x)
                append!(args, merge_repeats(^, vcat(arguments(x), y)))
            elseif isterm_op(+)(x)
                # args_x = arguments(x)
                # append!(args, [arg_x * y for arg_x in args_x])
                # return Term(+, args)
                append!(args, [x, y])
            elseif isterm_op(/)(x)
                args_x = arguments(x)
                append!(args, [args_x[1] * y, args_x[2]])
                return Term(/, args)
            elseif isterm_op(^)(x)
                args_x = arguments(x)
                if isequal(args_x[1], y)
                    append!(args, [y, args_x[2] + 1])
                    return Term(^, args)
                else
                    append!(args, [x, y])
                end
            else
                append!(args, [x, y]) # TODO
            end
        end
    elseif istree(y)
        if isterm_op(*)(y)
            append!(args, merge_repeats(^, vcat(x, arguments(y))))
        elseif isterm_op(+)(y)
            # args_y = arguments(y)
            # append!(args, [x * arg_y for arg_y in args_y])
            # return Term(+, args)
            append!(args, [x, y])
        elseif isterm_op(/)(y)
            args_y = arguments(y)
            append!(args, [x * args_y[1], args_y[2]])
            return Term(/, args)
        elseif isterm_op(^)(y)
            args_y = arguments(y)
            if isequal(x, args_y[1])
                append!(args, [x, args_y[2] + 1])
                return Term(^, args)
            else
                append!(args, [x, y])
            end
        else
            append!(args, [x, y]) # TODO
        end
    else
        if isequal(x, y)
            append!(args, [x, 2])
            return Term(^, args)
        else
            append!(args, [x, y])
        end
    end

    if length(args) == 1
        return args[1]
    end
    return Term(*, args)
end

function *(x::Symbolic{Number}, y::Symbolic{QOperator})
    args = []
    if istree(y)
        if isterm_op(*)(y)
            append!(args, num_arguments(y))
            append!(args, [*(vcat(x, symnum_arguments(y))...)])
            append!(args, qop_arguments(y))
        elseif isterm_op(+)(y)
            y_args = arguments(y)
            append!(args, [x * y_arg for y_arg in y_args])
            return Term(+, args)
        elseif isterm_op(/)(y)
            y_args = arguments(y)
            append!(args, [x * y_args[1]])
            append!(args, [y_args[2]])
            return Term(/, args)
        else
            append!(args, [x, y])
        end
    else
        append!(args, [x, y])
    end

    if length(args) == 1
        return args[1]
    end
    return Term(*, args)
end

function *(x::Number, y::Symbolic{QOperator})
    args = []
    
    if istree(y)
        if isterm_op(*)(y)
            append!(args, [*(vcat(x, num_arguments(y))...)])
            append!(args, symnum_arguments(y))
            append!(args, qop_arguments(y))
        elseif isterm_op(+)(y)
            y_args = arguments(y)
            append!(args, [x * y_arg for y_arg in y_args])
            return Term(+, args)
        elseif isterm_op(/)(y)
            y_args = arguments(y)
            append!(args, [x * y_args[1]])
            append!(args, [y_args[2]])
            return Term(/, args)
        else
            append!(args, [x, y])
        end
    else
        append!(args, [x, y])
    end

    if length(args) == 1
        return args[1]
    end
    return Term(*, args)
end

*(x::Symbolic{QOperator}, y::Symbolic{Number}) = y * x
*(x::Symbolic{QOperator}, y::Number) = y * x
*(x::Symbolic{QOperator}) = x
*(x::Term{QOperator}) = x

function +(x::Symbolic{QOperator}, y::Symbolic{QOperator})
    args = []
    if isterm_op(+)(x)
        if isterm_op(+)(y)
            args_x, args_y = arguments(x), arguments(y)
            args_unified = vcat(args_x, args_y)
            if needs_sum_ordering(+(args_unified...))
                args_unified = arguments(sort_args(+, +(args_unified...)))
            end
            # append!(args, merge_repeats(*, args_unified))
            append!(args, merge_sum_common_factors(args_unified))
        else
            # append!(args, merge_repeats(*, vcat(arguments(x), y)))
            append!(args, merge_sum_common_factors(vcat(arguments(x), y)))
        end
    elseif isterm_op(+)(y)
        # append!(args, merge_repeats(*, vcat(x, arguments(y))))
        append!(args, merge_sum_common_factors(vcat(x, arguments(y))))
    else
        # append!(args, merge_repeats(*, [x, y]))
        append!(args, merge_sum_common_factors([x, y]))
    end

    if length(args) == 1
        return args[1]
    end
    return Term(+, args)
end

function +(x::Symbolic{Number}, y::Symbolic{QOperator})
    args = []
    if isterm_op(+)(y)
        append!(args, merge_repeats(*, vcat(x, arguments(y))))
    else
        append!(args, [x, y])
    end

    if length(args) == 1
        return args[1]
    end
    return Term(+, args)
end

function +(x::Number, y::Symbolic{QOperator})
    args = []
    if isterm_op(+)(y)
        append!(args, merge_repeats(*, vcat(x, arguments(y))))
    else
        append!(args, [x, y])
    end

    if length(args) == 1
        return args[1]
    end
    return Term(+, args)
end

function +(x::Symbolic{QOperator}...)
    args = []
    append!(args, merge_sum_common_factors(x))

    if length(args) == 1
        return args[1]
    end
    return Term(+, args)
end

+(x::Symbolic{QOperator}, y::Symbolic{Number}) = y + x
+(x::Symbolic{QOperator}, y::Number) = y + x
+(x::Symbolic{QOperator}) = x
+(x::Term{QOperator}) = x

function -(x::Symbolic{QOperator}, y::Symbolic{QOperator})
    isequal(x, y) && return 0
    return x + (-1*y)
end

-(x::Symbolic{QOperator}, y::Symbolic{Number}) = (-1*y) + x
-(x::Symbolic{Number}, y::Symbolic{QOperator}) = (-1*x) + y
-(x::Symbolic{QOperator}, y::Number) = (-1*y) + x
-(x::Number, y::Symbolic{QOperator}) = (-1*x) + y
-(x::Symbolic{QOperator}) = -1 * x

function /(x::Symbolic{QOperator}, y::Symbolic{QOperator})
    isequal(x, y) && return 1
    return Term(/, [x, y])
end

/(x::Symbolic{QOperator}, y::Symbolic{Number}) = x * (1 // y)
/(x::Symbolic{Number}, y::Symbolic{QOperator}) = Term(/, [x, y])
/(x::Symbolic{QOperator}, y::Number) = x * (1 // y)
/(x::Number, y::Symbolic{QOperator}) = Term(/, [x, y])


function ^(x::Symbolic{QOperator}, n::Number)
    args = []
    if isterm_op(^)(x)
        x_args = arguments(x)
        append!(args, [x_args[1], x_args[2] * n])
    else
        append!(args, [x, n])
    end

    if length(args) == 1
        return args[1]
    end
    return Term(^, args)
end

# ^(x::Symbolic{QOperator}, n::Number) = Term(^, [x, n])
^(x::Symbolic{QOperator}, n::Symbolic{Number}) = Term(^, [x, n])
^(x::Symbolic{QOperator}, n::Symbolic{QOperator}) = Term(^, [x, n])

function Base.adjoint(op::Symbolic{QOperator})
    if istree(op)
        if isterm_op(*)(op)
            rev_adj_args = [adjoint(x) for x in reverse(arguments(op))]
            return *(rev_adj_args...)
        elseif isterm_op(+)(op)
            adj_args = [adjoint(x) for x in arguments(op)]
            return +(adj_args...)
        elseif isterm_op(^) && (arguments(op)[2] isa Number || arguments(op)[2] isa Symbolic{Number})
            args = arguments(op)
            return adjoint(args[1])^args[2]
        else
            return 123456
        end
    else
        metadt = getmetadata(op, QOperatorMeta)
        op_type = metadt.type
        h_idx = metadt.h_idx
        if op_type == BosonicDestroy()
            res = Sym{QOperator}(Symbol(String(op.name) * "_d"))
            res = setmetadata(res, QOperatorMeta, QOperatorMeta(BosonicCreate(), h_idx))
            return res
        elseif op_type == BosonicCreate()
            res = Sym{QOperator}(Symbol(String(op.name)[1:end-2]))
            res = setmetadata(res, QOperatorMeta, QOperatorMeta(BosonicDestroy(), h_idx))
            return res
        end
    end
end