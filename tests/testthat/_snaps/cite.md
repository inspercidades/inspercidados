# citation formatters produce stable output

    Code
      cat(format_text(authors, "2025", "Base de Teste", doi_to_url(doi)))
    Output
      Oike, Vinicius; Insper Cidades (2025). Base de Teste. Insper Dataverse. https://doi.org/10.60873/FK2/TOXCRF
    Code
      cat(format_bibtex(authors, "2025", "Base de Teste", doi))
    Output
      @dataset{Oike2025,
        author    = {Oike, Vinicius; Insper Cidades},
        title     = {Base de Teste},
        year      = {2025},
        publisher = {Insper Dataverse},
        doi       = {10.60873/FK2/TOXCRF}
      }
    Code
      cat(format_ris(authors, "2025", "Base de Teste", doi_to_url(doi)))
    Output
      TY  - DATA
      AU  - Oike, Vinicius
      AU  - Insper Cidades
      TI  - Base de Teste
      PY  - 2025
      PB  - Insper Dataverse
      DO  - https://doi.org/10.60873/FK2/TOXCRF
      ER  -

