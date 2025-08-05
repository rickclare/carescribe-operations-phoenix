# credo:disable-for-this-file Credo.CustomCheck.Design.PhrasesForbidden
defmodule Credo.CustomCheck.Design.PhrasesForbidden do
  @moduledoc "Checks all lines for a given Regex"

  use Credo.Check,
    # id: "EX2901",
    base_priority: :high,
    category: :custom,
    exit_status: 0

  @explanation [
    check: @moduledoc
  ]

  @doc false
  @impl Credo.Check
  def run(%SourceFile{} = source_file, params) do
    lines = SourceFile.lines(source_file)
    issue_meta = IssueMeta.for(source_file, params)
    line_regex = ~r/:timer\.sleep|take_screenshot|open_browser/i

    Enum.reduce(lines, [], &process_line(&1, &2, line_regex, issue_meta))
  end

  defp process_line({line_no, line}, issues, line_regex, issue_meta) do
    case Regex.run(line_regex, line) do
      nil ->
        issues

      matches ->
        trigger = List.last(matches)
        new_issue = issue_for(issue_meta, line_no, trigger)
        [new_issue] ++ issues
    end
  end

  defp issue_for(issue_meta, line_no, trigger) do
    format_issue(issue_meta,
      message: "Found a forbidden phrase [#{trigger}]",
      line_no: line_no,
      trigger: trigger
    )
  end
end
