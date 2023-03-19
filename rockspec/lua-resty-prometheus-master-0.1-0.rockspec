package = "lua-resty-prometheus-master"
version = "0.1-0"
source = {
   url = "git://github.com/tzssangglass/lua-resty-prometheus",
   branch = "master",
}

description = {
   summary = "Prometheus metric library for OpenResty",
   homepage = "https://github.com/tzssangglass/lua-resty-prometheus",
   license = "Apache License 2.0",
   maintainer = "ZhengSong Tu <tzssangglass@apache.com>"
}

dependencies = {
   "lua-resty-lmdb = 1.0.0",
}

build = {
   type = "builtin",
   modules = {
   }
}
