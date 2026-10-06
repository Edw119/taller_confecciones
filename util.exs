defmodule Util do
  @moduledoc "Funciones de entrada y salida usadas por la interfaz."

  @doc "Muestra un mensaje en salida estándar."
  def mostrar_mensaje(mensaje) do
    IO.puts(mensaje)
  end

  @doc "Muestra un mensaje en la salida de errores."
  def mostrar_error(mensaje) do
    IO.puts(:standard_error, mensaje)
  end

  @doc "Lee texto desde consola y elimina espacios externos."
  def ingresar(mensaje, :texto) do
    case IO.gets(mensaje) do
      nil -> ""
      texto -> String.trim(texto)
    end
  end

  @doc "Lee un entero sin usar excepciones y devuelve una tupla."
  def ingresar(mensaje, :entero) do
    mensaje
    |> ingresar(:texto)
    |> parsear_entero()
  end

  @doc "Lee un número real sin usar excepciones y devuelve una tupla."
  def ingresar(mensaje, :real) do
    mensaje
    |> ingresar(:texto)
    |> parsear_real()
  end

  @doc "Convierte una cadena a entero solamente si toda la cadena es válida."
  def parsear_entero(texto) do
    case Integer.parse(String.trim(texto)) do
      {valor, ""} -> {:ok, valor}
      _ -> {:error, :entero_invalido}
    end
  end

  @doc "Convierte una cadena a real solamente si toda la cadena es válida."
  def parsear_real(texto) do
    case Float.parse(String.trim(texto)) do
      {valor, ""} -> {:ok, valor}
      _ -> {:error, :real_invalido}
    end
  end

  @doc "Analiza una línea de lote y retorna {:ok, lote} o {:error, :formato_invalido}."
  def parsear_lote(texto) do
    case String.split(String.trim(texto), ";") do
      [confeccionista, linea, dia, prendas, defectos] ->
        with {:ok, dia_valor} <- parsear_entero(dia),
             {:ok, prendas_valor} <- parsear_entero(prendas),
             {:ok, defectos_valor} <- parsear_real(defectos) do
          {:ok,
           %{confeccionista: String.trim(confeccionista), linea: String.trim(linea),
             dia: dia_valor, prendas: prendas_valor, defectos: defectos_valor}}
        else
          _ -> {:error, :formato_invalido}
        end

      _ -> {:error, :formato_invalido}
    end
  end
end
