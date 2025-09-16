defmodule OuterfacesEctoApi.QueryEngine.QueryAssociator do
  @moduledoc """
  Helper functions for API models.
  """

  @spec preload_and_serialize(
          repo :: Ecto.Repo.t(),
          queryable :: Ecto.Queryable.t() | [Ecto.Queryable.t()],
          preloads :: list(atom() | {atom(), list(atom())}),
          opts :: Keyword.t()
        ) :: list(map())
  def preload_and_serialize(repo, queryable, preloads, opts) when is_list(queryable) do
    repo
    |> preload_query(queryable, preloads)
    |> Enum.map(&do_pre_serialize(&1, preloads, opts))
  end

  def preload_and_serialize(repo, queryable, preloads, opts) do
    repo
    |> preload_query(queryable, preloads)
    |> do_pre_serialize(preloads, opts)
  end

  defp do_pre_serialize(record, preloads, opts) when is_struct(record) do
    case record.__struct__ do
      nil ->
        record

      struct ->
        if function_exported?(struct, :pre_serialize, 3) do
          struct.pre_serialize(record, preloads, opts)
        else
          raise """
          The struct #{inspect(struct)} does not implement the `pre_serialize/3` function.

          add `use OuterfacesEctoApi.QueryEngine.QuerySerializer` to the struct module
          to use the default implementation.
          """
        end
    end
  end

  defp do_pre_serialize(field, _preloads, _opts) do
    field
  end

  defp preload_query(repo, queryable, preloads) do
    Enum.reduce(preloads, queryable, fn
      {field, nested_fields}, acc ->
        repo.preload(acc, [{field, nested_fields}])

      field, acc when is_atom(field) ->
        repo.preload(acc, field)
    end)
  end

  @spec pre_serialize_fields(
          result :: map(),
          source_record :: map(),
          fields :: list(atom() | {atom(), list(atom())}),
          opts :: Keyword.t()
        ) :: map()
  def pre_serialize_fields(result, source_record, fields, opts)
      when is_map(result) and is_map(source_record) and is_list(fields) do
    result = result |> Map.put(:schema, source_record.__struct__ |> Atom.to_string())

    Enum.reduce(fields, result, fn
      {key, nested_fields}, acc when is_atom(key) ->
        case Map.get(source_record, key) do
          nil ->
            acc
            |> Map.put(key, nil)

          value when is_list(value) ->
            Map.put(
              acc,
              key,
              Enum.map(value, &do_pre_serialize(&1, nested_fields, opts))
            )

          value ->
            Map.put(
              acc,
              key,
              do_pre_serialize(value, nested_fields, opts)
            )
        end

      key, acc when not is_nil(key) and is_atom(key) ->
        case Map.get(source_record, key) do
          nil ->
            acc
            |> Map.put(key, nil)

          value when is_list(value) ->
            Map.put(
              acc,
              key,
              Enum.map(value, &do_pre_serialize(&1, [], opts))
            )

          value ->
            Map.put(
              acc,
              key,
              do_pre_serialize(value, [], opts)
            )
        end

      _, acc ->
        acc
    end)
  end
end
