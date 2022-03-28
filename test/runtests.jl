using SecondQuantization
using Test

using SecondQuantization: flatten_term
using Latexify

@testset "Simplify and Normal Order" begin
    @boson a b c
    @parameter ω

    @test isequal(simplify(b * a, rewriter = serial_simplifier), a*b)
    @test isequal(simplify(b * a, rewriter = serial_expand_simplifier), a*b)
    @test isequal(simplify(b * a, rewriter = threaded_simplifier(100)), a*b)

    @test isequal(simplify(b * a * b, rewriter = serial_simplifier), a*b^2)
    @test isequal(simplify(b * a * b, rewriter = serial_expand_simplifier), a*b^2)
    @test isequal(simplify(b * a * b, rewriter = threaded_simplifier(100)), a*b^2)

    @test isequal(simplify(b * a * c * b * 2, rewriter = serial_simplifier), flatten_term(*, flatten_term(*, 2*a*b^2*c)))
    @test isequal(simplify(b * a * c * b * 2, rewriter = serial_expand_simplifier), flatten_term(*, flatten_term(*, 2*a*b^2*c)))
    @test isequal(simplify(b * a * c * b * 2, rewriter = threaded_simplifier(100)), flatten_term(*, flatten_term(*, 2*a*b^2*c)))

    @test isequal(normal_order(a * a'), normal_order(a' * a + 1))
    @test isequal(normal_order(a * a', rewriter = threaded_normal_order_simplifier(100)), normal_order(a' * a + 1))

    to_test = flatten_term(+, b + flatten_term(*, a' * a * b) + flatten_term(*, ω * b * c) + flatten_term(*, ω * a' * a * b * c)) / ω
    @test isequal(normal_order(a * (ω * c+1) * b * a' / ω), to_test)
    @test isequal(normal_order(a * (ω * c+1) * b * a' / ω, rewriter = threaded_normal_order_simplifier(100)), to_test)

    @test isequal(normal_order((a + a')^2), flatten_term(+, 1 + a^2 + a'^2 + flatten_term(*, 2 * a' * a)))
    @test isequal(normal_order((a + a')^2, rewriter = threaded_normal_order_simplifier(100)), flatten_term(+, 1 + a^2 + a'^2 + flatten_term(*, 2 * a' * a)))

    @test isequal(normal_order(a / a), 1)
end

@testset "Latexify" begin
    @boson a b
    @parameter ω

    @test latexify(Expr(:latexifymerge, "\\hat{a}")) == latexify(a)
    @test latexify(Expr(:latexifymerge, "\\hat{a}^\\dagger")) == latexify(a')
    @test latexify(Expr(:latexifymerge, "\\hat{a}^\\dagger\\hat{b}")) == latexify(a' * b)
    @test latexify(Expr(:latexifymerge, "\\hat{a}^\\dagger\\left(1+\\hat{b}\\right)")) == latexify(a' * (1 + b))
    @test latexify(Expr(:latexifymerge, "\\frac{\\hat{a}}{\\hat{a}}")) == latexify(a / a)
    @test latexify(Expr(:latexifymerge, "\\frac{1}{\\omega}\\left(\\hat{a}+\\hat{a}^\\dagger\\right)")) == latexify((a + a') / ω)
    @test latexify(Expr(:latexifymerge, "\\hat{a}^\\dagger\\hat{a}-1")) == latexify(a' * a - 1)
    @test latexify(Expr(:latexifymerge, "\\sin \\left(\\hat{a}+\\hat{a}^\\dagger\\right)")) == latexify(sin(a + a'))
    @test latexify(Expr(:latexifymerge, "\\cos \\left(\\hat{a}+\\hat{a}^\\dagger\\right)")) == latexify(cos(a + a'))
    @test latexify(Expr(:latexifymerge, "e^{\\hat{a}+\\hat{a}^\\dagger}")) == latexify(exp(a + a'))
end

@testset "Commutator" begin
    @boson a b
    @parameter ω δ

    @test isequal(commutator(a, b), 0)
    @test isequal(commutator(a, a), 0)
    @test isequal(commutator(a, a'), 1)
    @test isequal(commutator(a', a), -1)
    @test isequal(commutator(a, a' * ω), ω)
    @test isequal(commutator(a * ω^2 / (ω + δ), a'), ω^2 / (ω + δ))
    @test isequal(commutator(a * ω^2, a' * δ^2), ω^2 * δ^2)
end