defmodule OuterfacesEctoApi.QueryEngine.QueryJoiner do
  @moduledoc """
  Provides macros for dynamically constructing Ecto queries with filters and nested joins.
  """
  import Ecto.Query

  @spec ensure_joins(Ecto.Query.t(), list({atom(), module(), atom(), atom()})) :: Ecto.Query.t()
  defmacro ensure_joins(query, chain) do
    quote do
      Enum.reduce(unquote(chain), {unquote(query), nil}, fn
        {assoc_name, related_schema, owner_key, related_key}, {acc_query, parent_alias} ->
          expected_alias =
            if parent_alias, do: String.to_atom("#{parent_alias}_#{assoc_name}"), else: assoc_name

          already_joined? = Enum.any?(acc_query.joins, fn j -> j.as == expected_alias end)

          if already_joined? do
            {acc_query, expected_alias}
          else
            new_query =
              OuterfacesEctoApi.QueryEngine.QueryJoiner.do_join(
                acc_query,
                assoc_name,
                related_schema,
                owner_key,
                related_key,
                parent_alias
              )

            {new_query, expected_alias}
          end
      end)
      |> elem(0)
    end
  end

  @spec do_join(Ecto.Query.t(), atom(), module(), atom(), atom(), atom()) ::
          Ecto.Query.t()
  defmacro do_join(
             query,
             assoc_name,
             related_schema,
             owner_key,
             related_key,
             parent_alias \\ nil
           ) do
    quote bind_quoted: [
            query: query,
            assoc_name: assoc_name,
            related_schema: related_schema,
            owner_key: owner_key,
            related_key: related_key,
            parent_alias: parent_alias
          ] do
      new_alias =
        if parent_alias do
          String.to_atom("#{parent_alias}_#{assoc_name}")
        else
          assoc_name
        end

      if parent_alias do
        from([{^parent_alias, parent}] in query,
          left_join: assoc in ^related_schema,
          as: ^new_alias,
          on: field(parent, ^owner_key) == field(assoc, ^related_key)
        )
      else
        from(e0 in query,
          left_join: assoc in ^related_schema,
          as: ^new_alias,
          on: field(e0, ^owner_key) == field(assoc, ^related_key)
        )
      end
    end
  end

  defmodule NamedBinding do
    @moduledoc """
    Helper functions for working with named bindings in Ecto queries.
    """

    @spec find_all(Ecto.Query.t(), list(atom())) :: list({atom(), integer(), Ecto.Query.Join.t()})
    def find_all(query, binding_names) when is_list(binding_names) do
      binding_names
      |> Enum.reduce({[], nil}, fn binding_name, {acc, parent_alias} ->
        alias_to_find =
          if parent_alias do
            String.to_atom("#{parent_alias}_#{binding_name}")
          else
            binding_name
          end

        case find(query, alias_to_find) do
          nil -> {acc, alias_to_find}
          {idx, join} -> {[{alias_to_find, idx, join} | acc], alias_to_find}
        end
      end)
      |> elem(0)
      |> Enum.reverse()
    end

    @spec find(Ecto.Query.t(), atom()) :: {integer(), Ecto.Query.Join.t()} | nil
    def find(query, binding_name) do
      query.joins
      |> Enum.with_index(1)
      |> Enum.find_value(fn {join, idx} ->
        if join.as == binding_name, do: {idx, join}, else: nil
      end)
    end
  end
end
