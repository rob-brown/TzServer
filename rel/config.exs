Path.join(["rel", "plugins", "*.exs"])
|> Path.wildcard()
|> Enum.map(&Code.eval_file(&1))

use Mix.Releases.Config,
    default_release: :default,
    default_environment: :prod

environment :dev do
  set dev_mode: true
  set include_erts: false
  set cookie: :"k*900oqVG}vXYr}@7eRkE(15>LB|m,&>oLK_5L~D*rzpazSweAzanHVuUwKtxVlo"
end

environment :prod do
  set include_erts: false
  set include_src: false
  set cookie: :".SlSY^9soe7|lo}UuDXHU&;7Gdc;fJkyZ1?7:~Xs~F}by0j&x&GtdDx[1U<;1aiG"
end

release :tz_server do
  set version: current_version(:tz_server)
  set applications: [
    :runtime_tools
  ]
end
