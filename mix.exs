defmodule PlugHeadersBouncer.Mixfile do
  use Mix.Project

  def project do
    [
      app: :plug_headers_bouncer,
      version: "0.1.0",
      elixir: "~> 1.5",
      deps: deps()
    ]
  end

  def application do
    []
  end

  defp deps do
    [
      {:plug, "~> 1.4"},
      {:poison, "~> 3.1"},
      {:ex_doc, "~> 0.18", only: :dev, runtime: false},
      {:earmark, "~> 1.2", only: :dev, runtime: false},
      {:dialyxir, "~> 0.5", only: :dev, runtime: false}
    ]
  end
end
