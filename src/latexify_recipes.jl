@latexrecipe function f(op::Symbolic{QOperator})
    expr = Expr(:latexifymerge)
    expr.args = _to_expression(op)
    return expr
end

@latexrecipe function f(my_term::Term{QOperator})
    my_expr = Expr(:latexifymerge)
    my_expr.args = _to_expression(my_term)
    return my_expr
end

_to_expression(x::Number) = x

function _to_expression(op::Symbolic{QOperator})
    op_type = op.metadata.type
    if op_type == BosonicCreate()
        return ["\\hat{", String(op.name)[1:end-2], "}^\\dagger"]
    elseif op_type == PauliSM()
        return ["\\hat{", op.name, "}_{-}"]
    elseif op_type == PauliSP()
        return ["\\hat{", String(op.name)[1:end-2], "}_{+}"]
    else
        return ["\\hat{", op.name, "}"]
    end
end

function _to_expression(my_term::Term{QOperator})
    args = SymbolicUtils.arguments(my_term)
    my_args = []
    my_f = my_term.f
    if my_f == (*)
        for op in args
            if isterm_op(+)(op) || isterm_op(-)(op)
                append!(my_args, "\\left(")
                append!(my_args, _to_expression(op))
                append!(my_args, "\\right)")
            else
                append!(my_args, _to_expression(op))
            end
        end
    elseif my_f == (/) && length(args) == 2
        append!(my_args, "\\frac{")
        append!(my_args, _to_expression(args[1]))
        append!(my_args, "}{")
        append!(my_args, _to_expression(args[2]))
        append!(my_args, "}")
    elseif my_f == (^) && length(args) == 2
        append!(my_args, "{")
        append!(my_args, _to_expression(args[1]))
        append!(my_args, "}^{")
        append!(my_args, _to_expression(args[2]))
        append!(my_args, "}")
    elseif my_f == (+)
        append!(my_args, _to_expression(args[1]))
        for op in args[2:end]
            append!(my_args, "+")
            append!(my_args, _to_expression(op))
        end
    elseif my_f == (-)
        append!(my_args, _to_expression(args[1]))
        for op in args[2:end]
            append!(my_args, "-")
            append!(my_args, _to_expression(op))
        end
    elseif my_f == (sin)
        append!(my_args, "\\sin \\left(")
        append!(my_args, _to_expression(args[1]))
        append!(my_args, "\\right)")
    elseif my_f == (cos)
        append!(my_args, "\\cos \\left(")
        append!(my_args, _to_expression(args[1]))
        append!(my_args, "\\right)")
    elseif my_f == (exp)
        append!(my_args, "e^{")
        append!(my_args, _to_expression(args[1]))
        append!(my_args, "}")
    end

    return my_args
end