PDFLATEX ?= pdflatex
PDFLATEX_FLAGS ?= -interaction=nonstopmode -halt-on-error

.PHONY: all clean

all: Sppe.pdf

Sppe.pdf: Sppe.tex cesm215_sppe_namelist.tex fontawesome-icons.tex
	@if command -v $(PDFLATEX) >/dev/null 2>&1; then \
		$(PDFLATEX) $(PDFLATEX_FLAGS) Sppe.tex && \
		$(PDFLATEX) $(PDFLATEX_FLAGS) Sppe.tex; \
	else \
		bash -lc 'module load stack/2025-06 gcc/12.2.0 texlive/20240312 && \
		cd "$(CURDIR)" && $(PDFLATEX) $(PDFLATEX_FLAGS) Sppe.tex && \
		$(PDFLATEX) $(PDFLATEX_FLAGS) Sppe.tex'; \
	fi

clean:
	$(RM) Sppe.aux Sppe.log Sppe.out Sppe.toc
