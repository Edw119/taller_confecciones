defmodule Validacion do
  @moduledoc "Valida lotes según las cinco reglas del parcial."

  @doc "Valida un lote en el orden exigido y devuelve {:ok, lote} o {:error, motivo}."
  def validar_lote(lote, confeccionistas, lineas) do
    with :ok <- validar_confeccionista(lote, confeccionistas),
         :ok <- validar_linea(lote, lineas),
         :ok <- validar_dia(lote),
         :ok <- validar_prendas(lote),
         :ok <- validar_defectos(lote) do
      {:ok, lote}
    end
  end

  @doc "Valida todos los lotes y separa válidos de rechazados."
  def validar_lotes(lotes, confeccionistas, lineas) do
    Enum.reduce(lotes, {[], []}, fn lote, {validos, rechazados} ->
      case validar_lote(lote, confeccionistas, lineas) do
        {:ok, lote_valido} -> {[lote_valido | validos], rechazados}
        {:error, motivo} -> {validos, [{lote, motivo} | rechazados]}
      end
    end)
    |> ordenar_resultados()
  end

  @doc "Verifica que el confeccionista exista."
  def validar_confeccionista(%{confeccionista: codigo}, confeccionistas) do
    if Enum.any?(confeccionistas, &(&1.codigo == codigo)), do: :ok, else: {:error, :confeccionista_desconocido}
  end

  @doc "Verifica que la línea exista."
  def validar_linea(%{linea: id}, lineas) do
    if Enum.any?(lineas, &(&1.id == id)), do: :ok, else: {:error, :linea_desconocida}
  end

  @doc "Verifica que el día sea entero entre 1 y 6."
  def validar_dia(%{dia: dia}) when is_integer(dia) and dia in 1..6, do: :ok
  def validar_dia(_), do: {:error, :dia_invalido}

  @doc "Verifica que las prendas sean enteras entre 1 y 180."
  def validar_prendas(%{prendas: prendas}) when is_integer(prendas) and prendas in 1..180, do: :ok
  def validar_prendas(_), do: {:error, :prendas_fuera_de_rango}

  @doc "Verifica que los defectos sean numéricos entre 0 y 100."
  def validar_defectos(%{defectos: defectos}) when is_number(defectos) and defectos >= 0 and defectos <= 100, do: :ok
  def validar_defectos(_), do: {:error, :porcentaje_invalido}

  defp ordenar_resultados({validos, rechazados}), do: {Enum.reverse(validos), Enum.reverse(rechazados)}
end
