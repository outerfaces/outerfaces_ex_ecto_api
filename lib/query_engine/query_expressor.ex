defmodule OuterfacesEctoApi.QueryEngine.QueryExpressor do
  @doc """
  Builds a dynamic expression for filtering an associated field, supporting multiple levels of joins.

  - `arity`: 1 for `[assoc]`, 2 for `[_a, assoc]`, etc.
  - `operator`: `:==`, `:!=`, `:>`, `:<`, `:>=`, `:<=`, `:is_nil`, `:not_nil`, :in, :not_in.
  - `field`: Atom for the field to filter on.
  - `value`: The compare value, or nil if ignoring for `is_nil` checks.
  """
  import Ecto.Query

  # ---- ARITY: 1 ----
  # is_nil / not_nil
  def build_dynamic(1, :is_nil, field, _value),
    do: dynamic([assoc], is_nil(field(assoc, ^field)))

  def build_dynamic(1, :not_nil, field, _value),
    do: dynamic([assoc], not is_nil(field(assoc, ^field)))

  # = / != with nil
  def build_dynamic(1, :==, field, nil),
    do: dynamic([assoc], is_nil(field(assoc, ^field)))

  def build_dynamic(1, :!=, field, nil),
    do: dynamic([assoc], not is_nil(field(assoc, ^field)))

  # = / != with non-nil
  def build_dynamic(1, :==, field, value),
    do: dynamic([assoc], field(assoc, ^field) == ^value)

  def build_dynamic(1, :!=, field, value),
    do: dynamic([assoc], field(assoc, ^field) != ^value)

  # > / < / >= / <= with nil => raise error
  def build_dynamic(1, op, _field, nil) when op in [:>, :<, :>=, :<=, :in, :not_in],
    do:
      raise(
        ArgumentError,
        "Cannot compare with nil using #{op}.
       Use :is_nil or :not_nil instead."
      )

  # > / < / >= / <= with non-nil
  def build_dynamic(1, :>, field, value),
    do: dynamic([assoc], field(assoc, ^field) > ^value)

  def build_dynamic(1, :<, field, value),
    do: dynamic([assoc], field(assoc, ^field) < ^value)

  def build_dynamic(1, :>=, field, value),
    do: dynamic([assoc], field(assoc, ^field) >= ^value)

  def build_dynamic(1, :<=, field, value),
    do: dynamic([assoc], field(assoc, ^field) <= ^value)

  def build_dynamic(1, :in, field, value) when is_list(value),
    do: dynamic([assoc], field(assoc, ^field) in ^value)

  def build_dynamic(1, :not_in, field, value) when is_list(value),
    do: dynamic([assoc], field(assoc, ^field) not in ^value)

  # ---- ARITY: 2 ----
  # is_nil / not_nil
  def build_dynamic(2, :is_nil, field, _value),
    do: dynamic([_a, assoc], is_nil(field(assoc, ^field)))

  def build_dynamic(2, :not_nil, field, _value),
    do: dynamic([_a, assoc], not is_nil(field(assoc, ^field)))

  # = / != with nil
  def build_dynamic(2, :==, field, nil),
    do: dynamic([_a, assoc], is_nil(field(assoc, ^field)))

  def build_dynamic(2, :!=, field, nil),
    do: dynamic([_a, assoc], not is_nil(field(assoc, ^field)))

  # = / != with non-nil
  def build_dynamic(2, :==, field, value),
    do: dynamic([_a, assoc], field(assoc, ^field) == ^value)

  def build_dynamic(2, :!=, field, value),
    do: dynamic([_a, assoc], field(assoc, ^field) != ^value)

  # > / < / >= / <= with nil => error
  def build_dynamic(2, op, _field, nil) when op in [:>, :<, :>=, :<=, :in, :not_in],
    do:
      raise(
        ArgumentError,
        "Cannot compare with nil using #{op}.
               Use :is_nil or :not_nil instead."
      )

  # > / < / >= / <= with non-nil
  def build_dynamic(2, :>, field, value),
    do: dynamic([_a, assoc], field(assoc, ^field) > ^value)

  def build_dynamic(2, :<, field, value),
    do: dynamic([_a, assoc], field(assoc, ^field) < ^value)

  def build_dynamic(2, :>=, field, value),
    do: dynamic([_a, assoc], field(assoc, ^field) >= ^value)

  def build_dynamic(2, :<=, field, value),
    do: dynamic([_a, assoc], field(assoc, ^field) <= ^value)

  def build_dynamic(2, :in, field, value) when is_list(value),
    do: dynamic([_a, assoc], field(assoc, ^field) in ^value)

  def build_dynamic(2, :not_in, field, value) when is_list(value),
    do: dynamic([_a, assoc], field(assoc, ^field) not in ^value)

  # ---- ARITY: 3 ----
  def build_dynamic(3, :is_nil, field, _value),
    do: dynamic([_a, _b, assoc], is_nil(field(assoc, ^field)))

  def build_dynamic(3, :not_nil, field, _value),
    do: dynamic([_a, _b, assoc], not is_nil(field(assoc, ^field)))

  def build_dynamic(3, :==, field, nil),
    do: dynamic([_a, _b, assoc], is_nil(field(assoc, ^field)))

  def build_dynamic(3, :!=, field, nil),
    do: dynamic([_a, _b, assoc], not is_nil(field(assoc, ^field)))

  def build_dynamic(3, :==, field, value),
    do: dynamic([_a, _b, assoc], field(assoc, ^field) == ^value)

  def build_dynamic(3, :!=, field, value),
    do: dynamic([_a, _b, assoc], field(assoc, ^field) != ^value)

  def build_dynamic(3, op, _field, nil) when op in [:>, :<, :>=, :<=, :in, :not_in],
    do:
      raise(
        ArgumentError,
        "Cannot compare with nil using #{op}.
               Use :is_nil or :not_nil instead."
      )

  def build_dynamic(3, :>, field, value),
    do: dynamic([_a, _b, assoc], field(assoc, ^field) > ^value)

  def build_dynamic(3, :<, field, value),
    do: dynamic([_a, _b, assoc], field(assoc, ^field) < ^value)

  def build_dynamic(3, :>=, field, value),
    do: dynamic([_a, _b, assoc], field(assoc, ^field) >= ^value)

  def build_dynamic(3, :<=, field, value),
    do: dynamic([_a, _b, assoc], field(assoc, ^field) <= ^value)

  def build_dynamic(3, :in, field, value) when is_list(value),
    do: dynamic([_a, _b, assoc], field(assoc, ^field) in ^value)

  def build_dynamic(3, :not_in, field, value) when is_list(value),
    do: dynamic([_a, _b, assoc], field(assoc, ^field) not in ^value)

  # ---- ARITY: 4 ----
  def build_dynamic(4, :is_nil, field, _value),
    do: dynamic([_a, _b, _c, assoc], is_nil(field(assoc, ^field)))

  def build_dynamic(4, :not_nil, field, _value),
    do: dynamic([_a, _b, _c, assoc], not is_nil(field(assoc, ^field)))

  def build_dynamic(4, :==, field, nil),
    do: dynamic([_a, _b, _c, assoc], is_nil(field(assoc, ^field)))

  def build_dynamic(4, :!=, field, nil),
    do: dynamic([_a, _b, _c, assoc], not is_nil(field(assoc, ^field)))

  def build_dynamic(4, :==, field, value),
    do: dynamic([_a, _b, _c, assoc], field(assoc, ^field) == ^value)

  def build_dynamic(4, :!=, field, value),
    do: dynamic([_a, _b, _c, assoc], field(assoc, ^field) != ^value)

  def build_dynamic(4, op, _field, nil) when op in [:>, :<, :>=, :<=, :in, :not_in],
    do:
      raise(
        ArgumentError,
        "Cannot compare with nil using #{op}.
               Use :is_nil or :not_nil instead."
      )

  def build_dynamic(4, :>, field, value),
    do: dynamic([_a, _b, _c, assoc], field(assoc, ^field) > ^value)

  def build_dynamic(4, :<, field, value),
    do: dynamic([_a, _b, _c, assoc], field(assoc, ^field) < ^value)

  def build_dynamic(4, :>=, field, value),
    do: dynamic([_a, _b, _c, assoc], field(assoc, ^field) >= ^value)

  def build_dynamic(4, :<=, field, value),
    do: dynamic([_a, _b, _c, assoc], field(assoc, ^field) <= ^value)

  def build_dynamic(4, :in, field, value) when is_list(value),
    do: dynamic([_a, _b, _c, assoc], field(assoc, ^field) in ^value)

  def build_dynamic(4, :not_in, field, value) when is_list(value),
    do: dynamic([_a, _b, _c, assoc], field(assoc, ^field) not in ^value)

  # ---- ARITY: 5 ----
  def build_dynamic(5, :is_nil, field, _value),
    do: dynamic([_a, _b, _c, _d, assoc], is_nil(field(assoc, ^field)))

  def build_dynamic(5, :not_nil, field, _value),
    do: dynamic([_a, _b, _c, _d, assoc], not is_nil(field(assoc, ^field)))

  def build_dynamic(5, :==, field, nil),
    do: dynamic([_a, _b, _c, _d, assoc], is_nil(field(assoc, ^field)))

  def build_dynamic(5, :!=, field, nil),
    do: dynamic([_a, _b, _c, _d, assoc], not is_nil(field(assoc, ^field)))

  def build_dynamic(5, :==, field, value),
    do: dynamic([_a, _b, _c, _d, assoc], field(assoc, ^field) == ^value)

  def build_dynamic(5, :!=, field, value),
    do: dynamic([_a, _b, _c, _d, assoc], field(assoc, ^field) != ^value)

  def build_dynamic(5, op, _field, nil) when op in [:>, :<, :>=, :<=, :in, :not_in],
    do:
      raise(
        ArgumentError,
        "Cannot compare with nil using #{op}.
               Use :is_nil or :not_nil instead."
      )

  def build_dynamic(5, :>, field, value),
    do: dynamic([_a, _b, _c, _d, assoc], field(assoc, ^field) > ^value)

  def build_dynamic(5, :<, field, value),
    do: dynamic([_a, _b, _c, _d, assoc], field(assoc, ^field) < ^value)

  def build_dynamic(5, :>=, field, value),
    do: dynamic([_a, _b, _c, _d, assoc], field(assoc, ^field) >= ^value)

  def build_dynamic(5, :<=, field, value),
    do: dynamic([_a, _b, _c, _d, assoc], field(assoc, ^field) <= ^value)

  def build_dynamic(5, :in, field, value) when is_list(value),
    do: dynamic([_a, _b, _c, _d, assoc], field(assoc, ^field) in ^value)

  def build_dynamic(5, :not_in, field, value) when is_list(value),
    do: dynamic([_a, _b, _c, _d, assoc], field(assoc, ^field) not in ^value)

  # ---- ARITY: 6 ----
  def build_dynamic(6, :is_nil, field, _value),
    do: dynamic([_a, _b, _c, _d, _e, assoc], is_nil(field(assoc, ^field)))

  def build_dynamic(6, :not_nil, field, _value),
    do: dynamic([_a, _b, _c, _d, _e, assoc], not is_nil(field(assoc, ^field)))

  def build_dynamic(6, :==, field, nil),
    do: dynamic([_a, _b, _c, _d, _e, assoc], is_nil(field(assoc, ^field)))

  def build_dynamic(6, :!=, field, nil),
    do: dynamic([_a, _b, _c, _d, _e, assoc], not is_nil(field(assoc, ^field)))

  def build_dynamic(6, :==, field, value),
    do: dynamic([_a, _b, _c, _d, _e, assoc], field(assoc, ^field) == ^value)

  def build_dynamic(6, :!=, field, value),
    do: dynamic([_a, _b, _c, _d, _e, assoc], field(assoc, ^field) != ^value)

  def build_dynamic(6, op, _field, nil) when op in [:>, :<, :>=, :<=, :in, :not_in],
    do:
      raise(
        ArgumentError,
        "Cannot compare with nil using #{op}.
               Use :is_nil or :not_nil instead."
      )

  def build_dynamic(6, :>, field, value),
    do: dynamic([_a, _b, _c, _d, _e, assoc], field(assoc, ^field) > ^value)

  def build_dynamic(6, :<, field, value),
    do: dynamic([_a, _b, _c, _d, _e, assoc], field(assoc, ^field) < ^value)

  def build_dynamic(6, :>=, field, value),
    do: dynamic([_a, _b, _c, _d, _e, assoc], field(assoc, ^field) >= ^value)

  def build_dynamic(6, :<=, field, value),
    do: dynamic([_a, _b, _c, _d, _e, assoc], field(assoc, ^field) <= ^value)

  def build_dynamic(6, :in, field, value) when is_list(value),
    do: dynamic([_a, _b, _c, _d, _e, assoc], field(assoc, ^field) in ^value)

  def build_dynamic(6, :not_in, field, value) when is_list(value),
    do: dynamic([_a, _b, _c, _d, _e, assoc], field(assoc, ^field) not in ^value)

  # ---- ARITY: 7 ----
  def build_dynamic(7, :is_nil, field, _value),
    do: dynamic([_a, _b, _c, _d, _e, _f, assoc], is_nil(field(assoc, ^field)))

  def build_dynamic(7, :not_nil, field, _value),
    do: dynamic([_a, _b, _c, _d, _e, _f, assoc], not is_nil(field(assoc, ^field)))

  def build_dynamic(7, :==, field, nil),
    do: dynamic([_a, _b, _c, _d, _e, _f, assoc], is_nil(field(assoc, ^field)))

  def build_dynamic(7, :!=, field, nil),
    do: dynamic([_a, _b, _c, _d, _e, _f, assoc], not is_nil(field(assoc, ^field)))

  def build_dynamic(7, :==, field, value),
    do: dynamic([_a, _b, _c, _d, _e, _f, assoc], field(assoc, ^field) == ^value)

  def build_dynamic(7, :!=, field, value),
    do: dynamic([_a, _b, _c, _d, _e, _f, assoc], field(assoc, ^field) != ^value)

  def build_dynamic(7, op, _field, nil) when op in [:>, :<, :>=, :<=, :in, :not_in],
    do:
      raise(
        ArgumentError,
        "Cannot compare with nil using #{op}.
               Use :is_nil or :not_nil instead."
      )

  def build_dynamic(7, :>, field, value),
    do: dynamic([_a, _b, _c, _d, _e, _f, assoc], field(assoc, ^field) > ^value)

  def build_dynamic(7, :<, field, value),
    do: dynamic([_a, _b, _c, _d, _e, _f, assoc], field(assoc, ^field) < ^value)

  def build_dynamic(7, :>=, field, value),
    do: dynamic([_a, _b, _c, _d, _e, _f, assoc], field(assoc, ^field) >= ^value)

  def build_dynamic(7, :<=, field, value),
    do: dynamic([_a, _b, _c, _d, _e, _f, assoc], field(assoc, ^field) <= ^value)

  def build_dynamic(7, :in, field, value) when is_list(value),
    do: dynamic([_a, _b, _c, _d, _e, _f, assoc], field(assoc, ^field) in ^value)

  def build_dynamic(7, :not_in, field, value) when is_list(value),
    do: dynamic([_a, _b, _c, _d, _e, _f, assoc], field(assoc, ^field) not in ^value)

  # ---- ARITY: 8 ----

  def build_dynamic(8, :is_nil, field, _value),
    do: dynamic([_a, _b, _c, _d, _e, _f, _g, assoc], is_nil(field(assoc, ^field)))

  def build_dynamic(8, :not_nil, field, _value),
    do: dynamic([_a, _b, _c, _d, _e, _f, _g, assoc], not is_nil(field(assoc, ^field)))

  def build_dynamic(8, :==, field, nil),
    do: dynamic([_a, _b, _c, _d, _e, _f, _g, assoc], is_nil(field(assoc, ^field)))

  def build_dynamic(8, :!=, field, nil),
    do: dynamic([_a, _b, _c, _d, _e, _f, _g, assoc], not is_nil(field(assoc, ^field)))

  def build_dynamic(8, :==, field, value),
    do: dynamic([_a, _b, _c, _d, _e, _f, _g, assoc], field(assoc, ^field) == ^value)

  def build_dynamic(8, :!=, field, value),
    do: dynamic([_a, _b, _c, _d, _e, _f, _g, assoc], field(assoc, ^field) != ^value)

  def build_dynamic(8, op, _field, nil) when op in [:>, :<, :>=, :<=, :in, :not_in],
    do:
      raise(
        ArgumentError,
        "Cannot compare with nil using #{op}.
               Use :is_nil or :not_nil instead."
      )

  def build_dynamic(8, :>, field, value),
    do: dynamic([_a, _b, _c, _d, _e, _f, _g, assoc], field(assoc, ^field) > ^value)

  def build_dynamic(8, :<, field, value),
    do: dynamic([_a, _b, _c, _d, _e, _f, _g, assoc], field(assoc, ^field) < ^value)

  def build_dynamic(8, :>=, field, value),
    do: dynamic([_a, _b, _c, _d, _e, _f, _g, assoc], field(assoc, ^field) >= ^value)

  def build_dynamic(8, :<=, field, value),
    do: dynamic([_a, _b, _c, _d, _e, _f, _g, assoc], field(assoc, ^field) <= ^value)

  def build_dynamic(8, :in, field, value) when is_list(value),
    do: dynamic([_a, _b, _c, _d, _e, _f, _g, assoc], field(assoc, ^field) in ^value)

  def build_dynamic(8, :not_in, field, value) when is_list(value),
    do: dynamic([_a, _b, _c, _d, _e, _f, _g, assoc], field(assoc, ^field) not in ^value)

  # ---- ARITY: 9 ----

  def build_dynamic(9, :is_nil, field, _value),
    do: dynamic([_a, _b, _c, _d, _e, _f, _g, _h, assoc], is_nil(field(assoc, ^field)))

  def build_dynamic(9, :not_nil, field, _value),
    do: dynamic([_a, _b, _c, _d, _e, _f, _g, _h, assoc], not is_nil(field(assoc, ^field)))

  def build_dynamic(9, :==, field, nil),
    do: dynamic([_a, _b, _c, _d, _e, _f, _g, _h, assoc], is_nil(field(assoc, ^field)))

  def build_dynamic(9, :!=, field, nil),
    do: dynamic([_a, _b, _c, _d, _e, _f, _g, _h, assoc], not is_nil(field(assoc, ^field)))

  def build_dynamic(9, :==, field, value),
    do: dynamic([_a, _b, _c, _d, _e, _f, _g, _h, assoc], field(assoc, ^field) == ^value)

  def build_dynamic(9, :!=, field, value),
    do: dynamic([_a, _b, _c, _d, _e, _f, _g, _h, assoc], field(assoc, ^field) != ^value)

  def build_dynamic(9, op, _field, nil) when op in [:>, :<, :>=, :<=, :in, :not_in],
    do:
      raise(
        ArgumentError,
        "Cannot compare with nil using #{op}.
               Use :is_nil or :not_nil instead."
      )

  def build_dynamic(9, :>, field, value),
    do: dynamic([_a, _b, _c, _d, _e, _f, _g, _h, assoc], field(assoc, ^field) > ^value)

  def build_dynamic(9, :<, field, value),
    do: dynamic([_a, _b, _c, _d, _e, _f, _g, _h, assoc], field(assoc, ^field) < ^value)

  def build_dynamic(9, :>=, field, value),
    do: dynamic([_a, _b, _c, _d, _e, _f, _g, _h, assoc], field(assoc, ^field) >= ^value)

  def build_dynamic(9, :<=, field, value),
    do: dynamic([_a, _b, _c, _d, _e, _f, _g, _h, assoc], field(assoc, ^field) <= ^value)

  def build_dynamic(9, :in, field, value) when is_list(value),
    do: dynamic([_a, _b, _c, _d, _e, _f, _g, _h, assoc], field(assoc, ^field) in ^value)

  # ---- ARITY: 10 ----

  def build_dynamic(10, :is_nil, field, _value),
    do: dynamic([_a, _b, _c, _d, _e, _f, _g, _h, assoc], is_nil(field(assoc, ^field)))

  def build_dynamic(10, :not_nil, field, _value),
    do: dynamic([_a, _b, _c, _d, _e, _f, _g, _h, assoc], not is_nil(field(assoc, ^field)))

  def build_dynamic(10, :==, field, nil),
    do: dynamic([_a, _b, _c, _d, _e, _f, _g, _h, assoc], is_nil(field(assoc, ^field)))

  def build_dynamic(10, :!=, field, nil),
    do: dynamic([_a, _b, _c, _d, _e, _f, _g, _h, assoc], not is_nil(field(assoc, ^field)))

  def build_dynamic(10, :==, field, value),
    do: dynamic([_a, _b, _c, _d, _e, _f, _g, _h, assoc], field(assoc, ^field) == ^value)

  def build_dynamic(10, :!=, field, value),
    do: dynamic([_a, _b, _c, _d, _e, _f, _g, _h, assoc], field(assoc, ^field) != ^value)

  def build_dynamic(10, op, _field, nil) when op in [:>, :<, :>=, :<=, :in, :not_in],
    do:
      raise(
        ArgumentError,
        "Cannot compare with nil using #{op}.
               Use :is_nil or :not_nil instead."
      )

  def build_dynamic(10, :>, field, value),
    do: dynamic([_a, _b, _c, _d, _e, _f, _g, _h, assoc], field(assoc, ^field) > ^value)

  def build_dynamic(10, :<, field, value),
    do: dynamic([_a, _b, _c, _d, _e, _f, _g, _h, assoc], field(assoc, ^field) < ^value)

  def build_dynamic(10, :>=, field, value),
    do: dynamic([_a, _b, _c, _d, _e, _f, _g, _h, assoc], field(assoc, ^field) >= ^value)

  def build_dynamic(10, :<=, field, value),
    do: dynamic([_a, _b, _c, _d, _e, _f, _g, _h, assoc], field(assoc, ^field) <= ^value)

  def build_dynamic(10, :in, field, value) when is_list(value),
    do: dynamic([_a, _b, _c, _d, _e, _f, _g, _h, assoc], field(assoc, ^field) in ^value)

  def build_dynamic(10, :not_in, field, value) when is_list(value),
    do: dynamic([_a, _b, _c, _d, _e, _f, _g, _h, assoc], field(assoc, ^field) not in ^value)

  # ---- ARITY: 11 ----
  def build_dynamic(11, :is_nil, field, _value),
    do: dynamic([_a, _b, _c, _d, _e, _f, _g, _h, _i, assoc], is_nil(field(assoc, ^field)))

  def build_dynamic(11, :not_nil, field, _value),
    do: dynamic([_a, _b, _c, _d, _e, _f, _g, _h, _i, assoc], not is_nil(field(assoc, ^field)))

  def build_dynamic(11, :==, field, nil),
    do: dynamic([_a, _b, _c, _d, _e, _f, _g, _h, _i, assoc], is_nil(field(assoc, ^field)))

  def build_dynamic(11, :!=, field, nil),
    do: dynamic([_a, _b, _c, _d, _e, _f, _g, _h, _i, assoc], not is_nil(field(assoc, ^field)))

  def build_dynamic(11, :==, field, value),
    do: dynamic([_a, _b, _c, _d, _e, _f, _g, _h, _i, assoc], field(assoc, ^field) == ^value)

  def build_dynamic(11, :!=, field, value),
    do: dynamic([_a, _b, _c, _d, _e, _f, _g, _h, _i, assoc], field(assoc, ^field) != ^value)

  def build_dynamic(11, op, _field, nil) when op in [:>, :<, :>=, :<=, :in, :not_in],
    do:
      raise(
        ArgumentError,
        "Cannot compare with nil using #{op}.
               Use :is_nil or :not_nil instead."
      )

  def build_dynamic(11, :>, field, value),
    do: dynamic([_a, _b, _c, _d, _e, _f, _g, _h, _i, assoc], field(assoc, ^field) > ^value)

  def build_dynamic(11, :<, field, value),
    do: dynamic([_a, _b, _c, _d, _e, _f, _g, _h, _i, assoc], field(assoc, ^field) < ^value)

  def build_dynamic(11, :>=, field, value),
    do: dynamic([_a, _b, _c, _d, _e, _f, _g, _h, _i, assoc], field(assoc, ^field) >= ^value)

  def build_dynamic(11, :<=, field, value),
    do: dynamic([_a, _b, _c, _d, _e, _f, _g, _h, _i, assoc], field(assoc, ^field) <= ^value)

  def build_dynamic(11, :in, field, value) when is_list(value),
    do: dynamic([_a, _b, _c, _d, _e, _f, _g, _h, _i, assoc], field(assoc, ^field) in ^value)

  def build_dynamic(11, :not_in, field, value) when is_list(value),
    do: dynamic([_a, _b, _c, _d, _e, _f, _g, _h, _i, assoc], field(assoc, ^field) not in ^value)

  # ---- ARITY: 12 ----
  def build_dynamic(12, :is_nil, field, _value),
    do: dynamic([_a, _b, _c, _d, _e, _f, _g, _h, _i, _j, assoc], is_nil(field(assoc, ^field)))

  def build_dynamic(12, :not_nil, field, _value),
    do: dynamic([_a, _b, _c, _d, _e, _f, _g, _h, _i, _j, assoc], not is_nil(field(assoc, ^field)))

  def build_dynamic(12, :==, field, nil),
    do: dynamic([_a, _b, _c, _d, _e, _f, _g, _h, _i, _j, assoc], is_nil(field(assoc, ^field)))

  def build_dynamic(12, :!=, field, nil),
    do: dynamic([_a, _b, _c, _d, _e, _f, _g, _h, _i, _j, assoc], not is_nil(field(assoc, ^field)))

  def build_dynamic(12, :==, field, value),
    do: dynamic([_a, _b, _c, _d, _e, _f, _g, _h, _i, _j, assoc], field(assoc, ^field) == ^value)

  def build_dynamic(12, :!=, field, value),
    do: dynamic([_a, _b, _c, _d, _e, _f, _g, _h, _i, _j, assoc], field(assoc, ^field) != ^value)

  def build_dynamic(12, op, _field, nil) when op in [:>, :<, :>=, :<=, :in, :not_in],
    do:
      raise(
        ArgumentError,
        "Cannot compare with nil using #{op}.
               Use :is_nil or :not_nil instead."
      )

  def build_dynamic(12, :>, field, value),
    do: dynamic([_a, _b, _c, _d, _e, _f, _g, _h, _i, _j, assoc], field(assoc, ^field) > ^value)

  def build_dynamic(12, :<, field, value),
    do: dynamic([_a, _b, _c, _d, _e, _f, _g, _h, _i, _j, assoc], field(assoc, ^field) < ^value)

  def build_dynamic(12, :>=, field, value),
    do: dynamic([_a, _b, _c, _d, _e, _f, _g, _h, _i, _j, assoc], field(assoc, ^field) >= ^value)

  def build_dynamic(12, :<=, field, value),
    do: dynamic([_a, _b, _c, _d, _e, _f, _g, _h, _i, _j, assoc], field(assoc, ^field) <= ^value)

  def build_dynamic(12, :in, field, value) when is_list(value),
    do: dynamic([_a, _b, _c, _d, _e, _f, _g, _h, _i, _j, assoc], field(assoc, ^field) in ^value)

  def build_dynamic(12, :not_in, field, value) when is_list(value),
    do:
      dynamic([_a, _b, _c, _d, _e, _f, _g, _h, _i, _j, assoc], field(assoc, ^field) not in ^value)

  # ---- ARITY: 13 ----
  def build_dynamic(13, :is_nil, field, _value),
    do: dynamic([_a, _b, _c, _d, _e, _f, _g, _h, _i, _j, _k, assoc], is_nil(field(assoc, ^field)))

  def build_dynamic(13, :not_nil, field, _value),
    do:
      dynamic(
        [_a, _b, _c, _d, _e, _f, _g, _h, _i, _j, _k, assoc],
        not is_nil(field(assoc, ^field))
      )

  def build_dynamic(13, :==, field, nil),
    do: dynamic([_a, _b, _c, _d, _e, _f, _g, _h, _i, _j, _k, assoc], is_nil(field(assoc, ^field)))

  def build_dynamic(13, :!=, field, nil),
    do:
      dynamic(
        [_a, _b, _c, _d, _e, _f, _g, _h, _i, _j, _k, assoc],
        not is_nil(field(assoc, ^field))
      )

  def build_dynamic(13, :==, field, value),
    do:
      dynamic([_a, _b, _c, _d, _e, _f, _g, _h, _i, _j, _k, assoc], field(assoc, ^field) == ^value)

  def build_dynamic(13, :!=, field, value),
    do:
      dynamic([_a, _b, _c, _d, _e, _f, _g, _h, _i, _j, _k, assoc], field(assoc, ^field) != ^value)

  def build_dynamic(13, op, _field, nil) when op in [:>, :<, :>=, :<=, :in, :not_in],
    do:
      raise(
        ArgumentError,
        "Cannot compare with nil using #{op}.
               Use :is_nil or :not_nil instead."
      )

  def build_dynamic(13, :>, field, value),
    do:
      dynamic([_a, _b, _c, _d, _e, _f, _g, _h, _i, _j, _k, assoc], field(assoc, ^field) > ^value)

  def build_dynamic(13, :<, field, value),
    do:
      dynamic([_a, _b, _c, _d, _e, _f, _g, _h, _i, _j, _k, assoc], field(assoc, ^field) < ^value)

  def build_dynamic(13, :>=, field, value),
    do:
      dynamic([_a, _b, _c, _d, _e, _f, _g, _h, _i, _j, _k, assoc], field(assoc, ^field) >= ^value)

  def build_dynamic(13, :<=, field, value),
    do:
      dynamic([_a, _b, _c, _d, _e, _f, _g, _h, _i, _j, _k, assoc], field(assoc, ^field) <= ^value)

  def build_dynamic(13, :in, field, value) when is_list(value),
    do:
      dynamic([_a, _b, _c, _d, _e, _f, _g, _h, _i, _j, _k, assoc], field(assoc, ^field) in ^value)

  def build_dynamic(13, :not_in, field, value) when is_list(value),
    do:
      dynamic(
        [_a, _b, _c, _d, _e, _f, _g, _h, _i, _j, _k, assoc],
        field(assoc, ^field) not in ^value
      )

  # ---- ARITY: 14 ----
  def build_dynamic(14, :is_nil, field, _value),
    do:
      dynamic(
        [_a, _b, _c, _d, _e, _f, _g, _h, _i, _j, _k, _l, assoc],
        is_nil(field(assoc, ^field))
      )

  def build_dynamic(14, :not_nil, field, _value),
    do:
      dynamic(
        [_a, _b, _c, _d, _e, _f, _g, _h, _i, _j, _k, _l, assoc],
        not is_nil(field(assoc, ^field))
      )

  def build_dynamic(14, :==, field, nil),
    do:
      dynamic(
        [_a, _b, _c, _d, _e, _f, _g, _h, _i, _j, _k, _l, assoc],
        is_nil(field(assoc, ^field))
      )

  def build_dynamic(14, :!=, field, nil),
    do:
      dynamic(
        [_a, _b, _c, _d, _e, _f, _g, _h, _i, _j, _k, _l, assoc],
        not is_nil(field(assoc, ^field))
      )

  def build_dynamic(14, :==, field, value),
    do:
      dynamic(
        [_a, _b, _c, _d, _e, _f, _g, _h, _i, _j, _k, _l, assoc],
        field(assoc, ^field) == ^value
      )

  def build_dynamic(14, :!=, field, value),
    do:
      dynamic(
        [_a, _b, _c, _d, _e, _f, _g, _h, _i, _j, _k, _l, assoc],
        field(assoc, ^field) != ^value
      )

  def build_dynamic(14, op, _field, nil) when op in [:>, :<, :>=, :<=, :in, :not_in],
    do:
      raise(
        ArgumentError,
        "Cannot compare with nil using #{op}.
               Use :is_nil or :not_nil instead."
      )

  def build_dynamic(14, :>, field, value),
    do:
      dynamic(
        [_a, _b, _c, _d, _e, _f, _g, _h, _i, _j, _k, _l, assoc],
        field(assoc, ^field) > ^value
      )

  def build_dynamic(14, :<, field, value),
    do:
      dynamic(
        [_a, _b, _c, _d, _e, _f, _g, _h, _i, _j, _k, _l, assoc],
        field(assoc, ^field) < ^value
      )

  def build_dynamic(14, :>=, field, value),
    do:
      dynamic(
        [_a, _b, _c, _d, _e, _f, _g, _h, _i, _j, _k, _l, assoc],
        field(assoc, ^field) >= ^value
      )

  def build_dynamic(14, :<=, field, value),
    do:
      dynamic(
        [_a, _b, _c, _d, _e, _f, _g, _h, _i, _j, _k, _l, assoc],
        field(assoc, ^field) <= ^value
      )

  def build_dynamic(14, :in, field, value) when is_list(value),
    do:
      dynamic(
        [_a, _b, _c, _d, _e, _f, _g, _h, _i, _j, _k, _l, assoc],
        field(assoc, ^field) in ^value
      )

  def build_dynamic(14, :not_in, field, value) when is_list(value),
    do:
      dynamic(
        [_a, _b, _c, _d, _e, _f, _g, _h, _i, _j, _k, _l, assoc],
        field(assoc, ^field) not in ^value
      )

  # ---- ARITY: 15 ----
  def build_dynamic(15, :is_nil, field, _value),
    do:
      dynamic(
        [_a, _b, _c, _d, _e, _f, _g, _h, _i, _j, _k, _l, _m, assoc],
        is_nil(field(assoc, ^field))
      )

  def build_dynamic(15, :not_nil, field, _value),
    do:
      dynamic(
        [_a, _b, _c, _d, _e, _f, _g, _h, _i, _j, _k, _l, _m, assoc],
        not is_nil(field(assoc, ^field))
      )

  def build_dynamic(15, :==, field, nil),
    do:
      dynamic(
        [_a, _b, _c, _d, _e, _f, _g, _h, _i, _j, _k, _l, _m, assoc],
        is_nil(field(assoc, ^field))
      )

  def build_dynamic(15, :!=, field, nil),
    do:
      dynamic(
        [_a, _b, _c, _d, _e, _f, _g, _h, _i, _j, _k, _l, _m, assoc],
        not is_nil(field(assoc, ^field))
      )

  def build_dynamic(15, :==, field, value),
    do:
      dynamic(
        [_a, _b, _c, _d, _e, _f, _g, _h, _i, _j, _k, _l, _m, assoc],
        field(assoc, ^field) == ^value
      )

  def build_dynamic(15, :!=, field, value),
    do:
      dynamic(
        [_a, _b, _c, _d, _e, _f, _g, _h, _i, _j, _k, _l, _m, assoc],
        field(assoc, ^field) != ^value
      )

  def build_dynamic(15, op, _field, nil) when op in [:>, :<, :>=, :<=, :in, :not_in],
    do:
      raise(
        ArgumentError,
        "Cannot compare with nil using #{op}.
               Use :is_nil or :not_nil instead."
      )

  def build_dynamic(15, :>, field, value),
    do:
      dynamic(
        [_a, _b, _c, _d, _e, _f, _g, _h, _i, _j, _k, _l, _m, assoc],
        field(assoc, ^field) > ^value
      )

  def build_dynamic(15, :<, field, value),
    do:
      dynamic(
        [_a, _b, _c, _d, _e, _f, _g, _h, _i, _j, _k, _l, _m, assoc],
        field(assoc, ^field) < ^value
      )

  def build_dynamic(15, :>=, field, value),
    do:
      dynamic(
        [_a, _b, _c, _d, _e, _f, _g, _h, _i, _j, _k, _l, _m, assoc],
        field(assoc, ^field) >= ^value
      )

  def build_dynamic(15, :<=, field, value),
    do:
      dynamic(
        [_a, _b, _c, _d, _e, _f, _g, _h, _i, _j, _k, _l, _m, assoc],
        field(assoc, ^field) <= ^value
      )

  def build_dynamic(15, :in, field, value) when is_list(value),
    do:
      dynamic(
        [_a, _b, _c, _d, _e, _f, _g, _h, _i, _j, _k, _l, _m, assoc],
        field(assoc, ^field) in ^value
      )

  def build_dynamic(15, :not_in, field, value) when is_list(value),
    do:
      dynamic(
        [_a, _b, _c, _d, _e, _f, _g, _h, _i, _j, _k, _l, _m, assoc],
        field(assoc, ^field) not in ^value
      )

  # ---- ARITY: 16 ----
  def build_dynamic(16, :is_nil, field, _value),
    do:
      dynamic(
        [_a, _b, _c, _d, _e, _f, _g, _h, _i, _j, _k, _l, _m, _n, assoc],
        is_nil(field(assoc, ^field))
      )

  def build_dynamic(16, :not_nil, field, _value),
    do:
      dynamic(
        [_a, _b, _c, _d, _e, _f, _g, _h, _i, _j, _k, _l, _m, _n, assoc],
        not is_nil(field(assoc, ^field))
      )

  def build_dynamic(16, :==, field, nil),
    do:
      dynamic(
        [_a, _b, _c, _d, _e, _f, _g, _h, _i, _j, _k, _l, _m, _n, assoc],
        is_nil(field(assoc, ^field))
      )

  def build_dynamic(16, :!=, field, nil),
    do:
      dynamic(
        [_a, _b, _c, _d, _e, _f, _g, _h, _i, _j, _k, _l, _m, _n, assoc],
        not is_nil(field(assoc, ^field))
      )

  def build_dynamic(16, :==, field, value),
    do:
      dynamic(
        [_a, _b, _c, _d, _e, _f, _g, _h, _i, _j, _k, _l, _m, _n, assoc],
        field(assoc, ^field) == ^value
      )

  def build_dynamic(16, :!=, field, value),
    do:
      dynamic(
        [_a, _b, _c, _d, _e, _f, _g, _h, _i, _j, _k, _l, _m, _n, assoc],
        field(assoc, ^field) != ^value
      )

  def build_dynamic(16, op, _field, nil) when op in [:>, :<, :>=, :<=, :in, :not_in],
    do:
      raise(
        ArgumentError,
        "Cannot compare with nil using #{op}.
               Use :is_nil or :not_nil instead."
      )

  def build_dynamic(16, :>, field, value),
    do:
      dynamic(
        [_a, _b, _c, _d, _e, _f, _g, _h, _i, _j, _k, _l, _m, _n, assoc],
        field(assoc, ^field) > ^value
      )

  def build_dynamic(16, :<, field, value),
    do:
      dynamic(
        [_a, _b, _c, _d, _e, _f, _g, _h, _i, _j, _k, _l, _m, _n, assoc],
        field(assoc, ^field) < ^value
      )

  def build_dynamic(16, :>=, field, value),
    do:
      dynamic(
        [_a, _b, _c, _d, _e, _f, _g, _h, _i, _j, _k, _l, _m, _n, assoc],
        field(assoc, ^field) >= ^value
      )

  def build_dynamic(16, :<=, field, value),
    do:
      dynamic(
        [_a, _b, _c, _d, _e, _f, _g, _h, _i, _j, _k, _l, _m, _n, assoc],
        field(assoc, ^field) <= ^value
      )

  def build_dynamic(16, :in, field, value) when is_list(value),
    do:
      dynamic(
        [_a, _b, _c, _d, _e, _f, _g, _h, _i, _j, _k, _l, _m, _n, assoc],
        field(assoc, ^field) in ^value
      )

  def build_dynamic(16, :not_in, field, value) when is_list(value),
    do:
      dynamic(
        [_a, _b, _c, _d, _e, _f, _g, _h, _i, _j, _k, _l, _m, _n, assoc],
        field(assoc, ^field) not in ^value
      )

  # ---- ARITY: 17 ----
  def build_dynamic(17, :is_nil, field, _value),
    do:
      dynamic(
        [_a, _b, _c, _d, _e, _f, _g, _h, _i, _j, _k, _l, _m, _n, _o, assoc],
        is_nil(field(assoc, ^field))
      )

  def build_dynamic(17, :not_nil, field, _value),
    do:
      dynamic(
        [_a, _b, _c, _d, _e, _f, _g, _h, _i, _j, _k, _l, _m, _n, _o, assoc],
        not is_nil(field(assoc, ^field))
      )

  def build_dynamic(17, :==, field, nil),
    do:
      dynamic(
        [_a, _b, _c, _d, _e, _f, _g, _h, _i, _j, _k, _l, _m, _n, _o, assoc],
        is_nil(field(assoc, ^field))
      )

  def build_dynamic(17, :!=, field, nil),
    do:
      dynamic(
        [_a, _b, _c, _d, _e, _f, _g, _h, _i, _j, _k, _l, _m, _n, _o, assoc],
        not is_nil(field(assoc, ^field))
      )

  def build_dynamic(17, :==, field, value),
    do:
      dynamic(
        [_a, _b, _c, _d, _e, _f, _g, _h, _i, _j, _k, _l, _m, _n, _o, assoc],
        field(assoc, ^field) == ^value
      )

  def build_dynamic(17, :!=, field, value),
    do:
      dynamic(
        [_a, _b, _c, _d, _e, _f, _g, _h, _i, _j, _k, _l, _m, _n, _o, assoc],
        field(assoc, ^field) != ^value
      )

  def build_dynamic(17, op, _field, nil) when op in [:>, :<, :>=, :<=, :in, :not_in],
    do:
      raise(
        ArgumentError,
        "Cannot compare with nil using #{op}.
               Use :is_nil or :not_nil instead."
      )

  def build_dynamic(17, :>, field, value),
    do:
      dynamic(
        [_a, _b, _c, _d, _e, _f, _g, _h, _i, _j, _k, _l, _m, _n, _o, assoc],
        field(assoc, ^field) > ^value
      )

  def build_dynamic(17, :<, field, value),
    do:
      dynamic(
        [_a, _b, _c, _d, _e, _f, _g, _h, _i, _j, _k, _l, _m, _n, _o, assoc],
        field(assoc, ^field) < ^value
      )

  def build_dynamic(17, :>=, field, value),
    do:
      dynamic(
        [_a, _b, _c, _d, _e, _f, _g, _h, _i, _j, _k, _l, _m, _n, _o, assoc],
        field(assoc, ^field) >= ^value
      )

  def build_dynamic(17, :<=, field, value),
    do:
      dynamic(
        [_a, _b, _c, _d, _e, _f, _g, _h, _i, _j, _k, _l, _m, _n, _o, assoc],
        field(assoc, ^field) <= ^value
      )

  def build_dynamic(17, :in, field, value) when is_list(value),
    do:
      dynamic(
        [_a, _b, _c, _d, _e, _f, _g, _h, _i, _j, _k, _l, _m, _n, _o, assoc],
        field(assoc, ^field) in ^value
      )

  def build_dynamic(17, :not_in, field, value) when is_list(value),
    do:
      dynamic(
        [_a, _b, _c, _d, _e, _f, _g, _h, _i, _j, _k, _l, _m, _n, _o, assoc],
        field(assoc, ^field) not in ^value
      )

  # ---- ARITY: 18 ----
  def build_dynamic(18, :is_nil, field, _value),
    do:
      dynamic(
        [_a, _b, _c, _d, _e, _f, _g, _h, _i, _j, _k, _l, _m, _n, _o, _p, assoc],
        is_nil(field(assoc, ^field))
      )

  def build_dynamic(18, :not_nil, field, _value),
    do:
      dynamic(
        [_a, _b, _c, _d, _e, _f, _g, _h, _i, _j, _k, _l, _m, _n, _o, _p, assoc],
        not is_nil(field(assoc, ^field))
      )

  def build_dynamic(18, :==, field, nil),
    do:
      dynamic(
        [_a, _b, _c, _d, _e, _f, _g, _h, _i, _j, _k, _l, _m, _n, _o, _p, assoc],
        is_nil(field(assoc, ^field))
      )

  def build_dynamic(18, :!=, field, nil),
    do:
      dynamic(
        [_a, _b, _c, _d, _e, _f, _g, _h, _i, _j, _k, _l, _m, _n, _o, _p, assoc],
        not is_nil(field(assoc, ^field))
      )

  def build_dynamic(18, :==, field, value),
    do:
      dynamic(
        [_a, _b, _c, _d, _e, _f, _g, _h, _i, _j, _k, _l, _m, _n, _o, _p, assoc],
        field(assoc, ^field) == ^value
      )

  def build_dynamic(18, :!=, field, value),
    do:
      dynamic(
        [_a, _b, _c, _d, _e, _f, _g, _h, _i, _j, _k, _l, _m, _n, _o, _p, assoc],
        field(assoc, ^field) != ^value
      )

  def build_dynamic(18, op, _field, nil) when op in [:>, :<, :>=, :<=, :in, :not_in],
    do:
      raise(
        ArgumentError,
        "Cannot compare with nil using #{op}.
               Use :is_nil or :not_nil instead."
      )

  def build_dynamic(18, :>, field, value),
    do:
      dynamic(
        [_a, _b, _c, _d, _e, _f, _g, _h, _i, _j, _k, _l, _m, _n, _o, _p, assoc],
        field(assoc, ^field) > ^value
      )

  def build_dynamic(18, :<, field, value),
    do:
      dynamic(
        [_a, _b, _c, _d, _e, _f, _g, _h, _i, _j, _k, _l, _m, _n, _o, _p, assoc],
        field(assoc, ^field) < ^value
      )

  def build_dynamic(18, :>=, field, value),
    do:
      dynamic(
        [_a, _b, _c, _d, _e, _f, _g, _h, _i, _j, _k, _l, _m, _n, _o, _p, assoc],
        field(assoc, ^field) >= ^value
      )

  def build_dynamic(18, :<=, field, value),
    do:
      dynamic(
        [_a, _b, _c, _d, _e, _f, _g, _h, _i, _j, _k, _l, _m, _n, _o, _p, assoc],
        field(assoc, ^field) <= ^value
      )

  def build_dynamic(18, :in, field, value) when is_list(value),
    do:
      dynamic(
        [_a, _b, _c, _d, _e, _f, _g, _h, _i, _j, _k, _l, _m, _n, _o, _p, assoc],
        field(assoc, ^field) in ^value
      )

  def build_dynamic(18, :not_in, field, value) when is_list(value),
    do:
      dynamic(
        [_a, _b, _c, _d, _e, _f, _g, _h, _i, _j, _k, _l, _m, _n, _o, _p, assoc],
        field(assoc, ^field) not in ^value
      )

  # ---- ARITY: 19 ----
  def build_dynamic(19, :is_nil, field, _value),
    do:
      dynamic(
        [_a, _b, _c, _d, _e, _f, _g, _h, _i, _j, _k, _l, _m, _n, _o, _p, _q, assoc],
        is_nil(field(assoc, ^field))
      )

  def build_dynamic(19, :not_nil, field, _value),
    do:
      dynamic(
        [_a, _b, _c, _d, _e, _f, _g, _h, _i, _j, _k, _l, _m, _n, _o, _p, _q, assoc],
        not is_nil(field(assoc, ^field))
      )

  def build_dynamic(19, :==, field, nil),
    do:
      dynamic(
        [_a, _b, _c, _d, _e, _f, _g, _h, _i, _j, _k, _l, _m, _n, _o, _p, _q, assoc],
        is_nil(field(assoc, ^field))
      )

  def build_dynamic(19, :!=, field, nil),
    do:
      dynamic(
        [_a, _b, _c, _d, _e, _f, _g, _h, _i, _j, _k, _l, _m, _n, _o, _p, _q, assoc],
        not is_nil(field(assoc, ^field))
      )

  def build_dynamic(19, :==, field, value),
    do:
      dynamic(
        [_a, _b, _c, _d, _e, _f, _g, _h, _i, _j, _k, _l, _m, _n, _o, _p, _q, assoc],
        field(assoc, ^field) == ^value
      )

  def build_dynamic(19, :!=, field, value),
    do:
      dynamic(
        [_a, _b, _c, _d, _e, _f, _g, _h, _i, _j, _k, _l, _m, _n, _o, _p, _q, assoc],
        field(assoc, ^field) != ^value
      )

  def build_dynamic(19, op, _field, nil) when op in [:>, :<, :>=, :<=, :in, :not_in],
    do:
      raise(
        ArgumentError,
        "Cannot compare with nil using #{op}.
               Use :is_nil or :not_nil instead."
      )

  def build_dynamic(19, :>, field, value),
    do:
      dynamic(
        [_a, _b, _c, _d, _e, _f, _g, _h, _i, _j, _k, _l, _m, _n, _o, _p, _q, assoc],
        field(assoc, ^field) > ^value
      )

  def build_dynamic(19, :<, field, value),
    do:
      dynamic(
        [_a, _b, _c, _d, _e, _f, _g, _h, _i, _j, _k, _l, _m, _n, _o, _p, _q, assoc],
        field(assoc, ^field) < ^value
      )

  def build_dynamic(19, :>=, field, value),
    do:
      dynamic(
        [_a, _b, _c, _d, _e, _f, _g, _h, _i, _j, _k, _l, _m, _n, _o, _p, _q, assoc],
        field(assoc, ^field) >= ^value
      )

  def build_dynamic(19, :<=, field, value),
    do:
      dynamic(
        [_a, _b, _c, _d, _e, _f, _g, _h, _i, _j, _k, _l, _m, _n, _o, _p, _q, assoc],
        field(assoc, ^field) <= ^value
      )

  def build_dynamic(19, :in, field, value) when is_list(value),
    do:
      dynamic(
        [_a, _b, _c, _d, _e, _f, _g, _h, _i, _j, _k, _l, _m, _n, _o, _p, _q, assoc],
        field(assoc, ^field) in ^value
      )

  def build_dynamic(19, :not_in, field, value) when is_list(value),
    do:
      dynamic(
        [_a, _b, _c, _d, _e, _f, _g, _h, _i, _j, _k, _l, _m, _n, _o, _p, _q, assoc],
        field(assoc, ^field) not in ^value
      )

  # ---- ARITY: 20 ----
  def build_dynamic(20, :is_nil, field, _value),
    do:
      dynamic(
        [_a, _b, _c, _d, _e, _f, _g, _h, _i, _j, _k, _l, _m, _n, _o, _p, _q, _r, assoc],
        is_nil(field(assoc, ^field))
      )

  def build_dynamic(20, :not_nil, field, _value),
    do:
      dynamic(
        [_a, _b, _c, _d, _e, _f, _g, _h, _i, _j, _k, _l, _m, _n, _o, _p, _q, _r, assoc],
        not is_nil(field(assoc, ^field))
      )

  def build_dynamic(20, :==, field, nil),
    do:
      dynamic(
        [_a, _b, _c, _d, _e, _f, _g, _h, _i, _j, _k, _l, _m, _n, _o, _p, _q, _r, assoc],
        is_nil(field(assoc, ^field))
      )

  def build_dynamic(20, :!=, field, nil),
    do:
      dynamic(
        [_a, _b, _c, _d, _e, _f, _g, _h, _i, _j, _k, _l, _m, _n, _o, _p, _q, _r, assoc],
        not is_nil(field(assoc, ^field))
      )

  def build_dynamic(20, :==, field, value),
    do:
      dynamic(
        [_a, _b, _c, _d, _e, _f, _g, _h, _i, _j, _k, _l, _m, _n, _o, _p, _q, _r, assoc],
        field(assoc, ^field) == ^value
      )

  def build_dynamic(20, :!=, field, value),
    do:
      dynamic(
        [_a, _b, _c, _d, _e, _f, _g, _h, _i, _j, _k, _l, _m, _n, _o, _p, _q, _r, assoc],
        field(assoc, ^field) != ^value
      )

  def build_dynamic(20, op, _field, nil) when op in [:>, :<, :>=, :<=, :in, :not_in],
    do:
      raise(
        ArgumentError,
        "Cannot compare with nil using #{op}.
               Use :is_nil or :not_nil instead."
      )

  def build_dynamic(20, :>, field, value),
    do:
      dynamic(
        [_a, _b, _c, _d, _e, _f, _g, _h, _i, _j, _k, _l, _m, _n, _o, _p, _q, _r, assoc],
        field(assoc, ^field) > ^value
      )

  def build_dynamic(20, :<, field, value),
    do:
      dynamic(
        [_a, _b, _c, _d, _e, _f, _g, _h, _i, _j, _k, _l, _m, _n, _o, _p, _q, _r, assoc],
        field(assoc, ^field) < ^value
      )

  def build_dynamic(20, :>=, field, value),
    do:
      dynamic(
        [_a, _b, _c, _d, _e, _f, _g, _h, _i, _j, _k, _l, _m, _n, _o, _p, _q, _r, assoc],
        field(assoc, ^field) >= ^value
      )

  def build_dynamic(20, :<=, field, value),
    do:
      dynamic(
        [_a, _b, _c, _d, _e, _f, _g, _h, _i, _j, _k, _l, _m, _n, _o, _p, _q, _r, assoc],
        field(assoc, ^field) <= ^value
      )

  def build_dynamic(20, :in, field, value) when is_list(value),
    do:
      dynamic(
        [_a, _b, _c, _d, _e, _f, _g, _h, _i, _j, _k, _l, _m, _n, _o, _p, _q, _r, assoc],
        field(assoc, ^field) in ^value
      )

  def build_dynamic(20, :not_in, field, value) when is_list(value),
    do:
      dynamic(
        [_a, _b, _c, _d, _e, _f, _g, _h, _i, _j, _k, _l, _m, _n, _o, _p, _q, _r, assoc],
        field(assoc, ^field) not in ^value
      )

  # ---- ARITY: 21 ----
  def build_dynamic(21, :is_nil, field, _value),
    do:
      dynamic(
        [_a, _b, _c, _d, _e, _f, _g, _h, _i, _j, _k, _l, _m, _n, _o, _p, _q, _r, _s, assoc],
        is_nil(field(assoc, ^field))
      )

  def build_dynamic(21, :not_nil, field, _value),
    do:
      dynamic(
        [_a, _b, _c, _d, _e, _f, _g, _h, _i, _j, _k, _l, _m, _n, _o, _p, _q, _r, _s, assoc],
        not is_nil(field(assoc, ^field))
      )

  def build_dynamic(21, :==, field, nil),
    do:
      dynamic(
        [_a, _b, _c, _d, _e, _f, _g, _h, _i, _j, _k, _l, _m, _n, _o, _p, _q, _r, _s, assoc],
        is_nil(field(assoc, ^field))
      )

  def build_dynamic(21, :!=, field, nil),
    do:
      dynamic(
        [_a, _b, _c, _d, _e, _f, _g, _h, _i, _j, _k, _l, _m, _n, _o, _p, _q, _r, _s, assoc],
        not is_nil(field(assoc, ^field))
      )

  def build_dynamic(21, :==, field, value),
    do:
      dynamic(
        [_a, _b, _c, _d, _e, _f, _g, _h, _i, _j, _k, _l, _m, _n, _o, _p, _q, _r, _s, assoc],
        field(assoc, ^field) == ^value
      )

  def build_dynamic(21, :!=, field, value),
    do:
      dynamic(
        [_a, _b, _c, _d, _e, _f, _g, _h, _i, _j, _k, _l, _m, _n, _o, _p, _q, _r, _s, assoc],
        field(assoc, ^field) != ^value
      )

  def build_dynamic(21, op, _field, nil) when op in [:>, :<, :>=, :<=, :in, :not_in],
    do:
      raise(
        ArgumentError,
        "Cannot compare with nil using #{op}.
               Use :is_nil or :not_nil instead."
      )

  def build_dynamic(21, :>, field, value),
    do:
      dynamic(
        [_a, _b, _c, _d, _e, _f, _g, _h, _i, _j, _k, _l, _m, _n, _o, _p, _q, _r, _s, assoc],
        field(assoc, ^field) > ^value
      )

  def build_dynamic(21, :<, field, value),
    do:
      dynamic(
        [_a, _b, _c, _d, _e, _f, _g, _h, _i, _j, _k, _l, _m, _n, _o, _p, _q, _r, _s, assoc],
        field(assoc, ^field) < ^value
      )

  def build_dynamic(21, :>=, field, value),
    do:
      dynamic(
        [_a, _b, _c, _d, _e, _f, _g, _h, _i, _j, _k, _l, _m, _n, _o, _p, _q, _r, _s, assoc],
        field(assoc, ^field) >= ^value
      )

  def build_dynamic(21, :<=, field, value),
    do:
      dynamic(
        [_a, _b, _c, _d, _e, _f, _g, _h, _i, _j, _k, _l, _m, _n, _o, _p, _q, _r, _s, assoc],
        field(assoc, ^field) <= ^value
      )

  def build_dynamic(21, :in, field, value) when is_list(value),
    do:
      dynamic(
        [_a, _b, _c, _d, _e, _f, _g, _h, _i, _j, _k, _l, _m, _n, _o, _p, _q, _r, _s, assoc],
        field(assoc, ^field) in ^value
      )

  def build_dynamic(21, :not_in, field, value) when is_list(value),
    do:
      dynamic(
        [_a, _b, _c, _d, _e, _f, _g, _h, _i, _j, _k, _l, _m, _n, _o, _p, _q, _r, _s, assoc],
        field(assoc, ^field) not in ^value
      )

  def build_dynamic(arity, op, _field, _value) do
    raise ArgumentError, "Unsupported binding depth: #{arity} or operator: #{inspect(op)}"
  end
end
