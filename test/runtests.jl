using SecondQuantization
using Test

using SecondQuantization: flatten_term
using Latexify

@testset "Normal Ordering" begin
    @boson a b c
    @parameter ω
    N = a' * a

    @test isequal(normal_order(a * a'), normal_order(a' * a + 1))
    @test isequal(normal_order(a * a', rewriter = threaded_normal_order_simplifier(100)), normal_order(a' * a + 1))

    to_test = to_test = b / ω + b * c + a' * a * b / ω + a' * a * b * c
    @test isequal(normal_order(a * (ω * c+1) * b * a' / ω), to_test)
    @test isequal(normal_order(a * (ω * c+1) * b * a' / ω, rewriter = threaded_normal_order_simplifier(100)), to_test)

    @test isequal(normal_order((a + a')^2), flatten_term(+, 1 + a^2 + flatten_term(*, 2 * a' * a) + a'^2))
    @test isequal(normal_order((a + a')^2, rewriter = threaded_normal_order_simplifier(100)), flatten_term(+, 1 + a^2 + flatten_term(*, 2 * a' * a) + a'^2))

    @test isequal(normal_order(a / a), 1)

    @test isequal(normal_order(a * N * N * N), a + 7 * a' * a^2 + 6 * a'^2 * a^3 + a'^3 * a^4)
end

@testset "Latexify" begin
    @boson a b
    @parameter ω δ

    @test latexify(Expr(:latexifymerge, "\\hat{a}")) == latexify(a)
    @test latexify(Expr(:latexifymerge, "\\hat{a}^\\dagger")) == latexify(a')
    @test latexify(Expr(:latexifymerge, "\\hat{a}^\\dagger\\hat{b}")) == latexify(a' * b)
    @test latexify(Expr(:latexifymerge, "\\hat{a}^\\dagger\\left(1+\\hat{b}\\right)")) == latexify(a' * (1 + b))
    @test latexify(Expr(:latexifymerge, "\\frac{1}{\\omega}\\hat{a}+\\frac{1}{\\omega}\\hat{a}^\\dagger")) == latexify((a + a') / ω)
    @test latexify(Expr(:latexifymerge, "-1+\\hat{a}^\\dagger\\hat{a}")) == latexify(a' * a - 1)
    @test latexify(Expr(:latexifymerge, "\\sin \\left(\\hat{a}+\\hat{a}^\\dagger\\right)")) == latexify(sin(a + a'))
    @test latexify(Expr(:latexifymerge, "\\cos \\left(\\hat{a}+\\hat{a}^\\dagger\\right)")) == latexify(cos(a + a'))
    @test latexify(Expr(:latexifymerge, "e^{\\hat{a}+\\hat{a}^\\dagger}")) == latexify(exp(a + a'))
    @test latexify(Expr(:latexifymerge, "\\hat{a}-\\hat{a}^\\dagger")) == latexify(normal_order(a - a'))
    @test latexify(Expr(:latexifymerge, "{\\hat{a}}^{2}")) == latexify(a^2)
    @test latexify(Expr(:latexifymerge, "\\left(\\hat{a}+\\hat{a}^\\dagger\\right)^{2}")) == latexify((a + a')^2)
    @test latexify(Expr(:latexifymerge, "\\delta\\omega+\\hat{a}")) == latexify(normal_order(a + δ * ω))
    @test latexify(Expr(:latexifymerge, "\\frac{\\delta}{\\omega}+\\hat{a}")) == latexify(a + δ / ω)
    @test latexify(Expr(:latexifymerge, "{\\delta}^{\\omega}+\\hat{a}")) == latexify(a + δ ^ ω)
    @test latexify(Expr(:latexifymerge, "\\left(\\delta+\\omega\\right)^{\\omega}+\\hat{a}")) == latexify(a + (δ+ω) ^ ω)
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