defmodule OuterfacesEctoApi.Codegen.JsCodegen do
  @moduledoc """
  Generates JavaScript type definitions from Ecto schemas.
  """

  @spec generate_js_typedef(
          schema :: String.t(),
          controller_module :: String.t() | nil
        ) :: String.t()
  def generate_js_typedef(schema, nil) do
    schema_name = schema |> String.split(".") |> List.last()

    schema_module =
      ("Elixir." <> schema)
      |> String.to_existing_atom()

    fields_defs = build_field_defs(schema_module)

    association_defs = build_association_defs(schema_module)

    """
    /**
     * @typedef {Object} #{schema_name}
    #{fields_defs}
    #{association_defs}
     */
    """
  end

  def generate_js_typedef(schema, controller_module_name)
      when is_binary(controller_module_name) do
    schema_name = schema |> String.split(".") |> List.last()

    schema_module =
      ("Elixir." <> schema)
      |> String.to_existing_atom()

    controller_module_atom = "Elixir." <> controller_module_name

    Code.ensure_loaded?(String.to_atom(controller_module_atom))

    controller_module =
      controller_module_atom
      |> String.to_existing_atom()

    fields_defs = build_field_defs(schema_module)

    index_association_defs =
      build_association_defs(schema_module, controller_module, :index_preloads, 0, [])

    show_association_defs =
      build_association_defs(schema_module, controller_module, :show_preloads, 0, [])

    """
    /**
     * @typedef {Object} #{schema_name}IndexData
    #{fields_defs}
    #{index_association_defs}
     */

    /**
     * @typedef {Object} Fetch#{schema_name}IndexQueryParams
     * @property {Object} [filters] - Filters to apply to the query
     * @property {string[]} [sort] - Sort order for the query. Format: ['sort_name:asc', 'sort_name:desc']
     * @property {number} [limit] - Maximum number of records to return
     * @property {number} [offset] - Offset for the query
     *
    */

    /**
     * @typedef {Object} Fetch#{schema_name}IndexQueryResult
     * @property {number} status,
     * @property {Object} results
     * @property {#{schema_name}IndexData[]} results.data
     * @property {string} results.schema
     * @property {PageInfo} results.page_info
     */

    /**
     * @typedef {Object} #{schema_name}ShowData
    #{fields_defs}
    #{show_association_defs}
     */

    /**
     * @typedef {Object} Fetch#{schema_name}ShowQueryResult
     * @property {number} status
     * @property {Object} results
     * @property {#{schema_name}ShowData} results.data
     * @property {string} results.schema
     */
    """
  end

  defp ecto_type_to_js_type(:integer), do: "number"
  defp ecto_type_to_js_type(:id), do: "number"
  defp ecto_type_to_js_type(:string), do: "string"
  defp ecto_type_to_js_type(:boolean), do: "boolean"
  defp ecto_type_to_js_type(:float), do: "number"
  defp ecto_type_to_js_type(:naive_datetime), do: "string"
  defp ecto_type_to_js_type(:utc_datetime), do: "string"
  defp ecto_type_to_js_type(:date), do: "string"
  defp ecto_type_to_js_type(:map), do: "Record<string, any>"
  defp ecto_type_to_js_type(_), do: "any"

  @spec build_field_defs(schema_module :: module()) :: String.t()
  defp build_field_defs(schema_module) do
    Code.ensure_loaded(schema_module)

    maybe_skip_fields =
      (function_exported?(schema_module, :serializer_skip_fields, 1) &&
         apply(schema_module, :serializer_skip_fields, [nil])) || []

    schema_module.__schema__(:fields)
    |> Enum.reject(fn field -> field in maybe_skip_fields end)
    |> Enum.map(fn field ->
      type = ecto_type_to_js_type(schema_module.__schema__(:type, field))
      " * @property {#{type}} #{field}"
    end)
    |> Enum.join("\n")
  end

  @spec build_association_defs(
          schema_module :: module(),
          preloader_module :: module(),
          function :: atom(),
          arity :: non_neg_integer(),
          arguments :: [term()]
        ) :: String.t()
  defp build_association_defs(
         schema_module,
         preloader_module,
         function,
         arity,
         arguments
       ) do
    preloads =
      (function_exported?(preloader_module, function, arity) &&
         apply(preloader_module, function, arguments)) || []

    preload_keys =
      Enum.map(preloads, fn
        {key, _value} -> key
        key -> key
      end)

    build_filtered_association_defs(schema_module, preload_keys)
  end

  @spec build_association_defs(
          schema_module :: module(),
          associations :: [atom()]
        ) :: String.t()
  defp build_association_defs(schema_module, associations) do
    associations
    |> Enum.map(fn assoc ->
      refl = schema_module.__schema__(:association, assoc)

      assoc_module =
        case refl do
          %{queryable: queryable} ->
            queryable
            |> to_string()
            |> String.split(".")
            |> List.last()

          %Ecto.Association.HasThrough{} ->
            fetch_final_module_in_chain(schema_module, refl.through)
        end

      assoc_module = Macro.camelize(assoc_module)

      assoc_module =
        if refl.cardinality == :many do
          "#{assoc_module}[]"
        else
          assoc_module
        end

      " * @property {#{assoc_module} | null} #{assoc}"
    end)
    |> Enum.join("\n")
  end

  @spec build_association_defs(schema_module :: module()) :: String.t()
  defp build_association_defs(schema_module) do
    associations =
      schema_module.__schema__(:associations)

    build_association_defs(schema_module, associations)
  end

  @spec build_filtered_association_defs(
          schema_module :: module(),
          preload_keys :: [atom()]
        ) :: String.t()
  defp build_filtered_association_defs(schema_module, preload_keys) do
    associations =
      schema_module.__schema__(:associations)
      |> Enum.filter(fn assoc -> assoc in preload_keys end)

    build_association_defs(schema_module, associations)
  end

  defp fetch_final_module_in_chain(root_module, through_chain) do
    Enum.reduce(through_chain, root_module, fn assoc, current_mod ->
      sub_refl = current_mod.__schema__(:association, assoc)

      if is_nil(sub_refl) do
        raise ArgumentError,
              "Invalid association in `through:` chain" <>
                " for top-level schema `#{inspect(root_module)}`: " <>
                "`#{assoc}` not found on intermediate schema `#{inspect(current_mod)}`"
      end

      sub_refl.queryable
    end)
    |> to_string()
    |> String.split(".")
    |> List.last()
  end
end
