defmodule OuterfacesEctoApi.QueryEngine.QueryBuilder do
  @moduledoc """
  Provides dynamic filtering and query building for API endpoints.
  """
  alias OuterfacesEctoApi.QueryEngine.QueryJoiner
  import Ecto.Query

  require Logger

  @type field_filter_definition ::
          {
            # Module
            module(),
            # Function
            atom(),
            # Field name
            atom(),
            # Operation {truthy arg, falsy arg} | operation
            {atom(), atom()} | atom(),
            # run filter with nil values
            boolean()
          }
          | {
              # Module
              module(),
              # Function
              atom(),
              # Field name
              atom(),
              # Operation {truthy arg, falsy arg} | operation
              {atom(), atom()} | atom(),
              # run filter with nil values
              boolean(),
              # default value or default filter definition
              any()
            }

  @type association_field_filter_definition ::
          {
            # Module
            module(),
            # Function
            atom(),
            # Binding list or []
            [atom()],
            # Field name
            atom(),
            # Operation(s)
            {atom(), atom()} | atom(),
            # run filter with nil values
            boolean()
          }
          | {
              # Module
              module(),
              # Function
              atom(),
              # Binding list or []
              [atom()],
              # Field name
              atom(),
              # Operation(s)
              {atom(), atom()} | atom(),
              # run filter with nil values
              boolean(),
              # default value or default filter definition
              any()
            }

  @type filter_spec :: {
          # Filter key
          atom(),
          # Filter definition
          field_filter_definition() | association_field_filter_definition()
        }

  @type field_sort_by_definition ::
          {
            # Module
            module(),
            # Function
            atom(),
            # Binding list or []
            [atom()],
            # Field to sort on
            atom(),
            # direction :desc or :asc
            atom(),
            # default sort
            boolean()
          }
          | {
              # Module
              module(),
              # Function
              atom(),
              # Field to sort on
              atom(),
              # direction :desc or :asc
              atom(),
              # default sort
              boolean()
            }

  @type sort_by_spec :: {
          # Sort key
          atom(),
          # Sort definition
          field_sort_by_definition()
        }

  @spec build_index_query(
          schema :: module(),
          queryable :: Ecto.Queryable.t(),
          params :: map(),
          filter_specs :: [filter_spec()],
          sort_specs :: [sort_by_spec()]
        ) :: {:ok, Ecto.Query.t()} | {:error, atom()}
  def build_index_query(schema, queryable, params, filter_specs, sort_specs \\ []) do
    try do
      queryable = ensure_queryable(queryable, schema)

      query = Map.get(params, "query", "{}") |> Jason.decode!()
      filter_params = Map.get(query, "filters", %{})
      sort_params = Map.get(query, "sort", [])

      effective_sort = compute_effective_sort(sort_params, sort_specs)

      join_info =
        extract_needed_joins(filter_specs, schema, filter_params) ++
          extract_needed_joins_from_sorts(effective_sort, schema)

      queryable =
        case join_info do
          [] ->
            queryable

          [_ | _] = list_of_lists ->
            if is_list(hd(list_of_lists)) do
              Enum.reduce(list_of_lists, queryable, fn chain, acc_query ->
                QueryJoiner.ensure_joins(acc_query, chain)
              end)
            else
              QueryJoiner.ensure_joins(queryable, list_of_lists)
            end
        end

      queryable
      |> apply_filters(filter_params, filter_specs)
      |> apply_default_filters(filter_params, filter_specs)
      |> apply_sorting(effective_sort)
      |> then(&{:ok, &1})
    catch
      _ ->
        {:error, :query_builder_failure}
    end
  end

  defp compute_effective_sort(sort_params, sorting_defs) do
    allowed_sort_keys = Enum.map(sorting_defs, fn {key, _} -> key end)

    explicit_sorts =
      sort_params
      |> Enum.map(&parse_sort_param/1)
      |> Enum.filter(fn {key, _dir} -> key in allowed_sort_keys end)
      |> Enum.map(fn {key, dir} ->
        {key, lookup_sort_def(key, dir, sorting_defs)}
      end)

    if explicit_sorts == [] do
      Enum.filter(sorting_defs, fn
        {_, {_mod, _func, _bindings, _field, _dir, default}} -> default
        {_, {_mod, :by_field, _field, _dir, default}} -> default
        _ -> false
      end)
    else
      explicit_sorts
    end
  end

  defp lookup_sort_def(key, dir, sorting_defs) do
    sorting_defs
    |> Enum.find(fn {k, _} -> k == key end)
    |> case do
      {_, {mod, func, binding_list, field, _original_dir, default}} ->
        {mod, func, binding_list, field, dir, default}

      {_, {mod, :by_field, field, _original_dir, default}} ->
        {mod, :by_field, field, dir, default}

      {_, {mod, func, binding_list, field, _original_dir}} ->
        {mod, func, binding_list, field, dir}

      {_, {mod, :by_field, field, _original_dir}} ->
        {mod, :by_field, field, dir}

      _ ->
        raise ArgumentError, "Unexpected sorting definition for key: #{key}"
    end
  end

  defp parse_sort_param(param) do
    case String.split(param, ":") do
      [key, "desc"] ->
        {format_parameterized_sort(key), :desc}

      [key, "asc"] ->
        {format_parameterized_sort(key), :asc}

      [key] ->
        {format_parameterized_sort(key), :asc}
    end
  end

  defp format_parameterized_sort(key) when is_binary(key), do: String.to_existing_atom(key)

  defp apply_sorting(query, effective_sorts) do
    Enum.reduce(effective_sorts, query, fn
      {_sort_key, {mod, func, binding_list, field, direction, _default}}, acc_query ->
        apply(mod, func, [acc_query, binding_list, field, direction])

      {_sort_key, {mod, :by_field, field, direction, _default}}, acc_query ->
        apply(mod, :by_field, [acc_query, field, direction])

      {_sort_key, {mod, func, binding_list, field, direction}}, acc_query ->
        apply(mod, func, [acc_query, binding_list, field, direction])

      {_sort_key, {mod, :by_field, field, direction}}, acc_query ->
        apply(mod, :by_field, [acc_query, field, direction])
    end)
  end

  @spec ensure_queryable(Ecto.Queryable.t(), module()) :: Ecto.Query.t()
  def ensure_queryable(queryable, schema) do
    case queryable do
      mod when is_atom(mod) -> from(q in mod)
      %Ecto.Query{} = q -> q
      struct when is_map(struct) -> from(q in schema)
    end
  end

  @spec apply_filters(
          queryable :: Ecto.Queryable.t(),
          filter_params :: map(),
          filter_specs :: [filter_spec()]
        ) :: Ecto.Query.t()
  defp apply_filters(queryable, filter_params, filter_specs) do
    Enum.reduce(filter_params, queryable, fn
      {filter_key, filter_value}, acc ->
        apply_filter(acc, filter_key, filter_value, filter_specs)
    end)
  end

  @spec apply_filter(
          queryable :: Ecto.Queryable.t(),
          filter_key :: atom(),
          filter_value :: any(),
          filter_specs :: [filter_spec()]
        ) :: Ecto.Query.t()
  defp apply_filter(queryable, filter_key, filter_value, filter_specs) do
    case Enum.find(filter_specs, fn {key, _} -> Atom.to_string(key) == filter_key end) do
      nil ->
        queryable

      {_, {mod, func, binding_list, field, operator, allow_nil, _default}}
      when is_list(binding_list) ->
        validate_filter_field!(detect_target_schema(queryable, binding_list), field)
        resolved_operator = resolve_operator(operator, filter_value)

        expected_alias =
          binding_list
          |> Enum.map(&Atom.to_string/1)
          |> Enum.join("_")
          |> String.to_atom()

        case QueryJoiner.NamedBinding.find(queryable, expected_alias) do
          {binding_index, _join} ->
            cond do
              is_nil(filter_value) and allow_nil ->
                apply(mod, func, [queryable, nil, binding_index, field, resolved_operator])

              is_nil(filter_value) ->
                queryable

              true ->
                apply(mod, func, [
                  queryable,
                  filter_value,
                  binding_index,
                  field,
                  resolved_operator
                ])
            end

          nil ->
            raise ArgumentError,
                  "No valid binding found for expected alias: #{inspect(expected_alias)}"
        end

      {_, {mod, func, binding_list, field, operator, allow_nil}} when is_list(binding_list) ->
        validate_filter_field!(detect_target_schema(queryable, binding_list), field)
        resolved_operator = resolve_operator(operator, filter_value)

        expected_alias =
          binding_list
          |> Enum.map(&Atom.to_string/1)
          |> Enum.join("_")
          |> String.to_atom()

        case QueryJoiner.NamedBinding.find(queryable, expected_alias) do
          {binding_index, _join} ->
            cond do
              is_nil(filter_value) and allow_nil ->
                apply(mod, func, [queryable, nil, binding_index, field, resolved_operator])

              is_nil(filter_value) ->
                queryable

              true ->
                apply(mod, func, [
                  queryable,
                  filter_value,
                  binding_index,
                  field,
                  resolved_operator
                ])
            end

          nil ->
            raise ArgumentError,
                  "No valid binding found for expected alias: #{inspect(expected_alias)}"
        end

      {_, {mod, func, field, operator, allow_nil, _default}} when is_atom(field) ->
        validate_filter_field!(queryable, field)
        resolved_operator = resolve_operator(operator, filter_value)

        cond do
          is_nil(filter_value) and allow_nil ->
            apply(mod, func, [queryable, nil, field, resolved_operator])

          is_nil(filter_value) ->
            queryable

          true ->
            apply(mod, func, [queryable, filter_value, field, resolved_operator])
        end

      {_, {mod, func, field, operator, allow_nil}} when is_atom(field) ->
        validate_filter_field!(queryable, field)
        resolved_operator = resolve_operator(operator, filter_value)

        cond do
          is_nil(filter_value) and allow_nil ->
            apply(mod, func, [queryable, nil, field, resolved_operator])

          is_nil(filter_value) ->
            queryable

          true ->
            apply(mod, func, [queryable, filter_value, field, resolved_operator])
        end
    end
  end

  @spec resolve_operator(atom() | {atom(), atom()}, any()) :: atom()
  defp resolve_operator(operator, filter_value) do
    case {operator, filter_value} do
      {{true_case, _false_case}, true} -> true_case
      {{_true_case, false_case}, false} -> false_case
      _ -> operator
    end
  end

  defp detect_target_schema(queryable, []) do
    case queryable do
      %Ecto.Query{from: %{source: {_, schema}}} -> schema
      schema when is_atom(schema) -> schema
    end
  end

  defp detect_target_schema(queryable, binding_list) when is_list(binding_list) do
    base_schema = detect_target_schema(queryable, [])

    case expand_association_chain(base_schema, binding_list, []) do
      [] ->
        base_schema

      steps ->
        case List.last(steps) do
          {_, related_schema, _, _} -> related_schema
          _ -> base_schema
        end
    end
  end

  defp validate_filter_field!(queryable, field) do
    schema =
      case queryable do
        %Ecto.Query{from: %{source: {_, schema}}} -> schema
        schema when is_atom(schema) -> schema
        _ -> raise ArgumentError, "Unexpected queryable type: #{inspect(queryable)}"
      end

    unless field in apply(schema, :__schema__, [:fields]) do
      raise ArgumentError, "Field `#{field}` does not exist on schema `#{inspect(schema)}`"
    end
  end

  defp apply_default_filters(queryable, filter_params, filter_specs) do
    Enum.reduce(filter_specs, queryable, fn
      {filter_key, {mod, func, binding_list, field, operator, _allow_nil, default}}, acc ->
        if Map.has_key?(filter_params, Atom.to_string(filter_key)) do
          acc
        else
          case default do
            nil ->
              acc

            {default_mod, default_func, default_field, default_operator, default_value} ->
              apply(default_mod, default_func, [
                acc,
                default_value,
                default_field,
                default_operator
              ])

            literal ->
              effective_operator =
                case operator do
                  {true_op, false_op} ->
                    if literal, do: true_op, else: false_op

                  op when is_atom(op) ->
                    op
                end

              apply(mod, func, [acc, literal, binding_list, field, effective_operator])
          end
        end

      {filter_key, {mod, func, field, operator, allow_nil, default}}, acc ->
        if Map.has_key?(filter_params, Atom.to_string(filter_key)) do
          acc
        else
          case default do
            nil ->
              if allow_nil do
                effective_operator =
                  case operator do
                    {true_op, _false_op} ->
                      true_op

                    op when is_atom(op) ->
                      op
                  end

                apply(mod, func, [acc, nil, field, effective_operator])
              else
                acc
              end

            {default_mod, default_func, default_field, default_operator, default_value} ->
              apply(default_mod, default_func, [
                acc,
                default_value,
                default_field,
                default_operator
              ])

            literal ->
              effective_operator =
                case operator do
                  {true_op, false_op} ->
                    if literal, do: true_op, else: false_op

                  op when is_atom(op) ->
                    op
                end

              apply(mod, func, [acc, literal, field, effective_operator])
          end
        end

      # Handle 5-tuple field format without default (no-op since no default to apply)
      {filter_key, {_mod, _func, _field, _operator, _allow_nil}}, acc
      when is_atom(filter_key) ->
        acc
    end)
  end

  defp extract_needed_joins(filter_specs, schema, filter_params) do
    filter_specs
    |> Enum.reduce([], fn
      {filter_key, {_mod, _func, binding_list, _field, _operator, allow_nil, _default}}, acc
      when is_list(binding_list) and is_atom(filter_key) ->
        filter_value = Map.get(filter_params, Atom.to_string(filter_key))

        cond do
          is_nil(filter_value) and not allow_nil ->
            acc

          not Map.has_key?(filter_params, Atom.to_string(filter_key)) ->
            acc

          true ->
            case binding_list do
              list when is_list(list) -> [list | acc]
              atom when is_atom(atom) -> [[atom] | acc]
              _ -> acc
            end
        end

      {filter_key, {_mod, _func, binding_list, _field, _operator, allow_nil}}, acc
      when is_list(binding_list) and is_atom(filter_key) ->
        filter_value = Map.get(filter_params, Atom.to_string(filter_key))

        cond do
          is_nil(filter_value) and not allow_nil ->
            acc

          not Map.has_key?(filter_params, Atom.to_string(filter_key)) ->
            acc

          true ->
            case binding_list do
              list when is_list(list) -> [list | acc]
              atom when is_atom(atom) -> [[atom] | acc]
              _ -> acc
            end
        end

      {filter_key, {_mod, :by_field, _field, _operator, _allow_nil, _default}}, acc
      when is_atom(filter_key) ->
        acc

      {filter_key, {_mod, :by_field, _field, _operator, _allow_nil}}, acc
      when is_atom(filter_key) ->
        acc

      # Sort specs - always extract joins regardless of params
      {_sort_key, {_mod, _func, binding_list, _field, _direction, _default}}, acc ->
        case binding_list do
          list when is_list(list) -> [list | acc]
          atom when is_atom(atom) -> [[atom] | acc]
          _ -> acc
        end

      {_sort_key, {_mod, :by_field, _field, _direction, _default}}, acc ->
        acc

      {_sort_key, {_mod, _func, binding_list, _field, _direction}}, acc ->
        case binding_list do
          list when is_list(list) -> [list | acc]
          atom when is_atom(atom) -> [[atom] | acc]
          _ -> acc
        end

      {_sort_key, {_mod, :by_field, _field, _direction}}, acc ->
        acc

      unknown, acc ->
        Logger.warning("Unexpected filter / sort spec format: #{inspect(unknown)}")
        acc
    end)
    |> Enum.uniq()
    |> Enum.flat_map(fn binding_list ->
      [expand_association_chain(schema, binding_list, [])]
    end)
  end

  defp extract_needed_joins_from_sorts(effective_sorts, schema) do
    effective_sorts
    |> Enum.reduce([], fn
      {_sort_key, {_mod, _func, binding_list, _field, _direction, _default}}, acc
      when is_list(binding_list) ->
        [binding_list | acc]

      {_sort_key, {_mod, _func, binding_list, _field, _direction}}, acc
      when is_list(binding_list) ->
        [binding_list | acc]

      _, acc ->
        acc
    end)
    |> Enum.uniq()
    |> Enum.flat_map(fn binding_list ->
      [expand_association_chain(schema, binding_list, [])]
    end)
  end

  defp expand_association_chain(current_schema, [assoc_name | rest], acc) do
    steps = get_association_info(current_schema, assoc_name)

    case steps do
      [] ->
        acc

      [{_, next_schema, _, _} = step] ->
        expand_association_chain(next_schema, rest, acc ++ [step])
    end
  end

  defp expand_association_chain(_schema, [], acc), do: acc

  defp get_association_info(schema, assoc_name) do
    case schema.__schema__(:association, assoc_name) do
      %Ecto.Association.Has{related: rs, owner_key: ok, related_key: rk} ->
        [{assoc_name, rs, ok, rk}]

      %Ecto.Association.BelongsTo{related: rs, owner_key: ok, related_key: rk} ->
        [{assoc_name, rs, ok, rk}]

      %Ecto.Association.HasThrough{through: through_list} ->
        expand_through_association(schema, through_list, [])

      nil ->
        []
    end
  end

  defp expand_through_association(_schema, [], acc), do: acc

  defp expand_through_association(schema, [assoc_name | rest], acc) do
    steps = get_association_info(schema, assoc_name)

    case steps do
      [] ->
        expand_through_association(schema, rest, acc)

      _ ->
        new_schema =
          case List.last(steps) do
            {_, related_schema, _, _} -> related_schema
            nil -> schema
          end

        expand_through_association(new_schema, rest, acc ++ steps)
    end
  end
end
