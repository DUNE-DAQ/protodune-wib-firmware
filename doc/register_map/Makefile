all:  register_map.pdf

register_map.pdf: register_map.tex
	pdflatex $<

register_map.tex: ../../src/register_map/register_map.vhd
	./generate_daq_reg_map.py $<

clean:
	@rm -f register_map.tex register_map.aux register_map.log register_map.pdf
