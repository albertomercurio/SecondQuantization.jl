using SecondQuantization
using Test

using SymbolicUtils: flatten_term
using Latexify

@testset "SecondQuantization.jl" begin
    # Write your tests here.
end

@testset "Simplify" begin
    @boson a b c

    @test isequal(simplify(b * a, rewriter = serial_simplifier), a*b)
    @test isequal(simplify(b * a, rewriter = serial_expand_simplifier), a*b)
    @test isequal(simplify(b * a, rewriter = threaded_simplifier(100)), a*b)

    @test isequal(simplify(b * a * b, rewriter = serial_simplifier), a*b^2)
    @test isequal(simplify(b * a * b, rewriter = serial_expand_simplifier), a*b^2)
    @test isequal(simplify(b * a * b, rewriter = threaded_simplifier(100)), a*b^2)

    @test isequal(simplify(b * a * c * b * 2, rewriter = serial_simplifier), flatten_term(*, flatten_term(*, 2*a*b^2*c)))
    @test isequal(simplify(b * a * c * b * 2, rewriter = serial_expand_simplifier), flatten_term(*, flatten_term(*, 2*a*b^2*c)))
    @test isequal(simplify(b * a * c * b * 2, rewriter = threaded_simplifier(100)), flatten_term(*, flatten_term(*, 2*a*b^2*c)))
end

@testset "Latexify" begin
    @boson a b
    @test latexify(Expr(:latexifymerge, "\\hat{a}")) == latexify(a)
    @test latexify(Expr(:latexifymerge, "\\hat{a}^\\dagger")) == latexify(a')
    @test latexify(Expr(:latexifymerge, "\\hat{a}^\\dagger\\hat{b}")) == latexify(a' * b)
    @test latexify(Expr(:latexifymerge, "\\hat{a}^\\dagger\\left(1+\\hat{b}\\right)")) == latexify(a' * (1 + b))
end
