using ModelTesting
using Documenter

DocMeta.setdocmeta!(ModelTesting, :DocTestSetup, :(using ModelTesting); recursive=true)

makedocs(;
    modules=[ModelTesting],
    authors="Ben Chung <benjamin.chung@juliahub.com> and contributors",
    repo="https://github.com/BenChung/ModelTesting.jl/blob/{commit}{path}#{line}",
    sitename="ModelTesting.jl",
    format=Documenter.HTML(;
        prettyurls=get(ENV, "CI", "false") == "true",
        edit_link="master",
        assets=String[],
    ),
    pages=[
        "Home" => "index.md",
    ],
)
deploydocs(
    repo = "github.com/JuliaComputing/ModelTesting.jl.git",
)