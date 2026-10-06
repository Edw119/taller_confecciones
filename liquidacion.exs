defmodule Liquidacion do
  @moduledoc "Calcula valores económicos y liquidaciones del taller."

  @tarifa_base 3200.0
  @bonificacion_diaria 18000.0
  @prendas_bonificacion 120
  @alquiler_diario 15000.0

  @doc "Calcula el valor económico de un lote válido según sus defectos."
  def valor_lote(%{prendas: prendas, defectos: defectos}) do
    prendas * @tarifa_base * factor_defectos(defectos)
  end

  @doc "Calcula la bonificación de un día según las prendas acumuladas."
  def bonificacion_diaria(prendas) when prendas >= @prendas_bonificacion, do: @bonificacion_diaria
  def bonificacion_diaria(_), do: 0.0

  @doc "Calcula el descuento de alquiler por cantidad de días trabajados."
  def alquiler(alquila?, dias_trabajados) do
    if alquila?, do: dias_trabajados * @alquiler_diario, else: 0.0
  end

  @doc "Liquida un confeccionista a partir de sus lotes válidos."
  def liquidar_confeccionista(confeccionista, lotes) do
    lotes_por_dia = agrupar_por_dia(lotes)
    detalle =
      lotes_por_dia
      |> Enum.sort_by(fn {dia, _} -> dia end)
      |> Enum.map(fn {dia, lotes_dia} ->
        prendas = Enum.sum(Enum.map(lotes_dia, & &1.prendas))
        valor = Enum.sum(Enum.map(lotes_dia, &valor_lote/1))
        bono = bonificacion_diaria(prendas)
        %{dia: dia, prendas: prendas, valor: valor, bonificacion: bono, lotes: lotes_dia}
      end)

    prendas_totales = Enum.sum(Enum.map(detalle, & &1.prendas))
    valor_lotes = Enum.sum(Enum.map(detalle, & &1.valor))
    bonificaciones = Enum.sum(Enum.map(detalle, & &1.bonificacion))
    alquiler = alquiler(confeccionista.alquiler, length(detalle))

    %{codigo: confeccionista.codigo, nombre: confeccionista.nombre,
      alquiler?: confeccionista.alquiler, prendas: prendas_totales,
      valor_lotes: valor_lotes, bonificaciones: bonificaciones,
      alquiler: alquiler, neto: valor_lotes + bonificaciones - alquiler,
      detalle: detalle}
  end

  @doc "Liquida a todos los confeccionistas, incluyendo quienes no tienen lotes."
  def liquidar_todos(confeccionistas, lotes) do
    Enum.map(confeccionistas, fn confeccionista ->
      lotes_persona = Enum.filter(lotes, &(&1.confeccionista == confeccionista.codigo))
      liquidar_confeccionista(confeccionista, lotes_persona)
    end)
  end

  @doc "Retorna el factor económico correspondiente al porcentaje de defectos."
  def factor_defectos(defectos) when defectos <= 2, do: 1.07
  def factor_defectos(defectos) when defectos <= 5, do: 1.0
  def factor_defectos(defectos) when defectos <= 10, do: 0.88
  def factor_defectos(_), do: 0.75

  defp agrupar_por_dia(lotes) do
    Enum.group_by(lotes, & &1.dia)
  end
end
