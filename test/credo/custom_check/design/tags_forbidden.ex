defmodule Credo.CustomCheck.Design.TagsForbidden do
  @moduledoc false
  use Credo.Check,
    # id: "EX2902",
    base_priority: :high,
    param_defaults: [include_doc: true],
    explanations: [
      check: """
      Comments that contains words such as BROKEN, BUG, HACK, XXX
      are used to indicate places where source code needs fixing.
      Example:
          # BROKEN: this does no longer work, research new API url
          defp fun do
            # ...
          end
      The premise here is that related code should indeed be fixed as soon as possible and
      are therefore reported by Credo.
      Like all `Software Design` issues, this is just advice and might not be
      applicable to your project/situation.
      """,
      params: [
        include_doc: "Set to `true` to also include tags from @doc attributes"
      ]
    ]

  alias Credo.Check.Design.TagHelper

  @dialyzer {:nowarn_function, run: 2}

  # NOTE: FIXME and TODO tags are already handled in
  # Credo.Check.Design.TagFIXME and Credo.Check.Design.TagTODO
  @tag_names ~w[BROKEN BUG HACK OPTIMIZE REVIEW WTF XXX]

  @doc false
  @impl Credo.Check
  def run(%SourceFile{} = source_file, params) do
    issue_meta = IssueMeta.for(source_file, params)
    include_doc? = Params.get(params, :include_doc, __MODULE__)

    Enum.flat_map(@tag_names, fn tag_name ->
      source_file
      |> TagHelper.tags(tag_name, include_doc?)
      |> Enum.map(&issue_for(issue_meta, tag_name, &1))
    end)
  end

  defp issue_for(issue_meta, tag_name, {line_no, _line, trigger}) do
    format_issue(
      issue_meta,
      message: "Found a #{tag_name} tag in a comment: #{trigger}",
      line_no: line_no,
      trigger: trigger
    )
  end
end
