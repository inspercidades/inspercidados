# Spatial and data manipulation
library(sf)
library(dplyr)
library(stringr)

# Import specific functions (3 or fewer uses)
import::from(fs, dir_create)
import::from(here, here)
import::from(tidygeocoder, geocode)
import::from(sfarrow, st_write_parquet)
import::from(arrow, read_parquet)

# Optional: keep for verbose logging
# library(tidylog)

# 1. Importa --------------------------------------------------------------

#
alvaras <- read_parquet(here("data", "alvaras_pde.parquet"))

# Para checagem da geocodificação
sf_geo_sp <- st_read(here(
  "data-raw",
  "Subprefeituras",
  "SubprefectureMSP_SIRGAS.shp"
)) %>%
  #st_set_crs(CRS) %>%
  st_transform(crs = 31983)

# 2. Geocodifica 1/2 -----------------------------------------------------------

# 1/2 - Geocode utilizando as coordenadas fornecidas diretamente na base (SIRGAS 2000)

# Filtrando os que possuem coordenadas
alvaras_1 <- alvaras %>% filter(!is.na(coord_x))

# Convertendo para um objeto sf
alvaras_1 <- st_as_sf(alvaras_1, coords = c("coord_x", "coord_y"), crs = 31983)


# 3. Geocodifica 2/2 -----------------------------------------------------------

# 2/2 - Geocode pelo API do ArcGis

# Filtrando os que não possuem coordenadas
alvaras_2 <- alvaras %>% filter(is.na(coord_x))

# Removendo observações onde o endereço é composto somente de números e onde não temos precisão
alvaras_2 <- alvaras_2 %>%
  filter(
    str_detect(endereco, "[A-Za-z]"), # exclui observações com apenas números
    !str_detect(endereco, "\\b0\\b"), # remove "0" isolado
    !str_detect(endereco, "\\b999999\\b"), # remove "999999"
    str_detect(endereco, "\\d"), # mantém apenas os que têm ao menos um número
    !str_detect(endereco, "\\bKM\\b") # remove "KM" isolado
  )

# API comunidade ArcGIS: https://developers.arcgis.com/rest/
alvaras_2 <- tidygeocoder::geocode(
  alvaras_2 %>%
    mutate(
      endereco_key = if_else(
        !is.na(distrito),
        paste0(endereco, " ", distrito, " SAO PAULO SP"),
        paste0(endereco, " ", subprefeitura, " SAO PAULO SP")
      ) %>%
        str_remove_all(";|_|/") %>%
        str_squish(),
      # city = "São Paulo",
      # state = "SP"
    ),
  address = "endereco_key",
  method = "arcgis"
)

# Transforma em um dataframe sf
alvaras_2 <- alvaras_2 %>%
  st_as_sf(coords = c("long", "lat"), crs = 4326) %>%
  select(-c(endereco_key, coord_x, coord_y))

# Converte o CRS
alvaras_2 <- st_transform(alvaras_2, crs = 31983)

# 5. Unifica tabelas geocodificadas em uma -------------------------------------

#
# all.equal(
#   order(names(alvaras_1)),
#   order(names(alvaras_2))
# )

# Tipos de geometria devem ser idênticos (pontos)
# all.equal(
#   all(st_geometry_type(alvaras_1) == "POINT"),
#   all(st_geometry_type(alvaras_2) == "POINT")
# )

# Sistemas CRS devem ser idênticos
# all.equal(
#   st_crs(alvaras_1),
#   st_crs(alvaras_2)
#   )

# Todos os pontos devem estar dentro do perímetro de São Paulo
# all.equal(
#   length(st_filter(alvaras_1, sf_geo_sp)) == length(alvaras_1),
#   length(st_filter(alvaras_2, sf_geo_sp)) == length(alvaras_2)
#   )

# Junta linhas
geo_alvaras <- bind_rows(
  alvaras_1,
  alvaras_2
)


# 6. Exporta --------------------------------------------------------------

#
dir_create(here("data"))

#
st_write_parquet(geo_alvaras, here("data", "geo_alvaras_pde.parquet"))
st_write(geo_alvaras, here("data", "geo_alvaras_pde.gpkg"))
st_write(geo_alvaras, here("data", "geo_alvaras_pde.shp"))

# beepr::beep(8)
