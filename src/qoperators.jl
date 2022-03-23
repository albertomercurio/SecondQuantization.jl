abstract type QOperator end
struct BosonicDestroy <: QOperator end
struct BosonicCreate <: QOperator end
struct PauliSP <: QOperator end
struct PauliSM <: QOperator end

mutable struct QOperatorMeta
    type::T where {T<:QOperator}
    h_idx::Int
end


Base.hash(op::T, h::UInt) where T<:Sym{QOperator} = hash(T, hash(op.metadata.type, hash(op.metadata.h_idx, h)))

# TermInterface.exprhead(::QOperator) = :call
# TermInterface.istree(::QOperator) = false

SymbolicUtils.islike(::Symbolic{QOperator}, ::Type{Number}) = true

# Symbolic type promotion
SymbolicUtils.promote_symtype(f, Ts::Type{<:QOperator}...) = promote_type(Ts...)
SymbolicUtils.promote_symtype(f, T::Type{<:QOperator}, Ts...) = T
SymbolicUtils.promote_symtype(f, T::Type{<:QOperator}, S::Type{<:Number}) = T
SymbolicUtils.promote_symtype(f, T::Type{<:Number}, S::Type{<:QOperator}) = S
SymbolicUtils.promote_symtype(f, T::Type{<:QOperator}, S::Type{<:QOperator}) = promote_type(T,S)
SymbolicUtils.symtype(x::T) where T<:QOperator = T

Base.one(::T) where T<:QOperator = one(T)
Base.one(::Type{<:QOperator}) = 1
Base.isone(::QOperator) = false
Base.zero(::T) where T<:QOperator = zero(T)
Base.zero(::Type{<:QOperator}) = 0
Base.iszero(::QOperator) = false

*(x::Symbolic{QOperator}, y::Symbolic{QOperator}) = Term(*, [x, y])
*(x::Symbolic{QOperator}, y::Symbolic{Number}) = Term(*, [x, y])
*(x::Symbolic{Number}, y::Symbolic{QOperator}) = Term(*, [x, y])
*(x::Symbolic{QOperator}, y::Number) = Term(*, [x, y])
*(x::Number, y::Symbolic{QOperator}) = Term(*, [x, y])
*(x::Term{QOperator}) = Term(*, [1, x])
+(x::Symbolic{QOperator}, y::Symbolic{QOperator}) = Term(+, [x, y])
+(x::Symbolic{QOperator}, y::Symbolic{Number}) = Term(+, [x, y])
+(x::Symbolic{Number}, y::Symbolic{QOperator}) = Term(+, [x, y])
+(x::Symbolic{QOperator}, y::Number) = Term(+, [x, y])
+(x::Number, y::Symbolic{QOperator}) = Term(+, [x, y])
+(x::Term{QOperator}) = Term(+, [0, x])
-(x::Symbolic{QOperator}, y::Symbolic{QOperator}) = Term(-, [x, y])
-(x::Symbolic{QOperator}, y::Symbolic{Number}) = Term(-, [x, y])
-(x::Symbolic{Number}, y::Symbolic{QOperator}) = Term(-, [x, y])
-(x::Symbolic{QOperator}, y::Number) = Term(-, [x, y])
-(x::Number, y::Symbolic{QOperator}) = Term(-, [x, y])
-(x::Term{QOperator}) = Term(-, [0, x])
/(x::Symbolic{QOperator}, y::Symbolic{QOperator}) = Term(/, [x, y])
/(x::Symbolic{QOperator}, y::Symbolic{Number}) = Term(/, [x, y])
/(x::Symbolic{Number}, y::Symbolic{QOperator}) = Term(/, [x, y])
/(x::Symbolic{QOperator}, y::Number) = Term(/, [x, y])
/(x::Number, y::Symbolic{QOperator}) = Term(/, [x, y])
^(x::Symbolic{QOperator}, n::Number) = Term(^, [x, n])
^(x::Symbolic{QOperator}, n::Symbolic{QOperator}) = Term(^, [x, n])

function Base.adjoint(op::Symbolic{QOperator})
    op_type = op.metadata.type
    h_idx = op.metadata.h_idx
    if op_type == BosonicDestroy()
        return Sym{QOperator}(Symbol(String(op.name) * "_d"), metadata = QOperatorMeta(BosonicCreate(), h_idx))
    elseif op_type == BosonicCreate()
        return Sym{QOperator}(Symbol(String(op.name)[1:end-2]), metadata = QOperatorMeta(BosonicDestroy(), h_idx))
    end
end

function Base.isequal(a::Term{QOperator},b::Term{QOperator})
    length(arguments(a))==length(arguments(b)) || return false
    for (arg_a,arg_b) ∈ zip(arguments(a), arguments(b))
        isequal(arg_a, arg_b) || return false
    end
    return true
end

macro boson(xs...)
    global hilbert_space_iterator
    defs = map(enumerate(xs)) do (i, x)
        n, t = _name_type(x)
        T = esc(t)
        nt = _name_type(x)
        n, t = nt.name, nt.type
        :($(esc(n)) = Sym{QOperator}($(Expr(:quote, n)), metadata = QOperatorMeta(BosonicDestroy(), hilbert_space_iterator + $(esc(i)))))
    end
    hilbert_space_iterator += length(xs)
    Expr(:block, defs...,
         :(tuple($(map(x->esc(_name_type(x).name), xs)...))))
end

macro paulism(xs...)
    global hilbert_space_iterator
    defs = map(enumerate(xs)) do (i, x)
        n, t = _name_type(x)
        T = esc(t)
        nt = _name_type(x)
        n, t = nt.name, nt.type
        :($(esc(n)) = Sym{QOperator}($(Expr(:quote, n)), metadata = QOperatorMeta(PauliSM(), hilbert_space_iterator + $(esc(i)))))
    end
    hilbert_space_iterator += length(xs)
    Expr(:block, defs...,
         :(tuple($(map(x->esc(_name_type(x).name), xs)...))))
end