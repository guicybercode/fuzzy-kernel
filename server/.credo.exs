%{
  configs: [
    %{
      name: "default",
      files: %{
        included: ["lib/", "test/"],
        excluded: []
      },
      checks: [
        {Credo.Check.Readability.MaxLineLength, priority: :low, max_length: 120},
        {Credo.Check.Design.AliasUsage, priority: :low, if_nested_deeper_than: 2},
        {Credo.Check.Refactor.Nesting, priority: :low, max_nesting: 3},
        {Credo.Check.Warning.IoInspect, false},
        {Credo.Check.Refactor.ABCSize, false},
        {Credo.Check.Warning.UnusedFileOperation, false}
      ]
    }
  ]
}

