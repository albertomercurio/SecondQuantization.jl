abstract type QOperator end
abstract type QOperatorType end
struct BosonicDestroy <: QOperatorType end
struct BosonicCreate <: QOperatorType end
struct PauliSP <: QOperatorType end
struct PauliSM <: QOperatorType end

mutable struct QOperatorMeta
    type::QOperatorType
    h_idx::Int
end

Base.hash(op::T, h::UInt) where T<:Sym{QOperator} = hash(T, hash(getmetadata(op, QOperatorMeta).type, hash(getmetadata(op, QOperatorMeta).h_idx, h)))

# TermInterface.exprhead(::QOperator) = :call
# TermInterface.istree(::Type{<:QOperator}) = false
# TermInterface.arguments(::Type{<:QOperator}) = []

SymbolicUtils.promote_symtype(f, Ts::Type{<:QOperator}...) = promote_type(Ts...)
SymbolicUtils.promote_symtype(f, T::Type{<:QOperator}, Ts...) = T
SymbolicUtils.promote_symtype(f, T::Type{<:QOperator}, S::Type{<:Number}) = T
SymbolicUtils.promote_symtype(f, T::Type{<:Number}, S::Type{<:QOperator}) = S
SymbolicUtils.promote_symtype(f, T::Type{<:QOperator}, S::Type{<:QOperator}) = promote_type(T,S)

SymbolicUtils.promote_symtype(f, Ts::Type{<:QOperatorType}...) = promote_type(Ts...)
SymbolicUtils.promote_symtype(f, T::Type{<:QOperatorType}, Ts...) = T
SymbolicUtils.promote_symtype(f, T::Type{<:QOperatorType}, S::Type{<:Number}) = T
SymbolicUtils.promote_symtype(f, T::Type{<:Number}, S::Type{<:QOperatorType}) = S
SymbolicUtils.promote_symtype(f, T::Type{<:QOperatorType}, S::Type{<:QOperatorType}) = promote_type(T,S)

SymbolicUtils.islike(::Symbolic{QOperator}, ::Type{Number}) = true

for f in [+, -, *, \, /, ^]
    @eval SymbolicUtils.promote_symtype(::$(typeof(f)), Ts::Type{<:QOperator}...) = promote_type(Ts...)
    @eval SymbolicUtils.promote_symtype(::$(typeof(f)), T::Type{<:QOperator}, Ts...) = T
    @eval SymbolicUtils.promote_symtype(::$(typeof(f)), T::Type{<:QOperator}, S::Type{<:Number}) = T
    @eval SymbolicUtils.promote_symtype(::$(typeof(f)), T::Type{<:Number}, S::Type{<:QOperator}) = S
    @eval SymbolicUtils.promote_symtype(::$(typeof(f)), T::Type{<:QOperator}, S::Type{<:QOperator}) = promote_type(T,S)
end

function Base.isequal(a::Term{QOperator},b::Term{QOperator})
    length(arguments(a))==length(arguments(b)) || return false
    for (arg_a,arg_b) ∈ zip(arguments(a), arguments(b))
        isequal(arg_a, arg_b) || return false
    end
    return true
end

function commutator(a, b)
    return normal_order(normal_order(a * b) - normal_order(b * a))
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