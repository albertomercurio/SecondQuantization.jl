using SecondQuantization
using Test

using SymbolicUtils: flatten_term

@testset "SecondQuantization.jl" begin
    # Write your tests here.
end

@testset "Simplify" begin
    @boson a b c
    @test isequal(simplify(b * a, rewriter = threaded_simplifier(100)), a*b)
    @test isequal(simplify(b * a * b, rewriter = threaded_simplifier(100)), a*b^2)
    @test isequal(simplify(b * a * c * b * 2, rewriter = threaded_simplifier(100)), flatten_term(*, flatten_term(*, 2*a*b^2*c)))
end
