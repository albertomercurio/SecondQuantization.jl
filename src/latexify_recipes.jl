Base.show(io::IO, ::MIME"text/latex", x::Symbolic) = print(io, latexify(x))

@latexrecipe function f(op::Symbolic{Number})
    expr = Expr(:latexifymerge, op.name)
    return expr
end

@latexrecipe function f(op::Add{Number})
    expr = Expr(:latexifymerge)
    expr.args = _to_expression(op)
    return expr
end

@latexrecipe function f(op::Mul{Number})
    expr = Expr(:latexifymerge)
    expr.args = _to_expression(op)
    return expr
end

@latexrecipe function f(op::Div{Number})
    expr = Expr(:latexifymerge)
    expr.args = _to_expression(op)
    return expr
end

@latexrecipe function f(op::Pow{Number})
    expr = Expr(:latexifymerge)
    expr.args = _to_expression(op)
    return expr
end

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
_to_expression(op::Symbolic{Number}) = String(op.name)

function _to_expression(op::Symbolic{QOperator})
    metadt = getmetadata(op, QOperatorMeta)
    op_type = metadt.type
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
    args = arguments(my_term)
    my_args = []
    my_f = operation(my_term)
    if my_f == (*)
        for op in args
            if isterm_op(+)(op) || isterm_op(-)(op)
                append!(my_args, "\\left(")
                append!(my_args, _to_expression(op))
                append!(my_args, "\\right)")
            else
                if !isequal(op, 1)
                    if isequal(op, -1)
                        append!(my_args, "-")
                    else
                        append!(my_args, _to_expression(op))
                    end
                end
            end
        end
    elseif my_f == (/) && length(args) == 2
        if istree(args[1])
            append!(my_args, ["\\frac{1}{", args[2], "}"])
            append!(my_args, "\\left(")
            append!(my_args, _to_expression(args[1]))
            append!(my_args, "\\right)")
        else
            append!(my_args, "\\frac{")
            append!(my_args, _to_expression(args[1]))
            append!(my_args, "}{")
            append!(my_args, _to_expression(args[2]))
            append!(my_args, "}")
        end
    elseif my_f == (^) && length(args) == 2
        if istree(args[1])
            append!(my_args, "\\left(")
            append!(my_args, _to_expression(args[1]))
            append!(my_args, "\\right)^{")
            append!(my_args, _to_expression(args[2]))
            append!(my_args, "}")
        else
            append!(my_args, "{")
            append!(my_args, _to_expression(args[1]))
            append!(my_args, "}^{")
            append!(my_args, _to_expression(args[2]))
            append!(my_args, "}")
        end
    elseif my_f == (+)
        append!(my_args, _to_expression(args[1]))
        for op in args[2:end]
            if istree(op)
                if isterm_op(*)(op)
                    if isequal(arguments(op)[1],-1)
                        append!(my_args, "-")
                        append!(my_args, _to_expression(*(arguments(op)[2:end]...)))
                    else
                        append!(my_args, "+")
                        append!(my_args, _to_expression(op))
                    end
                else
                    append!(my_args, "+")
                    append!(my_args, _to_expression(op))
                end
            else
                if isequal(op, -1)
                    append!(my_args, "-1")
                else
                    append!(my_args, "+")
                    append!(my_args, _to_expression(op))
                end
            end
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

function _to_expression(my_term::Add{Number})
    args = SymbolicUtils.arguments(my_term)
    my_args = []
    append!(my_args, _to_expression(args[1]))
    for op in args[2:end]
        if isterm_op(*)(op)
            if arguments(op)[1] == -1
                append!(my_args, "-")
                append!(my_args, _to_expression(*(arguments(op)[2:end]...)))
            else
                append!(my_args, "+")
                append!(my_args, _to_expression(op))
            end
        else
            append!(my_args, "+")
            append!(my_args, _to_expression(op))
        end
    end
    return my_args
end

function _to_expression(my_term::Mul{Number})
    args = SymbolicUtils.arguments(my_term)
    my_args = []
    for op in args
        if isterm_op(+)(op) || isterm_op(-)(op)
            append!(my_args, "\\left(")
            append!(my_args, _to_expression(op))
            append!(my_args, "\\right)")
        else
            append!(my_args, _to_expression(op))
        end
    end
    return my_args
end

function _to_expression(my_term::Div{Number})
    args = SymbolicUtils.arguments(my_term)
    my_args = []
    if length(args) == 2
        append!(my_args, ["\\frac{", args[1], "}{", args[2], "}"])
    end
    return my_args
end

function _to_expression(my_term::Pow{Number})
    args = SymbolicUtils.arguments(my_term)
    my_args = []
    if istree(args[1])
        append!(my_args, "\\left(")
        append!(my_args, _to_expression(args[1]))
        append!(my_args, "\\right)^{")
        append!(my_args, _to_expression(args[2]))
        append!(my_args, "}")
    else
        append!(my_args, "{")
        append!(my_args, _to_expression(args[1]))
        append!(my_args, "}^{")
        append!(my_args, _to_expression(args[2]))
        append!(my_args, "}")
    end
    return my_args
end

# function _to_expression(op::Symbolic{QOperator})
#     if !istree(op)
#         metadt = getmetadata(op, QOperatorMeta)
#         op_type = metadt.type
#         if op_type == BosonicCreate()
#             return ["\\hat{", String(op.name)[1:end-2], "}^\\dagger"]
#         elseif op_type == PauliSM()
#             return ["\\hat{", op.name, "}_{-}"]
#         elseif op_type == PauliSP()
#             return ["\\hat{", String(op.name)[1:end-2], "}_{+}"]
#         else
#             return ["\\hat{", op.name, "}"]
#         end
#     else
#         args = arguments(op)
#         my_args = []
#         if ismul(op)
#             for op_tmp in args
#                 if isadd(op_tmp)
#                     append!(my_args, "\\left(")
#                     append!(my_args, _to_expression(op_tmp))
#                     append!(my_args, "\\right)")
#                 else
#                     append!(my_args, _to_expression(op_tmp))
#                 end
#             end
#         elseif isdiv(op)
#             if istree(args[1])
#                 append!(my_args, ["\\frac{1}{", args[2], "}"])
#                 append!(my_args, "\\left(")
#                 append!(my_args, _to_expression(args[1]))
#                 append!(my_args, "\\right)")
#             else
#                 append!(my_args, "\\frac{")
#                 append!(my_args, _to_expression(args[1]))
#                 append!(my_args, "}{")
#                 append!(my_args, _to_expression(args[2]))
#                 append!(my_args, "}")
#             end
#         elseif ispow(op)
#             if istree(args[1])
#                 append!(my_args, "\\left(")
#                 append!(my_args, _to_expression(args[1]))
#                 append!(my_args, "\\right)^{")
#                 append!(my_args, _to_expression(args[2]))
#                 append!(my_args, "}")
#             else
#                 append!(my_args, "{")
#                 append!(my_args, _to_expression(args[1]))
#                 append!(my_args, "}^{")
#                 append!(my_args, _to_expression(args[2]))
#                 append!(my_args, "}")
#             end
#         elseif isadd(op)
#             append!(my_args, _to_expression(args[1]))
#             for op_tmp in args[2:end]
#                 if istree(op_tmp)
#                     if ismul(op_tmp)
#                         if arguments(op_tmp)[1] == -1
#                             append!(my_args, "-")
#                             append!(my_args, _to_expression(*(arguments(op_tmp)[2:end]...)))
#                         else
#                             append!(my_args, "+")
#                             append!(my_args, _to_expression(op_tmp))
#                         end
#                     else
#                         append!(my_args, "+")
#                         append!(my_args, _to_expression(op_tmp))
#                     end
#                 else
#                     if op_tmp == -1
#                         append!(my_args, "-1")
#                     else
#                         append!(my_args, "+")
#                         append!(my_args, _to_expression(op_tmp))
#                     end
#                 end
#             end
#         end
#         return my_args
#     end
# end