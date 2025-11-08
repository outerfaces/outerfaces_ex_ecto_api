defmodule OuterfacesEctoApi.QueryEngine.QueryPager do
  import Ecto.Query

  @type pagination_info :: %{
          total_count: non_neg_integer(),
          total_pages: pos_integer(),
          has_next_page: boolean(),
          has_previous_page: boolean(),
          limit: non_neg_integer(),
          offset: non_neg_integer()
        }

  @doc """
  Applies ordering, limit, and offset to a given query.

  Parameters:
    - query: The Ecto query.
    - params: A map containing "limit", and "offset".

  Example usage:
    QueryPager.apply_paging(query, %{"limit" => 10, "offset" => 20})
  """
  @spec apply_paging(Ecto.Query.t(), map()) :: Ecto.Query.t()
  def apply_paging(query, params) do
    params = Map.get(params, "query", "{}") |> Jason.decode!()

    query
    |> apply_limit(params)
    |> apply_offset(params)
  end

  defp apply_limit(query, %{"limit" => limit}) when is_integer(limit) do
    limit(query, ^limit)
  end

  defp apply_limit(query, _), do: query

  defp apply_offset(query, %{"offset" => offset}) when is_integer(offset) do
    offset(query, ^offset)
  end

  defp apply_offset(query, _), do: query

  @spec compute_pagination(map(), non_neg_integer()) :: pagination_info()
  def compute_pagination(params, total_count) do
    params = Map.get(params, "query", "{}") |> Jason.decode!()
    limit = parse_integer(params["limit"]) || 10
    offset = parse_integer(params["offset"]) || 0

    total_pages = compute_total_pages(total_count, limit)
    has_next_page = offset + limit < total_count
    has_previous_page = offset > 0

    %{
      total_count: total_count,
      total_pages: total_pages,
      has_next_page: has_next_page,
      has_previous_page: has_previous_page,
      limit: limit,
      offset: offset
    }
  end

  defp compute_total_pages(total_count, limit) when total_count > 0 do
    Float.ceil(total_count / limit) |> trunc()
  end

  defp compute_total_pages(_total_count, _limit), do: 1

  defp parse_integer(nil), do: nil
  defp parse_integer(value) when is_binary(value), do: String.to_integer(value)
  defp parse_integer(value), do: value
end
