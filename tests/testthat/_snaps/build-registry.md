# catalog schema errors name missing fields

    Code
      validate_catalog_schema(catalog)
    Condition
      Error in `validate_catalog_schema()`:
      ! The catalog schema is invalid.
      x Missing 1 column: filtro_tema
      i Restore the missing column in the Google Sheet and run the script again.

# catalog validation collects manual input errors

    Code
      validate_catalog(catalog)
    Condition
      Error in `validate_catalog()`:
      ! Catalog validation failed with 3 issues.
      x Google Sheet row 3 [filtro_tema]: unknown theme 'Transportes'; use one of: Clima e Meio Ambiente, Educação, Habitação e Mercado Imobiliário, Mobilidade, Multidisciplinar e transversal, Saúde, Trabalho e renda
      x Google Sheet row 3 [keywords]: expected 3 to 5 keywords, found 2
      x Google Sheet row 3 [keywords]: duplicated keyword(s): Mobilidade Urbana
      i Fix these values in the Google Sheet and run `Rscript data-raw/build_registry.R` again. No registry files were written.

