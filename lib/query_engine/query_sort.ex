defmodule OuterfacesEctoApi.QueryEngine.QuerySort do
  import Ecto.Query
  alias OuterfacesEctoApi.QueryEngine.QueryJoiner

  @doc """
  Sorts a query by a given field.

  Parameters:
    - query: The Ecto query.
    - field: The field to sort on.
    - direction: The sort direction (:asc or :desc, default: :asc).
  """
  @spec by_field(
          query :: Ecto.Query.t(),
          sort_field :: atom(),
          sort_direction :: :asc | :desc
        ) :: Ecto.Query.t()
  def by_field(query, field, direction \\ :asc) when is_atom(field) do
    order_expr = [{direction, dynamic([q], field(q, ^field))}]
    order_by(query, ^order_expr)
  end

  @doc """
  Sorts a query by an association’s field.

  Parameters:
    - query: The Ecto query.
    - binding_list: A list of binding atoms (e.g. `[:organization, :department]`).
      - or binding index
    - field: The field to sort on.
    - direction: The sort direction (:asc or :desc, default: :asc).
  """
  def by_association_field(query, binding_index, field, direction)
      when is_integer(binding_index) do
    if binding_index == 0 do
      query |> order_by([q], [{^direction, field(q, ^field)}])
    else
      arity = binding_index + 1
      query |> order_by_for_arity(arity, field, direction)
    end
  end

  def by_association_field(query, binding_list, field, direction)
      when is_list(binding_list) do
    candidate_bindings = QueryJoiner.NamedBinding.find_all(query, binding_list)

    case List.last(candidate_bindings) do
      {_binding_alias, binding_index, _join} ->
        by_association_field(query, binding_index, field, direction)

      nil ->
        raise ArgumentError, "No valid bindings found for aliases: #{inspect(binding_list)}"
    end
  end

  # Handles `order_by` dynamically for different join depths
  defp order_by_for_arity(query, arity, field, direction) do
    dynamic_expr =
      case arity do
        1 ->
          dynamic([q], field(q, ^field))

        2 ->
          dynamic([_a, q], field(q, ^field))

        3 ->
          dynamic([_a, _b, q], field(q, ^field))

        4 ->
          dynamic([_a, _b, _c, q], field(q, ^field))

        5 ->
          dynamic([_a, _b, _c, _d, q], field(q, ^field))

        6 ->
          dynamic([_a, _b, _c, _d, _e, q], field(q, ^field))

        7 ->
          dynamic([_a, _b, _c, _d, _e, _f, q], field(q, ^field))

        8 ->
          dynamic([_a, _b, _c, _d, _e, _f, _g, q], field(q, ^field))

        9 ->
          dynamic([_a, _b, _c, _d, _e, _f, _g, _h, q], field(q, ^field))

        10 ->
          dynamic([_a, _b, _c, _d, _e, _f, _g, _h, _i, q], field(q, ^field))

        11 ->
          dynamic([_a, _b, _c, _d, _e, _f, _g, _h, _i, _j, q], field(q, ^field))

        12 ->
          dynamic([_a, _b, _c, _d, _e, _f, _g, _h, _i, _j, _k, q], field(q, ^field))

        13 ->
          dynamic([_a, _b, _c, _d, _e, _f, _g, _h, _i, _j, _k, _l, q], field(q, ^field))

        14 ->
          dynamic([_a, _b, _c, _d, _e, _f, _g, _h, _i, _j, _k, _l, _m, q], field(q, ^field))

        15 ->
          dynamic([_a, _b, _c, _d, _e, _f, _g, _h, _i, _j, _k, _l, _m, _n, q], field(q, ^field))

        16 ->
          dynamic(
            [_a, _b, _c, _d, _e, _f, _g, _h, _i, _j, _k, _l, _m, _n, _o, q],
            field(q, ^field)
          )

        17 ->
          dynamic(
            [_a, _b, _c, _d, _e, _f, _g, _h, _i, _j, _k, _l, _m, _n, _o, _p, q],
            field(q, ^field)
          )

        18 ->
          dynamic(
            [_a, _b, _c, _d, _e, _f, _g, _h, _i, _j, _k, _l, _m, _n, _o, _p, _q, q],
            field(q, ^field)
          )

        19 ->
          dynamic(
            [_a, _b, _c, _d, _e, _f, _g, _h, _i, _j, _k, _l, _m, _n, _o, _p, _q, _r, q],
            field(q, ^field)
          )

        20 ->
          dynamic(
            [_a, _b, _c, _d, _e, _f, _g, _h, _i, _j, _k, _l, _m, _n, _o, _p, _q, _r, _s, q],
            field(q, ^field)
          )

        21 ->
          dynamic(
            [_a, _b, _c, _d, _e, _f, _g, _h, _i, _j, _k, _l, _m, _n, _o, _p, _q, _r, _s, _t, q],
            field(q, ^field)
          )

        _ ->
          raise ArgumentError, "Unsupported arity: #{arity}"
      end

    order_by(query, ^[{direction, dynamic_expr}])
  end
end
