defmodule OuterfacesEctoApi.QueryEngine.QueryFilter do
  import Ecto.Query
  alias OuterfacesEctoApi.QueryEngine.QueryExpressor
  alias OuterfacesEctoApi.QueryEngine.QueryJoiner

  @doc """
  Filters a query by a given field.

  Parameters:
    - query: The Ecto query.
    - value: The value to filter against.
    - field: The field to filter on.
    - operator: The comparison operator (default: :==).
  """
  @spec by_field(
          query :: Ecto.Query.t(),
          filter_value :: any(),
          filter_field :: atom(),
          filter_operator :: atom()
        ) :: Ecto.Query.t()
  def by_field(query, value, field, operator \\ :==) when is_atom(field) do
    expr = QueryExpressor.build_dynamic(1, operator, field, value)
    where(query, ^expr)
  end

  @doc """
  Filters a query by an association’s field.

  Parameters:
    - query: The Ecto query.
    - value: The value to filter against.
    - binding_list: A literal list of binding atoms (e.g. `[:ecosystem_auditoriums, :auditorium, :current_node]`).
      - or binding index
    - field: The field to filter on (default: :id).
    - operator: The comparison operator (default: :==).
  """
  def by_association_field(query, value, binding_index, field, operator)
      when is_integer(binding_index) do
    if binding_index == 0 do
      query |> where([q], field(q, ^field) == ^value)
    else
      arity = binding_index + 1

      expr = QueryExpressor.build_dynamic(arity, operator, field, value)

      where(query, ^expr)
    end
  end

  def by_association_field(query, value, binding_list, field, operator)
      when is_list(binding_list) do
    candidate_bindings = QueryJoiner.NamedBinding.find_all(query, binding_list)

    case candidate_bindings do
      [{_binding_alias, binding_index, _join} | _] ->
        by_association_field(query, value, binding_index, field, operator)

      [] ->
        raise ArgumentError, "No valid bindings found for aliases: #{inspect(binding_list)}"
    end
  end
end
