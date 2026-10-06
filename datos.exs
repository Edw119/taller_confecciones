defmodule Datos do
  @moduledoc """
  Datos de prueba del taller de confeccion.
  """

  @doc """
  Retorna los confeccionistas del taller.
  """
  def confeccionistas do
    [
      %{codigo: "C01", nombre: "Maria Elena Rios", alquiler: true},
      %{codigo: "C02", nombre: "Andres Salazar", alquiler: false},
      %{codigo: "C03", nombre: "Carlos Gomez", alquiler: true},
      %{codigo: "C04", nombre: "Laura Martinez", alquiler: false},
      %{codigo: "C05", nombre: "Sofia Ramirez", alquiler: true},
      %{codigo: "C06", nombre: "Diego Herrera", alquiler: false},
      %{codigo: "C07", nombre: "Valentina Lipez", alquiler: true},
      %{codigo: "C08", nombre: "Juan Esteban Torres", alquiler: false},
      %{codigo: "C09", nombre: "Camila Restrepo", alquiler: true},
      %{codigo: "C10", nombre: "Mateo Vargas", alquiler: false}
    ]
  end

  @doc """
  Retorna las lineas de producciin.
  """
  def lineas do
    [
      %{id: "L1", nombre: "Linea Norte", puestos: 6},
      %{id: "L2", nombre: "Linea Central", puestos: 4},
      %{id: "L3", nombre: "Linea Sur", puestos: 5},
      %{id: "L4", nombre: "Linea Oriente", puestos: 3}
    ]
  end

  @doc """
  Retorna 84 lotes validos y 10 lotes invalidos de prueba.
  """
  def lotes do
    validos =
      for dia <- 1..6,
          indice <- 1..14 do
        codigo = "C#{rem((dia - 1) * 14 + indice - 1, 10) + 1 |> Integer.to_string() |> String.pad_leading(2, "0")}"
        linea = "L#{rem(indice - 1, 4) + 1}"
        prendas = 70 + rem(dia * 13 + indice * 7, 91)
        defectos =
          case rem(dia + indice, 4) do
            0 -> 1.5
            1 -> 3.0
            2 -> 7.0
            _ -> 12.0
          end

        %{confeccionista: codigo, linea: linea, dia: dia, prendas: prendas, defectos: defectos}
      end

    ejemplo = [
      %{confeccionista: "C01", linea: "L1", dia: 1, prendas: 70, defectos: 1.5},
      %{confeccionista: "C01", linea: "L2", dia: 1, prendas: 55, defectos: 7.0},
      %{confeccionista: "C01", linea: "L1", dia: 2, prendas: 90, defectos: 12.0}
    ]

    validos = Enum.drop(validos, 3) ++ ejemplo

    invalidos = [
      %{confeccionista: "C99", linea: "L1", dia: 1, prendas: 50, defectos: 2.0},
      %{confeccionista: "C98", linea: "L2", dia: 2, prendas: 60, defectos: 3.0},
      %{confeccionista: "C01", linea: "L99", dia: 1, prendas: 50, defectos: 2.0},
      %{confeccionista: "C02", linea: "L99", dia: 2, prendas: 60, defectos: 3.0},
      %{confeccionista: "C03", linea: "L1", dia: 0, prendas: 50, defectos: 2.0},
      %{confeccionista: "C04", linea: "L2", dia: 7, prendas: 60, defectos: 3.0},
      %{confeccionista: "C05", linea: "L1", dia: 1, prendas: 0, defectos: 2.0},
      %{confeccionista: "C06", linea: "L2", dia: 2, prendas: 181, defectos: 3.0},
      %{confeccionista: "C07", linea: "L1", dia: 1, prendas: 50, defectos: -1.0},
      %{confeccionista: "C08", linea: "L2", dia: 2, prendas: 60, defectos: 101.0}
    ]

    validos ++ invalidos
  end
end
