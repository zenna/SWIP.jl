using Documenter, SWIP

makedocs(;
    modules=[SWIP],
    format=Documenter.HTML(),
    pages=[
        "Home" => "index.md",
    ],
    repo="https://github.com/zenna/SWIP.jl/blob/{commit}{path}#L{line}",
    sitename="SWIP.jl",
    authors="Zenna Tavares",
    assets=String[],
)

deploydocs(;
    repo="github.com/zenna/SWIP.jl",
)
