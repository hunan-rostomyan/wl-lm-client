main_in=main.elm
main_out=main.js

compile:
	elm make $(main_in) --output $(main_out)
