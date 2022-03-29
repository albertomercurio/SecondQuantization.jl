abstract type QOperator end
abstract type QOperatorType end
struct BosonicDestroy <: QOperatorType end
struct BosonicCreate <: QOperatorType end
struct PauliSP <: QOperatorType end
struct PauliSM <: QOperatorType end

mutable struct QOperatorMeta
    type::T where {T<:QOperatorType}
    h_idx::Int
end

Base.hash(op::T, h::UInt) where T<:Sym{QOperator} = hash(T, hash(getmetadata(op, QOperatorMeta).type, hash(getmetadata(op, QOperatorMeta).h_idx, h)))

# TermInterface.exprhead(::QOperator) = :call
TermInterface.istree(::Type{<:QOperator}) = false
# TermInterface.arguments(::Type{<:QOperator}) = []

SymbolicUtils.promote_symtype(f, Ts::Type{<:QOperator}...) = promote_type(Ts...)
SymbolicUtils.promote_symtype(f, T::Type{<:QOperator}, Ts...) = T
SymbolicUtils.promote_symtype(f, T::Type{<:QOperator}, S::Type{<:Number}) = T
SymbolicUtils.promote_symtype(f, T::Type{<:Number}, S::Type{<:QOperator}) = S
SymbolicUtils.promote_symtype(f, T::Type{<:QOperator}, S::Type{<:QOperator}) = promote_type(T,S)

SymbolicUtils.islike(::Symbolic{QOperator}, ::Type{Number}) = true

for f in [+, -, *, \, /, ^]
    @eval SymbolicUtils.promote_symtype(::$(typeof(f)), Ts::Type{<:QOperator}...) = promote_type(Ts...)
    @eval SymbolicUtils.promote_symtype(::$(typeof(f)), T::Type{<:QOperator}, Ts...) = T
    @eval SymbolicUtils.promote_symtype(::$(typeof(f)), T::Type{<:QOperator}, S::Type{<:Number}) = T
    @eval SymbolicUtils.promote_symtype(::$(typeof(f)), T::Type{<:Number}, S::Type{<:QOperator}) = S
    @eval SymbolicUtils.promote_symtype(::$(typeof(f)), T::Type{<:QOperator}, S::Type{<:QOperator}) = promote_type(T,S)
end


Base.one(::T) where T<:QOperator = one(T)
Base.one(::Type{<:QOperator}) = 1
Base.zero(::T) where T<:QOperator = zero(T)
Base.zero(::Type{<:QOperator}) = 0
Base.isone(::QOperator) = false
Base.iszero(::QOperator) = false

*(x::Symbolic{QOperator}, y::Symbolic{QOperator}) = Term(*, [x, y])
*(x::Symbolic{QOperator}, y::Symbolic{Number}) = Term(*, [x, y])
*(x::Symbolic{Number}, y::Symbolic{QOperator}) = Term(*, [x, y])
*(x::Symbolic{QOperator}, y::Number) = Term(*, [x, y])
*(x::Number, y::Symbolic{QOperator}) = Term(*, [x, y])
*(x::Symbolic{QOperator}) = x
*(x::Term{QOperator}) = x
+(x::Symbolic{QOperator}, y::Symbolic{QOperator}) = Term(+, [x, y])
+(x::Symbolic{QOperator}, y::Symbolic{Number}) = Term(+, [x, y])
+(x::Symbolic{Number}, y::Symbolic{QOperator}) = Term(+, [x, y])
+(x::Symbolic{QOperator}, y::Number) = Term(+, [x, y])
+(x::Number, y::Symbolic{QOperator}) = Term(+, [x, y])
+(x::Symbolic{QOperator}) = x
+(x::Term{QOperator}) = x
-(x::Symbolic{QOperator}, y::Symbolic{QOperator}) = Term(+, [x, -1*y])
-(x::Symbolic{QOperator}, y::Symbolic{Number}) = Term(+, [x, -1*y])
-(x::Symbolic{Number}, y::Symbolic{QOperator}) = Term(+, [x, -1*y])
-(x::Symbolic{QOperator}, y::Number) = Term(+, [x, -1*y])
-(x::Number, y::Symbolic{QOperator}) = Term(+, [x, -1*y])
-(x::Symbolic{QOperator}) = Term(+, [0, -1 * x])
/(x::Symbolic{QOperator}, y::Symbolic{QOperator}) = Term(/, [x, y])
/(x::Symbolic{QOperator}, y::Symbolic{Number}) = Term(/, [x, y])
/(x::Symbolic{Number}, y::Symbolic{QOperator}) = Term(/, [x, y])
/(x::Symbolic{QOperator}, y::Number) = Term(*, [x, 1 // y])
/(x::Number, y::Symbolic{QOperator}) = Term(/, [x, y])
^(x::Symbolic{QOperator}, n::Number) = Term(^, [x, n])
^(x::Symbolic{QOperator}, n::Symbolic{QOperator}) = Term(^, [x, n])

function Base.adjoint(op::Symbolic{QOperator})
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

function Base.isequal(a::Term{QOperator},b::Term{QOperator})
    length(arguments(a))==length(arguments(b)) || return false
    for (arg_a,arg_b) ∈ zip(arguments(a), arguments(b))
        isequal(arg_a, arg_b) || return false
    end
    return true
end

function commutator(a, b)
    return normal_order(a * b - b * a)
end

macro boson(xs...)
    global hilbert_space_iterator
    defs = map(enumerate(xs)) do (i, x)
        n, t = _name_type(x)
        T = esc(t)
        nt = _name_type(x)
        n, t = nt.name, nt.type
        :($(esc(n)) = Sym{QOperator}($(Expr(:quote, n))); $(esc(n)) = setmetadata($(esc(n)), QOperatorMeta, QOperatorMeta(BosonicDestroy(), hilbert_space_iterator + $(esc(i)))))
    end
    hilbert_space_iterator += length(xs)
    Expr(:block, defs...,
         :(tuple($(map(x->esc(_name_type(x).name), xs)...))))
end

macro parameter(xs...)
    defs = map(enumerate(xs)) do (i, x)
        n, t = _name_type(x)
        T = esc(t)
        nt = _name_type(x)
        n, t = nt.name, nt.type
        :($(esc(n)) = Sym{$T}($(Expr(:quote, n))))
    end
    Expr(:block, defs...,
         :(tuple($(map(x->esc(_name_type(x).name), xs)...))))
end

# macro paulism(xs...)
#     global hilbert_space_iterator
#     defs = map(enumerate(xs)) do (i, x)
#         n, t = _name_type(x)
#         T = esc(t)
#         nt = _name_type(x)
#         n, t = nt.name, nt.type
#         :($(esc(n)) = Sym{QOperator}($(Expr(:quote, n)), metadata = QOperatorMeta(PauliSM(), hilbert_space_iterator + $(esc(i)))))
#     end
#     hilbert_space_iterator += length(xs)
#     Expr(:block, defs...,
#          :(tuple($(map(x->esc(_name_type(x).name), xs)...))))
# end