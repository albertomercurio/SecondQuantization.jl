using SecondQuantization
using Test

@testset "SecondQuantization.jl" begin
    # Write your tests here.
end

@testset "Simplify" begin
    @boson a b c
    @test isequal(simplify(b * a, threaded_simplifier(100)), a*b)
    @test isequal(simplify(b * a * b, threaded_simplifier(100)), a*b^2)
    @test isequal(simplify(b * a * c * b * 2, threaded_simplifier(100)), flatten_term(*, flatten_term(*, 2*a*b^2*c)))
end
