defmodule Reportes do
  @moduledoc "Cálculos puros de los ocho reportes y del ranking."

  @meta_diaria 600
  @motivos [:confeccionista_desconocido, :linea_desconocida, :dia_invalido, :prendas_fuera_de_rango, :porcentaje_invalido]

  @doc "Resume lotes rechazados y cuenta cada motivo."
  def r1(rechazados) do
    conteos = Enum.reduce(rechazados, Map.new(@motivos, &{&1, 0}), fn {_lote, motivo}, acc ->
      Map.update!(acc, motivo, &(&1 + 1))
    end)
    %{rechazados: rechazados, conteos: conteos}
  end

  @doc "Calcula producción y productividad por línea, incluyendo líneas sin producción."
  def r2(lineas, lotes) do
    Enum.map(lineas, fn linea ->
      prendas = lotes |> Enum.filter(&(&1.linea == linea.id)) |> Enum.map(& &1.prendas) |> Enum.sum()
      %{id: linea.id, nombre: linea.nombre, puestos: linea.puestos,
        prendas: prendas, productividad: prendas / linea.puestos}
    end)
    |> Enum.sort_by(& &1.productividad, :desc)
  end

  @doc "Calcula la producción de cada uno de los seis días y las metas."
  def r3(lotes) do
    dias =
      for dia <- 1..6 do
        prendas = lotes |> Enum.filter(&(&1.dia == dia)) |> Enum.map(& &1.prendas) |> Enum.sum()
        %{dia: dia, prendas: prendas, meta_alcanzada?: prendas >= @meta_diaria}
      end

    %{dias: dias,
      todos?: Enum.all?(dias, & &1.meta_alcanzada?),
      al_menos_uno?: Enum.any?(dias, & &1.meta_alcanzada?)}
  end

  @doc "Ordena la liquidación por pago neto descendente."
  def r4(liquidaciones), do: Enum.sort_by(liquidaciones, & &1.neto, :desc)

  @doc "Calcula los líderes de producción para cada día y los empates."
  def r5(confeccionistas, lotes) do
    dias =
      for dia <- 1..6 do
        produccion =
          confeccionistas
          |> Enum.map(fn c -> {c, Enum.filter(lotes, &(&1.confeccionista == c.codigo and &1.dia == dia)) |> Enum.map(& &1.prendas) |> Enum.sum()} end)
          |> Enum.filter(fn {_c, prendas} -> prendas > 0 end)

        case produccion do
          [] -> %{dia: dia, lideres: [], prendas: 0}
          _ ->
            maximo = Enum.max_by(produccion, fn {_c, prendas} -> prendas end) |> elem(1)
            lideres = Enum.filter(produccion, fn {_c, prendas} -> prendas == maximo end) |> Enum.map(&elem(&1, 0))
            %{dia: dia, lideres: lideres, prendas: maximo}
        end
      end

    primeros =
      dias
      |> Enum.flat_map(& &1.lideres)
      |> Enum.frequencies()

    maximo_primeros = if map_size(primeros) == 0, do: 0, else: primeros |> Map.values() |> Enum.max()
    mas_primeros = Enum.filter(primeros, fn {_codigo, cantidad} -> cantidad == maximo_primeros end) |> Enum.map(&elem(&1, 0))

    %{dias: dias, primeros: primeros, maximo_primeros: maximo_primeros, mas_primeros: mas_primeros}
  end

  @doc "Calcula el menor porcentaje de defectos ponderado entre quienes tienen al menos tres lotes."
  def r6(confeccionistas, lotes) do
    candidatos =
      confeccionistas
      |> Enum.map(fn c ->
        lotes_c = Enum.filter(lotes, &(&1.confeccionista == c.codigo))
        prendas = Enum.sum(Enum.map(lotes_c, & &1.prendas))
        ponderado = if prendas > 0, do: Enum.sum(Enum.map(lotes_c, &(&1.defectos * &1.prendas))) / prendas, else: nil
        %{confeccionista: c, lotes: length(lotes_c), ponderado: ponderado}
      end)
      |> Enum.filter(&(&1.lotes >= 3))

    case candidatos do
      [] -> %{candidatos: [], mejores: []}
      _ ->
        minimo = Enum.min_by(candidatos, & &1.ponderado).ponderado
        mejores = Enum.filter(candidatos, & &1.ponderado == minimo)
        %{candidatos: candidatos, mejores: mejores}
    end
  end

  @doc "Calcula el pago total y el promedio por prenda válida."
  def r7(liquidaciones) do
    total = Enum.sum(Enum.map(liquidaciones, & &1.neto))
    prendas = Enum.sum(Enum.map(liquidaciones, & &1.prendas))
    promedio = if prendas > 0, do: total / prendas, else: nil
    %{total: total, prendas: prendas, promedio: promedio}
  end

  @doc "Obtiene los confeccionistas que trabajaron al menos una vez en todas las líneas."
  def r8(confeccionistas, lineas, lotes) do
    ids_lineas = Enum.map(lineas, & &1.id) |> MapSet.new()
    Enum.filter(confeccionistas, fn c ->
      lineas_trabajadas = lotes |> Enum.filter(&(&1.confeccionista == c.codigo)) |> Enum.map(& &1.linea) |> MapSet.new()
      MapSet.subset?(ids_lineas, lineas_trabajadas)
    end)
  end

  @doc "Combina producción diaria de dos mapas sumando los días coincidentes."
  def combinar_produccion(produccion, aliado) do
    Map.merge(produccion, aliado, fn _dia, taller, aliado_dia -> taller + aliado_dia end)
  end

  @doc "Ordena liquidaciones según campo, orden y límite indicados en una keyword list."
  def ranking(liquidaciones, opciones) do
    campo = Keyword.get(opciones, :campo, :neto)
    orden = Keyword.get(opciones, :orden, :desc)
    limite = Keyword.get(opciones, :limite, length(liquidaciones))

    liquidaciones
    |> Enum.sort_by(&valor_campo(&1, campo), orden)
    |> Enum.take(limite)
  end

  defp valor_campo(liquidacion, :neto), do: liquidacion.neto
  defp valor_campo(liquidacion, :prendas), do: liquidacion.prendas
  defp valor_campo(liquidacion, :bruto), do: liquidacion.valor_lotes
end
