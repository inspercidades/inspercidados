# Core data manipulation
library(dplyr)
library(stringr)
library(purrr)
library(lubridate)
library(readr)
library(cli)

# Import specific functions (3 or fewer uses)
import::from(here, here)
import::from(arrow, write_parquet)
import::from(janitor, get_dupes)
import::from(httr, HEAD, status_code, timeout)
import::from(fs, dir_create)

# Optional: keep for verbose logging
# library(tidylog)

# 1. Importa dados do Portal de Monitoramento do PDE -------------------------------------------------------------------

# Função para testar se o arquivo existe no site
check_url_exists <- function(url) {
  tryCatch(
    {
      res <- HEAD(url, timeout(2)) # tempo curto
      status_code(res) == 200
    },
    error = function(e) {
      FALSE
    }
  )
}

# Função para encontrar o arquivo mais recente disponível
find_latest_zip <- function(base_url, start_date, max_days = 365) {
  # Primeiro: busca em blocos maiores
  step_sizes <- c(7, 3, 1)
  current_date <- start_date

  cli_alert_info("Buscando arquivo mais recente")

  for (step in step_sizes) {
    found_at_least_one <- FALSE
    cli_alert_info("Procurando em intervalos de {step} dia(s)")

    # Calculate total iterations for progress bar
    iterations <- seq(0, max_days, by = step)
    cli_progress_bar("Checando datas", total = length(iterations))

    for (i in iterations) {
      date_str <- format(current_date - days(i), "%Y%m%d")
      url <- sprintf(base_url, date_str)

      if (check_url_exists(url)) {
        cli_progress_done()
        cli_alert_success("Arquivo encontrado: {date_str}")
        current_date <- as.Date(date_str, "%Y%m%d")
        found_at_least_one <- TRUE
        break
      }

      cli_progress_update()
    }

    if (!found_at_least_one) {
      cli_progress_done()
      cli_alert_warning("Nenhum arquivo encontrado neste intervalo")
      next
    }
  }

  final_url <- sprintf(base_url, format(current_date, "%Y%m%d"))
  return(final_url)
}

# URL base com espaço para a data
base_url <- "https://monitoramentopde.gestaourbana.prefeitura.sp.gov.br/app/uploads/msp_alvaras_sisacoe_aprovadigital/%s_msp_alvaras_sisacoe_aprovadigital.zip"

# Data de hoje
start_date <- Sys.Date()

# Buscar a URL do arquivo mais recente
zip_url <- find_latest_zip(base_url, start_date)

# Baixar o arquivo zip
zip_file <- basename(zip_url)
download.file(zip_url, zip_file, mode = "wb")

# Listar arquivos dentro do ZIP
# zip_contents <- archive::archive(zip_file)$path
zip_contents <- unzip(zip_file, list = TRUE)$Name

# Encontrar o CSV desejado
csv_file <- zip_contents[grepl(
  "msp_alvaras_sisacoe_aprovadigital.*\\.csv$",
  zip_contents
)]

if (length(csv_file) == 0) {
  cli::cli_abort("Nenhum arquivo CSV correspondente encontrado no ZIP.")
}

# Extrair o CSV do zip
unzip(zip_file, files = csv_file, exdir = ".")

# Lendo o arquivo
alvaras_raw <- read_csv2(
  csv_file,
  locale = locale(encoding = "ISO-8859-1"),
  show_col_types = FALSE
)

# 2. Checa atributos -----------------------------------------------------------

# Vários dados vem da camada raw como string/character
# alvaras_raw %>%
#   glimpse()

# Cria colunas ano e mes
alvaras_raw <- alvaras_raw %>%
  mutate(
    ano = ano_emissao,
    mes = ymd(paste(year(data_emissao), month(data_emissao), 1, sep = "-"))
  )

# Renomeia colunas
alvaras_raw <- alvaras_raw %>%
  rename(
    alvara = n_documento,
    descricao = assunto,
    unidade_pmsp = unid_aprov,
    sql_incra = sql,
    zona_de_uso_registro = zona_uso,
    categoria_de_uso = uso_subcat,
    area_do_terreno = area_terreno,
    area_da_construcao = ac_total,
    n_blocos = blocos,
    n_pavimentos_por_bloco = pavimentos,
    n_unidades = unid_resid,
    data_aprovacao = data_emissao,
    ano_aprovacao = ano_emissao
  )

# Cria coluna de unidades por bloco e de número total de pavimentos
alvaras_raw <- alvaras_raw %>%
  mutate(
    n_unidades_por_bloco = n_unidades / n_blocos,
    n_pavimentos = n_blocos * n_pavimentos_por_bloco
  )

d1 <- alvaras_raw |>
  mutate(
    across(everything(), ~ str_squish(str_trim(.x)))
  ) |>
  filter(!is.na(alvara)) |>
  mutate(id = row_number()) |>
  select(id, everything())

# Número de observações únicas
# map(alvaras_trimed, ~ unique(.x) %>% length())

# Número de caracteres de atributos padronizados/padronizáveis
# map(
#   alvaras_trimed[c(
#     "data_aprovacao",
#     "alvara",
#     "processo",
#     "data_autuacao",
#     "sql_incra"
#   )],
#   ~ nchar(.x) %>% unique()
# )

# Chave relacional excluindo variáveis alvo do tratamento
alvaras_key <- alvaras_trimed %>%
  select(
    -c(
      # datas
      "data_aprovacao",
      "data_autuacao",
      # numericas
      "area_do_terreno",
      "area_da_construcao",
      "n_blocos",
      "n_pavimentos_por_bloco",
      "n_unidades_por_bloco",
      "n_pavimentos",
      "n_unidades",
      "unid_his",
      "unid_hmp",
      "unid_r2h_r2v",
      "coord_x",
      "coord_y",
      # categoricas
      "ano",
      "mes",
      "descricao",
      "categoria_de_uso",
      "sql_incra",
      "endereco"
    )
  )

# 3. Ajusta datas ---------------------------------------------------------

# Variáveis de data
# alvaras_trimed %>%
#   select(starts_with("data_"))

# Mesmo padrão de data
# padroes_data_aprovacao <- alvaras_trimed %>%
#   mutate(nchar_data_aprovacao = nchar(data_aprovacao)) %>%
#   group_split(nchar_data_aprovacao)

#
# map(padroes_data_aprovacao, ~ slice_sample(.x, prop = 0.1))
# 2020-01-09 [Y-M-D]

# Cria tabela de atributos atualizados com chave relacional
atts_datas <- alvaras_trimed %>%
  select(id, starts_with("data_")) %>%
  mutate(across(
    starts_with("data_"),
    ~ case_when(
      nchar(.x) == 0 ~ NA_Date_, # Se não há caracteres, atribui NA
      nchar(.x) == 10 ~ as_date(str_replace_all(.x, "/", "-")), # Se tem 10 caracteres, converte para data
      TRUE ~ NA_Date_ # Qualquer outro caso, atribui NA
    )
  ))

# 4. Ajusta variáveis numéricas -------------------------------------------

#
alvaras_trimed %>%
  select(starts_with("n_"), starts_with("area_"), starts_with("unid_")) %>%
  glimpse()

# Cria tabela de atributos atualizados com chave relacional e ajustes
atts_numericos <- alvaras_trimed %>%
  select(
    id,
    starts_with("n_"),
    starts_with("area_"),
    starts_with("unid_"),
    starts_with("coord_")
  ) %>%
  mutate(across(everything(), as.numeric)) %>%
  # Ajusta subnotificação de NA's
  mutate(across(starts_with(c("area_", "n_")), ~ ifelse(. == 0, NA, .)))

#
# atts_numericos %>%
#   View()

# 5. Ajusta variáveis categóricas ----------------------------------------------

# A - Mês
att_mes <- alvaras_trimed %>%
  select(-starts_with("data_")) %>%
  left_join(atts_datas, by = "id") %>%
  transmute(
    id,
    mes_raw = mes,
    mes = str_to_upper(month(
      data_aprovacao,
      label = TRUE,
      abbr = FALSE
    ))
  )

att_ano <- alvaras_trimed %>%
  select(-starts_with("data_")) %>%
  left_join(atts_datas, by = "id") %>%
  transmute(id, ano_raw = ano, ano = year(data_aprovacao))

# C - Descrição
# padroes_descricao <- alvaras_trimed %>%
#   mutate(nchar_sql_incra = nchar(sql_incra)) %>%
#   group_split(nchar_sql_incra)

#
# padroes_descricao %>%
#   map(~ select(.x, id, ano, descricao))

# Definição de alvará relevante
att_descricao <- alvaras_trimed %>%
  transmute(
    id,
    descricao,
    ind_loteamento = if_else(
      str_detect(
        descricao,
        "DESMEMBRAMENTO|LOTEAMENTO|DESDOBRO|REMEMBRAMENTO|TERMO DE VERIF|Desmembramento|Loteamento"
      ),
      TRUE,
      FALSE
    ),
    ind_aprovacao = if_else(
      str_detect(descricao, "APROVACAO|Aprovação"),
      TRUE,
      FALSE
    ),
    ind_execucao = if_else(
      str_detect(descricao, "EXECUCAO|Execução"),
      TRUE,
      FALSE
    ),
    ind_conclusao = if_else(
      str_detect(descricao, "CONCLUSAO|Conclusão"),
      TRUE,
      FALSE
    ),
    ind_correcao = if_else(
      str_detect(
        descricao,
        "APOSTILAMENTO|PROJETO MODIFICATIVO|Apostilamento|Projeto Modificativo"
      ),
      TRUE,
      FALSE
    ),
    ind_edificacao_nova = if_else(
      str_detect(
        descricao,
        "EDIFICACAO NOVA|EDIFICACAONOVA|EDI-FICACAO NOVA|Edificação Nova"
      ),
      TRUE,
      FALSE
    ),
    descricao_tipo = case_when(
      ind_loteamento == TRUE ~ "PLANO INTEGRADO",
      ind_aprovacao == TRUE & ind_execucao == TRUE ~ "APROVACAO E EXECUCAO",
      ind_aprovacao == TRUE ~ "APROVACAO",
      ind_execucao == TRUE ~ "EXECUCAO",
      ind_conclusao == TRUE ~ "CONCLUSAO",
      TRUE ~ "OUTRO"
    )
    # Alvarás relevantes para M&A de licenciamentos imobiliários residenciais:
    # Aprovação, Execução ou Aprovação e Execução de Edificação Nova
    # Loteamento e Conclusão (quando lote está atribuido à edificaçao nova)
    # Dados Bloco-Pavimentos-Unidades: Aprovação, Aprovaçao e Execução
    # Casos excepcionais podem ter dados em Execução
  )

# Alvarás de interesse
# att_descricao %>%
#   #count(ind_relevante)
#   count(descricao_tipo != "OUTRO")

# Alvarás de aprovação e execução
# att_descricao %>%
#   count(ind_execucao == TRUE & ind_aprovacao == TRUE)

# D - Unidade_PMSP
# padroes_unidade_pmsp <- alvaras_trimed %>%
#   mutate(nchar_unidade_pmsp = nchar(unidade_pmsp)) %>%
#   group_split(nchar_unidade_pmsp)

# E - Processo
# padroes_processo <- alvaras_trimed %>%
#   mutate(nchar_processo = nchar(processo)) %>%
#   group_split(nchar_processo)

#
# map(
#   padroes_processo,
#   ~ .x %>%
#     select(
#       processo #, everything()
#     )
# )

# F - Categoria de uso
att_categoria_de_uso <- alvaras_trimed %>%
  transmute(
    id,
    categoria_de_uso,
    ind_r2v = if_else(str_detect(categoria_de_uso, "R2V"), TRUE, FALSE),
    ind_r2h = if_else(str_detect(categoria_de_uso, "R2H"), TRUE, FALSE),
    ind_his = if_else(str_detect(categoria_de_uso, "HIS|H.I.S"), TRUE, FALSE),
    ind_hmp = if_else(str_detect(categoria_de_uso, "HMP|H.M.P"), TRUE, FALSE),
    ind_ezeis = if_else(str_detect(categoria_de_uso, "EZEIS"), TRUE, FALSE)
  )
#
# att_categoria_de_uso %>%
#   count(ind_his)

# G - SQL_INCRA
# padroes_sql_incra <- alvaras_trimed %>%
#   mutate(nchar_sql_incra = nchar(sql_incra)) %>%
#   group_split(nchar_sql_incra)

# Alguns alvarás provenientes do Aprova Digital vêm com mais de um SQL e mais de um endereço
# (não necessariamente o mesmo número de SQLs e endereços)
# map(
#   padroes_sql_incra,
#   ~ .x %>%
#     select(sql_incra, nchar_sql_incra, everything())
# )

#
att_sql_incra <- alvaras_trimed %>%
  transmute(
    id,
    sql_incra, #nchar_sql_incra = nchar(sql_incra),
    sql_incra_11 = case_when(
      nchar(sql_incra) == 0 ~ NA_character_,
      nchar(sql_incra) > 11 ~ substr(sql_incra, 1, 11),
      TRUE ~ sql_incra
    ),
    ind_sql_incra_null = if_else(is.na(sql_incra_11), TRUE, FALSE),
    ind_incra = if_else(ind_sql_incra_null == FALSE, TRUE, FALSE),
  )


# G - Endereço

#
att_endereco <- alvaras_trimed %>%
  transmute(
    id,
    data_aprovacao = case_when(
      nchar(data_aprovacao) == 0 ~ NA_Date_, # Se não há caracteres, atribui NA
      nchar(data_aprovacao) == 10 ~ as_date(str_replace_all(
        data_aprovacao,
        "/",
        "-"
      )), # Se tem 10 caracteres, converte para data
      TRUE ~ NA_Date_
    ),
    endereco_raw = endereco,
    endereco_unico = case_when(
      nchar(sql_incra) > 11 ~ sub(";.*", "", endereco),
      TRUE ~ endereco
    ),
    endereco_ajust_1 = str_remove_all(endereco_unico, ",SN|S/N"),
    logradouro = case_when(
      str_detect(endereco_ajust_1, "[0-9]\\'") ~ endereco_unico,
      str_detect(endereco_ajust_1, ",") ~ str_split(endereco_ajust_1, ",") %>%
        map_chr(~ .x[1]),
      TRUE ~ str_split(endereco_ajust_1, "(?<=[a-zA-Z])\\s*(?=[0-9])") %>%
        map_chr(~ .x[1])
    ),
    numero = case_when(
      # Casos onde "KM" está presente (ex., "Rodovia Anhanguera KM 32,5")
      str_detect(endereco_ajust_1, "\\sKM\\s") ~ str_extract(
        endereco_ajust_1,
        "KM.*"
      ) %>%
        str_replace_all(",", ".") %>%
        str_extract(pattern = "[-+]?[0-9]*\\.?[0-9]+") %>%
        str_replace_all("\\s", "") %>%
        as.numeric() %>%
        as.character(),

      # Casos onde um número está entre apóstofres (ex., "Rua X, '123'")
      str_detect(endereco_ajust_1, "[0-9]\\'") ~ str_extract(
        endereco_unico,
        "\\'.*"
      ) %>%
        str_extract(pattern = "[-+]?[0-9]*\\.?[0-9]+") %>%
        as.numeric() %>%
        as.character(),

      # Casos onde o número está entre duas vírgulas em um intervalo
      str_detect(endereco_ajust_1, ",\\s*\\d{1,5}(\\.\\d{3})?,") ~ str_extract(
        endereco_ajust_1,
        ",\\s*\\d{1,5}(\\.\\d{3})?"
      ) %>%
        str_replace_all(",", "") %>% # Remove leading comma
        str_replace_all("\\.", "") %>% # Remove dot inside numbers (e.g., "1.584" → "1584")
        str_extract("\\d+") %>% # Extract only the number
        as.character(),

      # Caso base: extrai a primeira ocorrência
      TRUE ~ str_extract(
        endereco_ajust_1,
        pattern = "[-+]?[0-9]*\\.?[0-9]+"
      ) %>%
        as.numeric() %>%
        as.character()
    ) %>%
      # Convert "99999" to NA
      na_if("99999"),
    endereco_ajust_2 = case_when(
      str_detect(endereco_ajust_1, "\\sKM\\s") ~ paste0(
        logradouro,
        " KM ",
        numero
      ),
      str_detect(endereco_ajust_1, "[0-9]\\'") ~ endereco_ajust_1,
      numero >= 0 & !is.na(numero) ~ paste0(logradouro, " ", numero),
      TRUE ~ logradouro
    ) %>%
      str_replace_all(",", " "),
    subprefeitura,
    endereco_clean = str_remove(
      endereco_ajust_2,
      "R |AV |ES |EST |VIA |AL |PC |PG |LV |TV |PV |LG |VD |RV |PQ |VP |RUA |Av. |Rua |PRAÇA |rua |AVENIDA |Avenida |Alameda |av |R. |AV. |Av "
    )
  ) %>%
  # Para garantir a não-duplicação de endereços por falta de tipo de logradouro
  # Importante também chave secundária de subprefeitura para evitar unificação equivocada
  # Ex: Rua/Avenida/Alameda Santo Amaro
  group_by(endereco_clean, subprefeitura) %>%
  # Toma informação mais recente como referência
  arrange(desc(data_aprovacao)) %>%
  mutate(
    endereco = first(endereco_ajust_2) #,
    #ind_diff_endereco = if_else(endereco_ajust_2 != endereco, TRUE, FALSE)
  ) %>%
  ungroup()

# Cria tabela de atributos atualizados com chave relacional
att_categoricos <- list(
  att_ano,
  att_mes,
  att_descricao,
  att_categoria_de_uso,
  att_sql_incra,
  att_endereco %>%
    select(-c(data_aprovacao, subprefeitura))
) %>%
  reduce(left_join, by = "id")

# 6. Cria conjunto de dados ----------------------------------------------------

#
alvaras_trusted_not_unique <- list(
  alvaras_key,
  atts_datas,
  atts_numericos,
  att_categoricos
) %>%
  reduce(left_join, by = "id") %>%
  select(
    id,
    data_aprovacao,
    mes,
    ano,
    alvara,
    descricao,
    descricao_tipo,
    unidade_pmsp,
    processo,
    data_autuacao,
    categoria_de_uso,
    area_do_terreno,
    area_da_construcao,
    n_blocos,
    n_pavimentos_por_bloco,
    n_unidades_por_bloco,
    n_pavimentos,
    n_unidades,
    unid_his,
    unid_hmp,
    unid_r2h_r2v,
    sql_incra_11,
    sql_incra,
    endereco_raw,
    endereco_unico,
    endereco,
    distrito,
    subprefeitura,
    zona_de_uso_registro,
    coord_x,
    coord_y,
    georref_nivel,
    georref_modo,
    starts_with("ind_")
  )

# 0 alvarás com número de alvará duplicado
# alvaras_trusted_not_unique %>%
#   get_dupes(alvara) %>%
#   count(descricao_tipo != "Outro" & ind_edificacao_nova == TRUE)

# Número duplicado, entretanto, não indica necessariamente mesmo alvará!
# Para correção, mantém-se tratamento dado no script Java
# Considerada duplicata Somente se idênticos: {unidade_pmsp, subprefeitura, alvara,
# data_aprovacao, data_autuacao, descricao, endereco, sql_incra}
#
# alvaras_duplicatas <- alvaras_trusted_not_unique %>%
#   get_dupes(
#     unidade_pmsp,
#     subprefeitura,
#     alvara,
#     data_aprovacao,
#     data_autuacao,
#     descricao,
#     endereco_raw,
#     sql_incra
#   )

#
alvaras_trusted <- alvaras_trusted_not_unique %>%
  distinct(
    unidade_pmsp,
    subprefeitura,
    alvara,
    data_aprovacao,
    data_autuacao,
    descricao,
    endereco_raw,
    sql_incra,
    .keep_all = TRUE
  )

# Alvarás relevantes
# alvaras_trusted %>%
#   #count(ind_relevante)
#   count(descricao_tipo != "Outro" & ind_edificacao_nova == TRUE)

# Alvarás relevantes com codigo SQL inválido
# alvaras_trusted %>%
#   count(
#     is.na(sql_incra_11) &
#       descricao_tipo != "Outro" &
#       ind_edificacao_nova == TRUE
#   )

# 7. Exporta -------------------------------------------------------------------

# Assegura a existência do diretório para exportação
fs::dir_create(here("data"))

# Exporta alvarás individualizados
arrow::write_parquet(
  alvaras_trusted,
  here("data", "alvaras_pde.parquet")
)

readr::write_csv(alvaras_trusted, here("data", "alvaras_pde.csv"))
readr::write_rds(alvaras_trusted, here("data", "alvaras_pde.rds"))
writexl::write_xlsx(alvaras_trusted, here("data", "alvaras_pde.xlsx"))
