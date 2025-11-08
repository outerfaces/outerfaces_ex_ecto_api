defmodule OuterfacesEctoApi.QueryEngine do
  @moduledoc """
  """

  require Logger

  alias OuterfacesEctoApi.QueryEngine.QueryAssociator
  alias OuterfacesEctoApi.QueryEngine.QueryBuilder
  alias OuterfacesEctoApi.QueryEngine.QueryPager

  @type repo :: Ecto.Repo.t()
  @type schema :: module()
  @type preload :: atom() | {atom(), [preload()]}
  @type filter_spec :: QueryBuilder.filter_spec()
  @type sort_spec :: QueryBuilder.sort_by_spec()
  @type params :: map()
  @type pagination_info :: QueryPager.pagination_info()
  @type paginated_success :: %{
          :status => pos_integer(),
          :results => %{
            :data => [map()],
            :page_info => pagination_info(),
            :schema => String.t()
          }
        }
  @type single_success :: %{
          :status => pos_integer(),
          :results => %{
            :data => map(),
            :schema => String.t(),
            :id => integer()
          }
        }
  @type error_response :: %{
          :status => pos_integer(),
          :results => %{
            :data => nil,
            :schema => String.t(),
            optional(:page_info) => pagination_info() | nil,
            optional(:id) => integer()
          },
          optional(:debug) => map()
        }

  @type all_response :: {:ok, paginated_success()} | {:error, error_response()}
  @type get_response :: {:ok, single_success()} | {:error, error_response()}

  @spec build(
          schema(),
          [filter_spec()],
          params(),
          Keyword.t()
        ) :: {:ok, Ecto.Query.t()} | {:error, atom()}
  def build(schema, filters, params, opts \\ []) when is_map(params) and is_list(opts) do
    queryable = Keyword.get(opts, :base_queryable, schema)
    sort_specs = Keyword.get(opts, :sort_specs, [])

    QueryBuilder.build_index_query(
      schema,
      queryable,
      %{"query" => Jason.encode!(params)},
      filters,
      sort_specs
    )
  end

  @spec all(
          repo(),
          schema(),
          [preload()],
          [filter_spec()],
          [sort_spec()],
          params(),
          Keyword.t()
        ) :: all_response()
  def all(
        repo,
        schema,
        preloads,
        filter_specs,
        sort_specs,
        params,
        opts \\ []
      ) do
    queryable = Keyword.get(opts, :base_queryable, schema)

    with {:ok, query} <-
           QueryBuilder.build_index_query(
             schema,
             queryable,
             params,
             filter_specs,
             sort_specs
           ),
         {:ok, count} <- do_aggregate_count(repo, query),
         {:ok, query} <- do_apply_paging(query, params),
         {:ok, records} <- do_query_all(repo, query),
         {:ok, records} <- do_preload_and_serialize(repo, records, preloads, opts) do
      {:ok,
       %{
         status: 200,
         results: %{
           data: records,
           page_info: QueryPager.compute_pagination(params, count),
           schema: format_schema_name(schema)
         }
       }}
    else
      {:error, error} ->
        message =
          """
          Schema: #{inspect(schema)}
          Preloads: #{inspect(preloads)}
          Filter Specs: #{inspect(filter_specs)}
          Params: #{inspect(params)}
          )
          """

        Logger.error("#{__MODULE__} Error: #{inspect(error)} \n #{message}")

        {:error,
         %{
           status: 500,
           results: %{
             data: nil,
             page_info: nil,
             schema: format_schema_name(schema)
           },
           debug: %{
             error: error |> to_string(),
             message: message
           }
         }}
    end
  end

  @spec do_apply_paging(Ecto.Query.t(), params()) ::
          {:ok, Ecto.Query.t()} | {:error, atom()}
  defp do_apply_paging(%Ecto.Query{} = query, params) do
    query
    |> QueryPager.apply_paging(params)
    |> then(&{:ok, &1})
  end

  defp do_apply_paging(_query, _params) do
    {:error, :query_all_construction_failure}
  end

  @spec do_query_all(repo(), Ecto.Query.t()) :: {:ok, [Ecto.Schema.t()]} | {:error, atom()}
  defp do_query_all(repo, query) do
    try do
      query
      |> repo.all()
      |> then(fn
        results when is_list(results) ->
          {:ok, results}

        _err ->
          {:error, :query_all_execution_failure}
      end)
    catch
      _err ->
        {:error, :query_all_execution_failure}
    end
  end

  @spec do_preload_and_serialize(
          repo(),
          Ecto.Queryable.t() | [Ecto.Schema.t()],
          [preload()],
          Keyword.t()
        ) ::
          {:ok, [map()]} | {:error, atom()}
  defp do_preload_and_serialize(repo, queryable, preloads, opts) do
    try do
      QueryAssociator.preload_and_serialize(repo, queryable, preloads, opts)
      |> then(&{:ok, &1})
    catch
      _ -> {:error, :query_preload_and_serialize_failure}
    end
  end

  @spec do_aggregate_count(repo(), Ecto.Query.t()) ::
          {:ok, integer()} | {:error, atom()}
  defp do_aggregate_count(repo, %Ecto.Query{} = query) do
    try do
      query
      |> repo.aggregate(:count, :id)
      |> then(fn
        count when is_integer(count) ->
          {:ok, count}

        _err ->
          {:error, :query_all_count_aggregation_failure}
      end)
    rescue
      _ -> {:error, :query_all_construction_error}
    catch
      _err ->
        {:error, :query_all_count_aggregation_failure}
    end
  end

  @spec get(repo(), schema(), [preload()], binary() | integer(), Keyword.t()) ::
          get_response()
  def get(repo, schema, id, preloads \\ [], opts \\ [])

  def get(repo, schema, id, preloads, opts) when is_binary(id) do
    get(repo, schema, String.to_integer(id), preloads, opts)
  end

  def get(repo, schema, id, preloads, opts) when is_integer(id) do
    with {:ok, record} <- do_get(repo, schema, id),
         {:ok, record} <- do_preload_and_serialize(repo, record, preloads, opts) do
      {:ok,
       %{
         status: 200,
         results: %{
           data: record,
           schema: format_schema_name(schema),
           id: id
         }
       }}
    else
      {:error, :query_get_no_result} ->
        {:error,
         %{
           status: 404,
           results: %{
             data: nil,
             schema: format_schema_name(schema),
             id: id
           }
         }}

      {:error, error} ->
        message =
          """
          Schema: #{inspect(schema)}
          ID: #{inspect(id)}
          Preloads: #{inspect(preloads)}
          """

        Logger.error("#{__MODULE__} Error: #{inspect(error)} \n #{message}")

        {:error,
         %{
           status: 500,
           results: %{
             data: nil,
             schema: format_schema_name(schema),
             id: id
           },
           debug: %{
             error: error |> to_string(),
             message: message
           }
         }}
    end
  end

  @spec format_schema_name(Ecto.Schema.t()) :: binary()
  defp format_schema_name(schema) do
    schema
    |> Atom.to_string()
  end

  @spec do_get(repo(), schema(), binary() | integer()) ::
          {:ok, map()} | {:error, atom()}
  defp do_get(repo, schema, id) when is_binary(id) do
    do_get(repo, schema, String.to_integer(id))
  end

  defp do_get(repo, schema, id) when is_integer(id) do
    queryable = QueryBuilder.ensure_queryable(schema, schema)

    try do
      repo.get(queryable, id)
      |> then(fn
        record when is_map(record) ->
          {:ok, record}

        _err ->
          {:error, :query_get_no_result}
      end)
    catch
      _err ->
        {:error, :query_get_failure}
    end
  end
end
