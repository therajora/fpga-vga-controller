# -- Project information -------------------------------------------------------
project = "Controlador VGA em FPGA"
author = "Grupo 1 – CI Digital"
copyright = "2026, Grupo 1"
release = "1.0"

# -- General configuration ----------------------------------------------------
extensions = [
    "myst_parser",
    "sphinxcontrib.mermaid",
]

myst_enable_extensions = [
    "colon_fence",
    "fieldlist",
    "dollarmath",
]

templates_path = ["_templates"]
exclude_patterns = ["_build", ".venv", "Thumbs.db", ".DS_Store"]

language = "pt_BR"
source_suffix = {".rst": "restructuredtext", ".md": "markdown"}

# -- HTML output ---------------------------------------------------------------
html_theme = "furo"
html_title = "Controlador VGA em FPGA"
html_static_path = ["_static"]

html_theme_options = {
    "sidebar_hide_name": False,
    "navigation_with_keys": True,
}

# -- Mermaid -------------------------------------------------------------------
