using SecondQuantization
using Documenter

DocMeta.setdocmeta!(SecondQuantization, :DocTestSetup, :(using SecondQuantization); recursive=true)

makedocs(;
    modules=[SecondQuantization],
    authors="Alberto Mercurio",
    repo="https://github.com/albertomercurio/SecondQuantization.jl/blob/{commit}{path}#{line}",
    sitename="SecondQuantization.jl",
    format=Documenter.HTML(;
        prettyurls=get(ENV, "CI", "false") == "true",
        canonical="https://albertomercurio.github.io/SecondQuantization.jl",
        assets=String[],
    ),
    pages=[
        "Home" => "index.md",
    ],
)

deploydocs(;
    repo="github.com/albertomercurio/SecondQuantization.jl",
    devbranch="main",
)
