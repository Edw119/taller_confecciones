defmodule Programa do
  @moduledoc "Interfaz principal del taller de confección."

  @doc "Ejecuta el flujo completo del parcial."
  def main do
    IO.puts("=== CARGA DE DATOS ===")
    confeccionistas = Datos.confeccionistas()
    lineas = Datos.lineas()
    lotes = Datos.lotes()
    {validos, rechazados} = Validacion.validar_lotes(lotes, confeccionistas, lineas)
    IO.puts("Lotes válidos: #{length(validos)}")
    IO.puts("Lotes rechazados: #{length(rechazados)}")

    {validos, rechazados} = solicitar_lote(validos, rechazados, confeccionistas, lineas)

    liquidaciones = Liquidacion.liquidar_todos(confeccionistas, validos)
    r1 = Reportes.r1(rechazados)
    r2 = Reportes.r2(lineas, validos)
    r3 = Reportes.r3(validos)
    r4 = Reportes.r4(liquidaciones)
    r5 = Reportes.r5(confeccionistas, validos)
    r6 = Reportes.r6(confeccionistas, validos)
    r7 = Reportes.r7(liquidaciones)
    r8 = Reportes.r8(confeccionistas, lineas, validos)

    imprimir_r1(r1)
    imprimir_r2(r2)
    imprimir_r3(r3)
    imprimir_r4(r4)
    imprimir_r5(r5)
    imprimir_r6(r6)
    imprimir_r7(r7)
    imprimir_r8(r8)
    imprimir_c1(liquidaciones)
    imprimir_c2(r3)
    solicitar_comprobante(confeccionistas, liquidaciones)
  end

  @doc "Solicita y procesa un lote adicional una sola vez."
  def solicitar_lote(validos, rechazados, confeccionistas, lineas) do
    IO.puts("\nIngrese un lote adicional (confeccionista;linea;dia;prendas;defectos)")
    IO.puts("Presione Enter para omitir.")
    texto = Util.ingresar("> ", :texto)

    if texto == "" do
      IO.puts("Lote omitido.")
      {validos, rechazados}
    else
      case Util.parsear_lote(texto) do
        {:error, :formato_invalido} ->
          IO.puts("Lote rechazado: formato_invalido")
          {validos, rechazados}

        {:ok, lote} ->
          case Validacion.validar_lote(lote, confeccionistas, lineas) do
            {:ok, lote_valido} ->
              IO.puts("Lote agregado correctamente.")
              {validos ++ [lote_valido], rechazados}
            {:error, motivo} ->
              IO.puts("Lote rechazado: #{motivo}")
              {validos, [{lote, motivo} | rechazados]}
          end
      end
    end
  end

  @doc "Imprime R1."
  def imprimir_r1(r1) do
    IO.puts("\n=== R1. LOTES RECHAZADOS ===")
    Enum.each(r1.rechazados, fn {lote, motivo} ->
      IO.puts("#{dato_lote(lote, :confeccionista)} - Línea #{dato_lote(lote, :linea)} - Día #{dato_lote(lote, :dia)} - Motivo: #{motivo}")
    end)
    IO.puts("\nCantidad de rechazos por motivo:")
    Enum.each(r1.conteos, fn {motivo, cantidad} -> IO.puts("#{motivo}: #{cantidad}") end)
  end

  @doc "Imprime R2."
  def imprimir_r2(r2) do
    IO.puts("\n=== R2. PRODUCCIÓN POR LÍNEA ===")
    Enum.each(r2, fn r -> IO.puts("#{r.id} - #{r.nombre} | Prendas: #{r.prendas} | Puestos: #{r.puestos} | Productividad: #{Float.round(r.productividad, 2)}") end)
  end

  @doc "Imprime R3."
  def imprimir_r3(r3) do
    IO.puts("\n=== R3. PRODUCCIÓN DIARIA ===")
    Enum.each(r3.dias, fn d -> IO.puts("Día #{d.dia}: #{d.prendas} prendas - #{if d.meta_alcanzada?, do: "Meta alcanzada", else: "Meta no alcanzada"}") end)
    IO.puts("\nMeta alcanzada todos los días: #{r3.todos?}")
    IO.puts("Meta alcanzada al menos un día: #{r3.al_menos_uno?}")
  end

  @doc "Imprime R4."
  def imprimir_r4(r4) do
    IO.puts("\n=== R4. LIQUIDACIÓN DE CONFECCIONISTAS ===")
    Enum.with_index(r4, 1) |> Enum.each(fn {r, i} ->
      IO.puts("#{i}. #{r.nombre} (#{r.codigo})")
      IO.puts("   Prendas: #{r.prendas}")
      IO.puts("   Valor de lotes: #{dinero(r.valor_lotes)}")
      IO.puts("   Bonificaciones: #{dinero(r.bonificaciones)}")
      IO.puts("   Alquiler: #{dinero(r.alquiler)}")
      IO.puts("   Neto: #{dinero(r.neto)}")
    end)
  end

  @doc "Imprime R5."
  def imprimir_r5(r5) do
    IO.puts("\n=== R5. MEJOR PRODUCCIÓN POR DÍA ===")
    Enum.each(r5.dias, fn d ->
      case d.lideres do
        [] -> IO.puts("Día #{d.dia}: sin lotes válidos")
        lideres -> IO.puts("Día #{d.dia}: #{Enum.map_join(lideres, ", ", & &1.nombre)} - #{d.prendas} prendas")
      end
    end)
    IO.puts("\nMayor cantidad de primeros lugares: #{Enum.map_join(r5.mas_primeros, ", ", & &1.nombre)}: #{r5.maximo_primeros} días")
  end

  @doc "Imprime R6."
  def imprimir_r6(r6) do
    IO.puts("\n=== R6. MEJOR CALIDAD ===")
    case r6.mejores do
      [] -> IO.puts("No hay confeccionistas con al menos 3 lotes válidos.")
      mejores -> Enum.each(mejores, fn c -> IO.puts("#{c.confeccionista.nombre} (#{c.confeccionista.codigo}) - #{Float.round(c.ponderado, 2)}% de defectos ponderados") end)
    end
  end

  @doc "Imprime R7."
  def imprimir_r7(r7) do
    IO.puts("\n=== R7. PAGO TOTAL DEL TALLER ===")
    IO.puts("Total que debe pagar el taller: #{dinero(r7.total)}")
    case r7.promedio do
      nil -> IO.puts("El promedio por prenda no puede calcularse porque no hay prendas válidas.")
      valor -> IO.puts("Costo promedio por prenda válida: #{dinero(valor)}")
    end
  end

  @doc "Imprime R8."
  def imprimir_r8(r8) do
    IO.puts("\n=== R8. CONFECCIONISTAS EN TODAS LAS LÍNEAS ===")
    case r8 do
      [] -> IO.puts("No hay confeccionistas que hayan trabajado en todas las líneas.")
      _ -> Enum.each(r8, &IO.puts("#{&1.nombre} (#{&1.codigo})"))
    end
  end

  @doc "Imprime las llamadas exigidas para C.1."
  def imprimir_c1(liquidaciones) do
    IO.puts("\n=== C.1 RANKING ===")
    IO.inspect(Reportes.ranking(liquidaciones, []), label: "Ranking por neto")
    IO.inspect(Reportes.ranking(liquidaciones, campo: :prendas, limite: 3), label: "Top 3 por prendas")
    IO.inspect(Reportes.ranking(liquidaciones, orden: :asc, campo: :bruto), label: "Ranking por bruto ascendente")
  end

  @doc "Imprime el resultado de C.2 con Map.merge/3."
  def imprimir_c2(r3) do
    produccion = Enum.into(r3.dias, %{}, &{&1.dia, &1.prendas})
    taller_aliado = %{1 => 550, 2 => 620, 3 => 480, 5 => 710, 7 => 200}
    IO.puts("\n=== C.2 COMBINAR PRODUCCIÓN ===")
    IO.inspect(Reportes.combinar_produccion(produccion, taller_aliado), label: "Producción combinada")
  end

  @doc "Solicita una consulta individual y muestra su comprobante."
  def solicitar_comprobante(confeccionistas, liquidaciones) do
    codigo = Util.ingresar("\nIngrese el código del confeccionista para consultar: ", :texto)
    case Enum.find(confeccionistas, &(&1.codigo == codigo)) do
      nil -> IO.puts("No existe un confeccionista con código #{codigo}.")
      confeccionista -> imprimir_comprobante(confeccionista, Enum.find(liquidaciones, &(&1.codigo == codigo)))
    end
  end

  @doc "Imprime el comprobante individual de un confeccionista."
  def imprimir_comprobante(confeccionista, liquidacion) do
    IO.puts("\n=== COMPROBANTE INDIVIDUAL ===")
    IO.puts("Nombre: #{confeccionista.nombre}")
    IO.puts("Código: #{confeccionista.codigo}")
    IO.puts("Detalle por día:")
    Enum.each(liquidacion.detalle, fn d -> IO.puts("Día #{d.dia}: Prendas #{d.prendas}, Valor #{dinero(d.valor)}, Bonificación #{dinero(d.bonificacion)}") end)
    IO.puts("Suma lotes #{dinero(liquidacion.valor_lotes)}; Bonificaciones #{dinero(liquidacion.bonificaciones)}; Alquiler #{dinero(liquidacion.alquiler)}; Neto #{dinero(liquidacion.neto)}.")
  end

  defp dato_lote(lote, campo) when is_map(lote), do: Map.get(lote, campo, "entrada_no_parseada")
  defp dinero(valor), do: :io_lib.format("$~.2f", [valor]) |> IO.iodata_to_binary()
end

Programa.main()
