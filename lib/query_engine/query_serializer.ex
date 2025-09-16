defmodule OuterfacesEctoApi.QueryEngine.QuerySerializer do
  @doc """
  This module provides a macro to be used in API models to serialize the model's fields.
  """
  defmacro __using__(_opts) do
    quote do
      def serializer_skip_fields(_opts), do: []

      def do_serialize_field(_field, value, _opts) do
        value
      end

      def pre_serialize(field_or_struct, preload_fields \\ [], opts \\ [])

      def pre_serialize(field, _preload_fields, _opts) when not is_struct(field) do
        field
      end

      def pre_serialize(struct, preload_fields, opts) do
        schema_module = struct.__struct__

        schema_fields =
          schema_module.__schema__(:fields)
          |> Enum.reject(&(&1 in serializer_skip_fields(opts)))

        result =
          Enum.reduce(schema_fields, %{}, fn field, acc ->
            value = Map.get(struct, field)
            serialized_value = do_serialize_field(field, value, opts)
            Map.put(acc, field, serialized_value)
          end)

        OuterfacesEctoApi.QueryEngine.QueryAssociator.pre_serialize_fields(
          result,
          struct,
          preload_fields,
          opts
        )
      end

      defoverridable serializer_skip_fields: 1,
                     do_serialize_field: 3
    end
  end
end
