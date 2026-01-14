# Multilateral diagnostics

Repository for the research project on diagnostics for produciton multilateral price index methods. 

# Repo folder structure

```
├── data                    # Placeholder folders for the data
│   ├── raw                 # For raw open data
│   └── clean               # For cleaned datasets that can be used for downstream analysis
│
├── src                     # Source code to process data and generate dashboards rendered on the quarto site
│
├── output/                 # Generated data and artifacts
│   ├── figures/            # Figures embedded into the paper
│   └── tables/             # Output data
│
├── project-content/        # Organizational aspects of the project (not part of the static site)
│   ├── charter.md          # Project charter to outline scope and project structure
│   └── dmp.md              # Data management plan
│
└── docs/                   # Project site/manuscript rendered with Quarto
    ├── paper.qmd           # The main manuscript
    ├── presentation.qmd    # Presentation slides
    ├── references.bib      # Bibliography
    └── *.qmd               # Other quarto files to explain and visualize project info
```
