function isterm_op(f)
    function (x)
        if istree(x)
            return f == operation(x)
            # if typeof(x) <: Term{QOperator}
            #     return f == operation(x)
            # end
        end
        return false
    end
end

function hasrepeats(x)
    length(x) <= 1 && return false
    for i=1:length(x)-1
        if isequal(x[i], x[i+1]) && !istree(x[i+1])
            return true
        end
    end
    return false
end

function merge_repeats(merge, xs)
    length(xs) <= 1 && return false
    merged = Any[]
    i=1

    while i<=length(xs)
        l = 1
        for j=i+1:length(xs)
            if isequal(xs[i], xs[j]) && !istree(xs[j])
                l += 1
            else
                break
            end
        end
        if l > 1
            push!(merged, merge(xs[i], l))
        else
            push!(merged, xs[i])
        end
        i+=l
    end
    return merged
end

function hasrepeats_qterms(x)
    length(x) <= 1 && return false
    for i = 1:length(x)-1
        j = i+1
        if istree(x[i]) && istree(x[j])
            if isterm_op(*)(x[i])
                if isterm_op(*)(x[j])
                    if isequal(qop_arguments(x[i]), qop_arguments(x[j]))
                        return true
                    end
                elseif isterm_op(^)(x[j])
                    if isequal(qop_arguments(x[i]), [x[j]])
                        return true
                    end
                else
                    if isequal(x[i], x[j])
                        return true
                    end
                end
            elseif isterm_op(^)(x[i])
                if isterm_op(*)(x[j])
                    if isequal([x[i]], qop_arguments(x[j]))
                        return true
                    end
                else
                    if isequal(x[i], x[j])
                        return true
                    end
                end
            else
                if isequal(x[i], x[j])
                    return true
                end
            end
        else
            if isequal(x[i], x[j])
                return true
            end
        end
    end
    return false
end

function merge_sum_common_factors(xs)
    length(xs) <= 1 && return false
    merged = Any[]
    i=1
    
    while i<=length(xs)
        l = 1
        nonqop_merged = []

        if istree(xs[i])
            if isterm_op(*)(xs[i])
                qop_args_i = qop_arguments(xs[i])
                nonqop_args_i = nonqop_arguments(xs[i])
                if length(nonqop_args_i) > 0
                    push!(nonqop_merged, *(nonqop_args_i...))
                else
                    push!(nonqop_merged, 1)
                end

                for j=i+1:length(xs)
                    if istree(xs[j])
                        if isterm_op(*)(xs[j])
                            qop_args_j = qop_arguments(xs[j])
                            nonqop_args_j = nonqop_arguments(xs[j])
                            if isequal(qop_args_i, qop_args_j)
                                l += 1
                                if length(nonqop_args_j) > 0
                                    push!(nonqop_merged, *(nonqop_args_j...))
                                else
                                    push!(nonqop_merged, 1)
                                end
                            else
                                break
                            end
                        elseif isterm_op(^)(xs[j])
                            if isequal(qop_args_i, [xs[j]])
                                l += 1
                                push!(nonqop_merged, 1)
                            else
                                break
                            end
                        else
                            break
                        end
                    else
                        if isequal(qop_args_i, [xs[j]])
                            l += 1
                            push!(nonqop_merged, 1)
                        else
                            break
                        end
                    end
                end
            elseif isterm_op(^)(xs[i])
                qop_args_i = [xs[i]]
                push!(nonqop_merged, 1)

                for j=i+1:length(xs)
                    if istree(xs[j])
                        
                        if isterm_op(*)(xs[j])
                            qop_args_j = qop_arguments(xs[j])
                            nonqop_args_j = nonqop_arguments(xs[j])
                            if isequal([xs[i]], qop_args_j)
                                l += 1
                                if length(nonqop_args_j) > 0
                                    push!(nonqop_merged, *(nonqop_args_j...))
                                else
                                    push!(nonqop_merged, 1)
                                end
                            else
                                break
                            end
                        else
                            if isequal(xs[i], xs[j])
                                l += 1
                                push!(nonqop_merged, 1)
                            else
                                break
                            end
                        end
                    else
                        break
                    end
                end
            end
        else
            qop_args_i = [xs[i]]
            push!(nonqop_merged, 1)

            for j=i+1:length(xs)
                if istree(xs[j]) && isterm_op(*)(xs[j])
                    qop_args_j = qop_arguments(xs[j])
                    nonqop_args_j = nonqop_arguments(xs[j])
                    if isequal([xs[i]], qop_args_j)
                        l += 1
                        if length(nonqop_args_j) > 0
                            push!(nonqop_merged, *(nonqop_args_j...))
                        else
                            push!(nonqop_merged, 1)
                        end
                    else
                        break
                    end
                else
                    if isequal(xs[i], xs[j])
                        l += 1
                        push!(nonqop_merged, 1)
                    else
                        break
                    end
                end
            end
        end

        if l > 1
            if !isequal(simplify(+(nonqop_merged...)), 0)
                push!(merged, *(+(nonqop_merged...), *(qop_args_i...)))
            end
        else
            push!(merged, xs[i])
        end
        i+=l
    end
    return merged
end

# function merge_sum_common_factors(xs)
#     length(xs) <= 1 && return false
#     merged = Any[]
#     i=1

#     while i<=length(xs)
#         l = 1
#         num_symsym_merged = []
#         if isterm_op(*)(xs[i])
#             qop_args_i = qop_arguments(xs[i])
#             nonqop_args_i = nonqop_arguments(xs[i])
#             if length(nonqop_args_i) > 0
#                 push!(num_symsym_merged, *(nonqop_args_i...))
#             else
#                 push!(num_symsym_merged, 1)
#             end
#         end
#         for j=i+1:length(xs)
#             if isterm_op(*)(xs[i]) && isterm_op(*)(xs[j])
#                 qop_args_j = qop_arguments(xs[j])
#                 if isequal(qop_args_i, qop_args_j)
#                     l += 1
#                     nonqop_args_j = nonqop_arguments(xs[j])
#                     if length(nonqop_args_j) > 0
#                         push!(num_symsym_merged, *(nonqop_args_j...))
#                     else
#                         push!(num_symsym_merged, 1)
#                     end
#                 else
#                     break
#                 end
#             else
#                 if isequal(xs[i], xs[j])
#                     l += 1
#                 else
#                     break
#                 end
#             end
#         end
#         if l > 1
#             if isterm_op(*)(xs[i])
#                 push!(merged, *(+(num_symsym_merged...), *(qop_args_i...)))
#             else
#                 push!(merged, *(xs[i], l))
#             end
#         else
#             push!(merged, xs[i])
#         end
#         i+=l
#     end
#     return merged
# end

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

function swap_boson(a, b)
    (!sym_isa(QOperator)(a) || !sym_isa(QOperator)(b)) && return a * b
    metadt_a = getmetadata(a, QOperatorMeta)
    metadt_b = getmetadata(b, QOperatorMeta)
    if (is_boson_destroy(a) && is_boson_create(b)) && (metadt_a.h_idx == metadt_b.h_idx)
        return 1 + b * a
    end
    return a * b
end

function qop_arguments(x)
    args = arguments(x)
    idxs = [x isa Symbolic{QOperator} for x in args]
    return args[idxs]
end

function nonqop_arguments(x)
    args = arguments(x)
    idxs = [!(x isa Symbolic{QOperator}) for x in args]
    return args[idxs]
end

function symnum_arguments(x)
    args = arguments(x)
    idxs = [x isa Symbolic{Number} for x in args]
    return args[idxs]
end

function num_arguments(x)
    args = arguments(x)
    idxs = [x isa Number for x in args]
    return args[idxs]
end

