# -- Project information -------------------------------------------------------
project = "Controlador VGA em FPGA"
author = "Grupo 1 – CI Digital"
copyright = "2026, Grupo 1"
release = "1.0"

# -- General configuration ----------------------------------------------------
extensions = [
    "myst_parser",
    "sphinxcontrib.mermaid",
    "sphinx_copybutton",
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

html_js_files = [
    "js/svg-pan-zoom.min.js",
    "js/mermaid-zoom.js",
]

html_theme_options = {
    "sidebar_hide_name": False,
    "navigation_with_keys": True,
    "light_css_variables": {
        "color-sidebar-link-text": "black",
        "color-sidebar-link-text--top-level": "black",
    },
    "dark_css_variables": {
        "color-sidebar-link-text": "white",
        "color-sidebar-link-text--top-level": "white",
    },
}

# -- Mermaid -------------------------------------------------------------------
mermaid_version = "10.9.0"
