defmodule Mediciones do
  @moduledoc """
  Mediciones exigidas en C.3.
  """

  @doc """
  Ejecuta tres repeticiones de las mediciones solicitadas.
  """
  def main do
    IO.puts("===================================")
    IO.puts("C.3. MEDICIONES DE RENDIMIENTO")
    IO.puts("===================================\n")

    confeccionistas = Enum.map(1..100_000, fn i -> %{codigo: "C#{String.pad_leading(Integer.to_string(i), 6, "0")}", nombre: "Confeccionista #{i}"} end)
    mapa = Enum.into(confeccionistas, %{}, &{&1.codigo, &1})
    codigos = Enum.map(1..1_000, fn i -> "C#{String.pad_leading(Integer.to_string(rem(i * 7919, 100_000) + 1), 6, "0")}" end)

    IO.puts("--- Bosqueda de 1.000 codigos ---\n")
    tiempos_lista = medir_tres(fn -> Enum.each(codigos, fn codigo -> Enum.find(confeccionistas, &(&1.codigo == codigo)) end) end)
    tiempos_mapa = medir_tres(fn -> Enum.each(codigos, fn codigo -> Map.get(mapa, codigo) end) end)
    imprimir_tiempos("Busqueda en lista", tiempos_lista)
    imprimir_tiempos("Busqueda en mapa", tiempos_mapa)

    IO.puts("\n--- Construcciun de 20.000 elementos ---\n")
    tiempos_final = medir_tres(fn -> Enum.reduce(1..20_000, [], fn i, acc -> acc ++ [i] end) end)
    tiempos_inicio = medir_tres(fn -> Enum.reduce(1..20_000, [], fn i, acc -> [i | acc] end) end)
    imprimir_tiempos("Agregando al final con ++", tiempos_final)
    imprimir_tiempos("Agregando al inicio con [elemento | lista]", tiempos_inicio)
  end

  defp medir_tres(funcion) do
    Enum.map(1..3, fn _ -> :timer.tc(funcion) |> elem(0) end)
  end

  defp imprimir_tiempos(nombre, tiempos) do
    IO.puts("#{nombre}:")
    Enum.each(tiempos, &IO.puts("#{&1} microsegundos"))
    IO.puts("Promedio: #{Float.round(Enum.sum(tiempos) / 3, 2)} microsegundos\n")
  end
end

Mediciones.main()
