(kicad_sch
	(version 20231120)
	(generator "eeschema")
	(generator_version "8.0")
	(uuid "02b1dd05-420e-48b3-9ee8-c9edbf2413ac")
	(paper "A4")
	(title_block
		(title "Fast SPI interface + RTC sidecar")
		(date "2024-10-28")
		(rev "v1.0")
		(company "@zuiko21")
		(comment 1 "(c) 2023-2024 Carlos J. Santisteban")
	)
	(lib_symbols
		(symbol "74xx:74HC245"
			(pin_names
				(offset 1.016)
			)
			(exclude_from_sim no)
			(in_bom yes)
			(on_board yes)
			(property "Reference" "U"
				(at -7.62 16.51 0)
				(effects
					(font
						(size 1.27 1.27)
					)
				)
			)
			(property "Value" "74HC245"
				(at -7.62 -16.51 0)
				(effects
					(font
						(size 1.27 1.27)
					)
				)
			)
			(property "Footprint" ""
				(at 0 0 0)
				(effects
					(font
						(size 1.27 1.27)
					)
					(hide yes)
				)
			)
			(property "Datasheet" "http://www.ti.com/lit/gpn/sn74HC245"
				(at 0 0 0)
				(effects
					(font
						(size 1.27 1.27)
					)
					(hide yes)
				)
			)
			(property "Description" "Octal BUS Transceivers, 3-State outputs"
				(at 0 0 0)
				(effects
					(font
						(size 1.27 1.27)
					)
					(hide yes)
				)
			)
			(property "ki_locked" ""
				(at 0 0 0)
				(effects
					(font
						(size 1.27 1.27)
					)
				)
			)
			(property "ki_keywords" "HCMOS BUS 3State"
				(at 0 0 0)
				(effects
					(font
						(size 1.27 1.27)
					)
					(hide yes)
				)
			)
			(property "ki_fp_filters" "DIP?20*"
				(at 0 0 0)
				(effects
					(font
						(size 1.27 1.27)
					)
					(hide yes)
				)
			)
			(symbol "74HC245_1_0"
				(polyline
					(pts
						(xy -0.635 -1.27) (xy -0.635 1.27) (xy 0.635 1.27)
					)
					(stroke
						(width 0)
						(type default)
					)
					(fill
						(type none)
					)
				)
				(polyline
					(pts
						(xy -1.27 -1.27) (xy 0.635 -1.27) (xy 0.635 1.27) (xy 1.27 1.27)
					)
					(stroke
						(width 0)
						(type default)
					)
					(fill
						(type none)
					)
				)
				(pin input line
					(at -12.7 -10.16 0)
					(length 5.08)
					(name "A->B"
						(effects
							(font
								(size 1.27 1.27)
							)
						)
					)
					(number "1"
						(effects
							(font
								(size 1.27 1.27)
							)
						)
					)
				)
				(pin power_in line
					(at 0 -20.32 90)
					(length 5.08)
					(name "GND"
						(effects
							(font
								(size 1.27 1.27)
							)
						)
					)
					(number "10"
						(effects
							(font
								(size 1.27 1.27)
							)
						)
					)
				)
				(pin tri_state line
					(at 12.7 -5.08 180)
					(length 5.08)
					(name "B7"
						(effects
							(font
								(size 1.27 1.27)
							)
						)
					)
					(number "11"
						(effects
							(font
								(size 1.27 1.27)
							)
						)
					)
				)
				(pin tri_state line
					(at 12.7 -2.54 180)
					(length 5.08)
					(name "B6"
						(effects
							(font
								(size 1.27 1.27)
							)
						)
					)
					(number "12"
						(effects
							(font
								(size 1.27 1.27)
							)
						)
					)
				)
				(pin tri_state line
					(at 12.7 0 180)
					(length 5.08)
					(name "B5"
						(effects
							(font
								(size 1.27 1.27)
							)
						)
					)
					(number "13"
						(effects
							(font
								(size 1.27 1.27)
							)
						)
					)
				)
				(pin tri_state line
					(at 12.7 2.54 180)
					(length 5.08)
					(name "B4"
						(effects
							(font
								(size 1.27 1.27)
							)
						)
					)
					(number "14"
						(effects
							(font
								(size 1.27 1.27)
							)
						)
					)
				)
				(pin tri_state line
					(at 12.7 5.08 180)
					(length 5.08)
					(name "B3"
						(effects
							(font
								(size 1.27 1.27)
							)
						)
					)
					(number "15"
						(effects
							(font
								(size 1.27 1.27)
							)
						)
					)
				)
				(pin tri_state line
					(at 12.7 7.62 180)
					(length 5.08)
					(name "B2"
						(effects
							(font
								(size 1.27 1.27)
							)
						)
					)
					(number "16"
						(effects
							(font
								(size 1.27 1.27)
							)
						)
					)
				)
				(pin tri_state line
					(at 12.7 10.16 180)
					(length 5.08)
					(name "B1"
						(effects
							(font
								(size 1.27 1.27)
							)
						)
					)
					(number "17"
						(effects
							(font
								(size 1.27 1.27)
							)
						)
					)
				)
				(pin tri_state line
					(at 12.7 12.7 180)
					(length 5.08)
					(name "B0"
						(effects
							(font
								(size 1.27 1.27)
							)
						)
					)
					(number "18"
						(effects
							(font
								(size 1.27 1.27)
							)
						)
					)
				)
				(pin input inverted
					(at -12.7 -12.7 0)
					(length 5.08)
					(name "CE"
						(effects
							(font
								(size 1.27 1.27)
							)
						)
					)
					(number "19"
						(effects
							(font
								(size 1.27 1.27)
							)
						)
					)
				)
				(pin tri_state line
					(at -12.7 12.7 0)
					(length 5.08)
					(name "A0"
						(effects
							(font
								(size 1.27 1.27)
							)
						)
					)
					(number "2"
						(effects
							(font
								(size 1.27 1.27)
							)
						)
					)
				)
				(pin power_in line
					(at 0 20.32 270)
					(length 5.08)
					(name "VCC"
						(effects
							(font
								(size 1.27 1.27)
							)
						)
					)
					(number "20"
						(effects
							(font
								(size 1.27 1.27)
							)
						)
					)
				)
				(pin tri_state line
					(at -12.7 10.16 0)
					(length 5.08)
					(name "A1"
						(effects
							(font
								(size 1.27 1.27)
							)
						)
					)
					(number "3"
						(effects
							(font
								(size 1.27 1.27)
							)
						)
					)
				)
				(pin tri_state line
					(at -12.7 7.62 0)
					(length 5.08)
					(name "A2"
						(effects
							(font
								(size 1.27 1.27)
							)
						)
					)
					(number "4"
						(effects
							(font
								(size 1.27 1.27)
							)
						)
					)
				)
				(pin tri_state line
					(at -12.7 5.08 0)
					(length 5.08)
					(name "A3"
						(effects
							(font
								(size 1.27 1.27)
							)
						)
					)
					(number "5"
						(effects
							(font
								(size 1.27 1.27)
							)
						)
					)
				)
				(pin tri_state line
					(at -12.7 2.54 0)
					(length 5.08)
					(name "A4"
						(effects
							(font
								(size 1.27 1.27)
							)
						)
					)
					(number "6"
						(effects
							(font
								(size 1.27 1.27)
							)
						)
					)
				)
				(pin tri_state line
					(at -12.7 0 0)
					(length 5.08)
					(name "A5"
						(effects
							(font
								(size 1.27 1.27)
							)
						)
					)
					(number "7"
						(effects
							(font
								(size 1.27 1.27)
							)
						)
					)
				)
				(pin tri_state line
					(at -12.7 -2.54 0)
					(length 5.08)
					(name "A6"
						(effects
							(font
								(size 1.27 1.27)
							)
						)
					)
					(number "8"
						(effects
							(font
								(size 1.27 1.27)
							)
						)
					)
				)
				(pin tri_state line
					(at -12.7 -5.08 0)
					(length 5.08)
					(name "A7"
						(effects
							(font
								(size 1.27 1.27)
							)
						)
					)
					(number "9"
						(effects
							(font
								(size 1.27 1.27)
							)
						)
					)
				)
			)
			(symbol "74HC245_1_1"
				(rectangle
					(start -7.62 15.24)
					(end 7.62 -15.24)
					(stroke
						(width 0.254)
						(type default)
					)
					(fill
						(type background)
					)
				)
			)
		)
		(symbol "74xx:74HC595"
			(exclude_from_sim no)
			(in_bom yes)
			(on_board yes)
			(property "Reference" "U"
				(at -7.62 13.97 0)
				(effects
					(font
						(size 1.27 1.27)
					)
				)
			)
			(property "Value" "74HC595"
				(at -7.62 -16.51 0)
				(effects
					(font
						(size 1.27 1.27)
					)
				)
			)
			(property "Footprint" ""
				(at 0 0 0)
				(effects
					(font
						(size 1.27 1.27)
					)
					(hide yes)
				)
			)
			(property "Datasheet" "http://www.ti.com/lit/ds/symlink/sn74hc595.pdf"
				(at 0 0 0)
				(effects
					(font
						(size 1.27 1.27)
					)
					(hide yes)
				)
			)
			(property "Description" "8-bit serial in/out Shift Register 3-State Outputs"
				(at 0 0 0)
				(effects
					(font
						(size 1.27 1.27)
					)
					(hide yes)
				)
			)
			(property "ki_keywords" "HCMOS SR 3State"
				(at 0 0 0)
				(effects
					(font
						(size 1.27 1.27)
					)
					(hide yes)
				)
			)
			(property "ki_fp_filters" "DIP*W7.62mm* SOIC*3.9x9.9mm*P1.27mm* TSSOP*4.4x5mm*P0.65mm* SOIC*5.3x10.2mm*P1.27mm* SOIC*7.5x10.3mm*P1.27mm*"
				(at 0 0 0)
				(effects
					(font
						(size 1.27 1.27)
					)
					(hide yes)
				)
			)
			(symbol "74HC595_1_0"
				(pin tri_state line
					(at 10.16 7.62 180)
					(length 2.54)
					(name "QB"
						(effects
							(font
								(size 1.27 1.27)
							)
						)
					)
					(number "1"
						(effects
							(font
								(size 1.27 1.27)
							)
						)
					)
				)
				(pin input line
					(at -10.16 2.54 0)
					(length 2.54)
					(name "~{SRCLR}"
						(effects
							(font
								(size 1.27 1.27)
							)
						)
					)
					(number "10"
						(effects
							(font
								(size 1.27 1.27)
							)
						)
					)
				)
				(pin input line
					(at -10.16 5.08 0)
					(length 2.54)
					(name "SRCLK"
						(effects
							(font
								(size 1.27 1.27)
							)
						)
					)
					(number "11"
						(effects
							(font
								(size 1.27 1.27)
							)
						)
					)
				)
				(pin input line
					(at -10.16 -2.54 0)
					(length 2.54)
					(name "RCLK"
						(effects
							(font
								(size 1.27 1.27)
							)
						)
					)
					(number "12"
						(effects
							(font
								(size 1.27 1.27)
							)
						)
					)
				)
				(pin input line
					(at -10.16 -5.08 0)
					(length 2.54)
					(name "~{OE}"
						(effects
							(font
								(size 1.27 1.27)
							)
						)
					)
					(number "13"
						(effects
							(font
								(size 1.27 1.27)
							)
						)
					)
				)
				(pin input line
					(at -10.16 10.16 0)
					(length 2.54)
					(name "SER"
						(effects
							(font
								(size 1.27 1.27)
							)
						)
					)
					(number "14"
						(effects
							(font
								(size 1.27 1.27)
							)
						)
					)
				)
				(pin tri_state line
					(at 10.16 10.16 180)
					(length 2.54)
					(name "QA"
						(effects
							(font
								(size 1.27 1.27)
							)
						)
					)
					(number "15"
						(effects
							(font
								(size 1.27 1.27)
							)
						)
					)
				)
				(pin power_in line
					(at 0 15.24 270)
					(length 2.54)
					(name "VCC"
						(effects
							(font
								(size 1.27 1.27)
							)
						)
					)
					(number "16"
						(effects
							(font
								(size 1.27 1.27)
							)
						)
					)
				)
				(pin tri_state line
					(at 10.16 5.08 180)
					(length 2.54)
					(name "QC"
						(effects
							(font
								(size 1.27 1.27)
							)
						)
					)
					(number "2"
						(effects
							(font
								(size 1.27 1.27)
							)
						)
					)
				)
				(pin tri_state line
					(at 10.16 2.54 180)
					(length 2.54)
					(name "QD"
						(effects
							(font
								(size 1.27 1.27)
							)
						)
					)
					(number "3"
						(effects
							(font
								(size 1.27 1.27)
							)
						)
					)
				)
				(pin tri_state line
					(at 10.16 0 180)
					(length 2.54)
					(name "QE"
						(effects
							(font
								(size 1.27 1.27)
							)
						)
					)
					(number "4"
						(effects
							(font
								(size 1.27 1.27)
							)
						)
					)
				)
				(pin tri_state line
					(at 10.16 -2.54 180)
					(length 2.54)
					(name "QF"
						(effects
							(font
								(size 1.27 1.27)
							)
						)
					)
					(number "5"
						(effects
							(font
								(size 1.27 1.27)
							)
						)
					)
				)
				(pin tri_state line
					(at 10.16 -5.08 180)
					(length 2.54)
					(name "QG"
						(effects
							(font
								(size 1.27 1.27)
							)
						)
					)
					(number "6"
						(effects
							(font
								(size 1.27 1.27)
							)
						)
					)
				)
				(pin tri_state line
					(at 10.16 -7.62 180)
					(length 2.54)
					(name "QH"
						(effects
							(font
								(size 1.27 1.27)
							)
						)
					)
					(number "7"
						(effects
							(font
								(size 1.27 1.27)
							)
						)
					)
				)
				(pin power_in line
					(at 0 -17.78 90)
					(length 2.54)
					(name "GND"
						(effects
							(font
								(size 1.27 1.27)
							)
						)
					)
					(number "8"
						(effects
							(font
								(size 1.27 1.27)
							)
						)
					)
				)
				(pin output line
					(at 10.16 -12.7 180)
					(length 2.54)
					(name "QH'"
						(effects
							(font
								(size 1.27 1.27)
							)
						)
					)
					(number "9"
						(effects
							(font
								(size 1.27 1.27)
							)
						)
					)
				)
			)
			(symbol "74HC595_1_1"
				(rectangle
					(start -7.62 12.7)
					(end 7.62 -15.24)
					(stroke
						(width 0.254)
						(type default)
					)
					(fill
						(type background)
					)
				)
			)
		)
		(symbol "74xx:74LS132"
			(pin_names
				(offset 1.016)
			)
			(exclude_from_sim no)
			(in_bom yes)
			(on_board yes)
			(property "Reference" "U"
				(at 0 1.27 0)
				(effects
					(font
						(size 1.27 1.27)
					)
				)
			)
			(property "Value" "74LS132"
				(at 0 -1.27 0)
				(effects
					(font
						(size 1.27 1.27)
					)
				)
			)
			(property "Footprint" ""
				(at 0 0 0)
				(effects
					(font
						(size 1.27 1.27)
					)
					(hide yes)
				)
			)
			(property "Datasheet" "http://www.ti.com/lit/gpn/sn74LS132"
				(at 0 0 0)
				(effects
					(font
						(size 1.27 1.27)
					)
					(hide yes)
				)
			)
			(property "Description" "Quad 2-input NAND Schmitt trigger"
				(at 0 0 0)
				(effects
					(font
						(size 1.27 1.27)
					)
					(hide yes)
				)
			)
			(property "ki_locked" ""
				(at 0 0 0)
				(effects
					(font
						(size 1.27 1.27)
					)
				)
			)
			(property "ki_keywords" "TTL Nand2"
				(at 0 0 0)
				(effects
					(font
						(size 1.27 1.27)
					)
					(hide yes)
				)
			)
			(property "ki_fp_filters" "DIP*W7.62mm*"
				(at 0 0 0)
				(effects
					(font
						(size 1.27 1.27)
					)
					(hide yes)
				)
			)
			(symbol "74LS132_1_0"
				(polyline
					(pts
						(xy -0.635 -1.27) (xy -0.635 1.27) (xy 0.635 1.27)
					)
					(stroke
						(width 0)
						(type default)
					)
					(fill
						(type none)
					)
				)
				(polyline
					(pts
						(xy -0.635 -1.27) (xy -0.635 1.27) (xy 0.635 1.27)
					)
					(stroke
						(width 0)
						(type default)
					)
					(fill
						(type none)
					)
				)
				(polyline
					(pts
						(xy -1.27 -1.27) (xy 0.635 -1.27) (xy 0.635 1.27) (xy 1.27 1.27)
					)
					(stroke
						(width 0)
						(type default)
					)
					(fill
						(type none)
					)
				)
				(polyline
					(pts
						(xy -1.27 -1.27) (xy 0.635 -1.27) (xy 0.635 1.27) (xy 1.27 1.27)
					)
					(stroke
						(width 0)
						(type default)
					)
					(fill
						(type none)
					)
				)
			)
			(symbol "74LS132_1_1"
				(arc
					(start 0 -3.81)
					(mid 3.7934 0)
					(end 0 3.81)
					(stroke
						(width 0.254)
						(type default)
					)
					(fill
						(type background)
					)
				)
				(polyline
					(pts
						(xy 0 3.81) (xy -3.81 3.81) (xy -3.81 -3.81) (xy 0 -3.81)
					)
					(stroke
						(width 0.254)
						(type default)
					)
					(fill
						(type background)
					)
				)
				(pin input line
					(at -7.62 2.54 0)
					(length 3.81)
					(name "~"
						(effects
							(font
								(size 1.27 1.27)
							)
						)
					)
					(number "1"
						(effects
							(font
								(size 1.27 1.27)
							)
						)
					)
				)
				(pin input line
					(at -7.62 -2.54 0)
					(length 3.81)
					(name "~"
						(effects
							(font
								(size 1.27 1.27)
							)
						)
					)
					(number "2"
						(effects
							(font
								(size 1.27 1.27)
							)
						)
					)
				)
				(pin output inverted
					(at 7.62 0 180)
					(length 3.81)
					(name "~"
						(effects
							(font
								(size 1.27 1.27)
							)
						)
					)
					(number "3"
						(effects
							(font
								(size 1.27 1.27)
							)
						)
					)
				)
			)
			(symbol "74LS132_1_2"
				(arc
					(start -3.81 -3.81)
					(mid -2.589 0)
					(end -3.81 3.81)
					(stroke
						(width 0.254)
						(type default)
					)
					(fill
						(type none)
					)
				)
				(arc
					(start -0.6096 -3.81)
					(mid 2.1842 -2.5851)
					(end 3.81 0)
					(stroke
						(width 0.254)
						(type default)
					)
					(fill
						(type background)
					)
				)
				(polyline
					(pts
						(xy -3.81 -3.81) (xy -0.635 -3.81)
					)
					(stroke
						(width 0.254)
						(type default)
					)
					(fill
						(type background)
					)
				)
				(polyline
					(pts
						(xy -3.81 3.81) (xy -0.635 3.81)
					)
					(stroke
						(width 0.254)
						(type default)
					)
					(fill
						(type background)
					)
				)
				(polyline
					(pts
						(xy -0.635 3.81) (xy -3.81 3.81) (xy -3.81 3.81) (xy -3.556 3.4036) (xy -3.0226 2.2606) (xy -2.6924 1.0414)
						(xy -2.6162 -0.254) (xy -2.7686 -1.4986) (xy -3.175 -2.7178) (xy -3.81 -3.81) (xy -3.81 -3.81)
						(xy -0.635 -3.81)
					)
					(stroke
						(width -25.4)
						(type default)
					)
					(fill
						(type background)
					)
				)
				(arc
					(start 3.81 0)
					(mid 2.1915 2.5936)
					(end -0.6096 3.81)
					(stroke
						(width 0.254)
						(type default)
					)
					(fill
						(type background)
					)
				)
				(pin input inverted
					(at -7.62 2.54 0)
					(length 4.318)
					(name "~"
						(effects
							(font
								(size 1.27 1.27)
							)
						)
					)
					(number "1"
						(effects
							(font
								(size 1.27 1.27)
							)
						)
					)
				)
				(pin input inverted
					(at -7.62 -2.54 0)
					(length 4.318)
					(name "~"
						(effects
							(font
								(size 1.27 1.27)
							)
						)
					)
					(number "2"
						(effects
							(font
								(size 1.27 1.27)
							)
						)
					)
				)
				(pin output line
					(at 7.62 0 180)
					(length 3.81)
					(name "~"
						(effects
							(font
								(size 1.27 1.27)
							)
						)
					)
					(number "3"
						(effects
							(font
								(size 1.27 1.27)
							)
						)
					)
				)
			)
			(symbol "74LS132_2_0"
				(polyline
					(pts
						(xy -0.635 -1.27) (xy -0.635 1.27) (xy 0.635 1.27)
					)
					(stroke
						(width 0)
						(type default)
					)
					(fill
						(type none)
					)
				)
				(polyline
					(pts
						(xy -0.635 -1.27) (xy -0.635 1.27) (xy 0.635 1.27)
					)
					(stroke
						(width 0)
						(type default)
					)
					(fill
						(type none)
					)
				)
				(polyline
					(pts
						(xy -1.27 -1.27) (xy 0.635 -1.27) (xy 0.635 1.27) (xy 1.27 1.27)
					)
					(stroke
						(width 0)
						(type default)
					)
					(fill
						(type none)
					)
				)
				(polyline
					(pts
						(xy -1.27 -1.27) (xy 0.635 -1.27) (xy 0.635 1.27) (xy 1.27 1.27)
					)
					(stroke
						(width 0)
						(type default)
					)
					(fill
						(type none)
					)
				)
			)
			(symbol "74LS132_2_1"
				(arc
					(start 0 -3.81)
					(mid 3.7934 0)
					(end 0 3.81)
					(stroke
						(width 0.254)
						(type default)
					)
					(fill
						(type background)
					)
				)
				(polyline
					(pts
						(xy 0 3.81) (xy -3.81 3.81) (xy -3.81 -3.81) (xy 0 -3.81)
					)
					(stroke
						(width 0.254)
						(type default)
					)
					(fill
						(type background)
					)
				)
				(pin input line
					(at -7.62 2.54 0)
					(length 3.81)
					(name "~"
						(effects
							(font
								(size 1.27 1.27)
							)
						)
					)
					(number "4"
						(effects
							(font
								(size 1.27 1.27)
							)
						)
					)
				)
				(pin input line
					(at -7.62 -2.54 0)
					(length 3.81)
					(name "~"
						(effects
							(font
								(size 1.27 1.27)
							)
						)
					)
					(number "5"
						(effects
							(font
								(size 1.27 1.27)
							)
						)
					)
				)
				(pin output inverted
					(at 7.62 0 180)
					(length 3.81)
					(name "~"
						(effects
							(font
								(size 1.27 1.27)
							)
						)
					)
					(number "6"
						(effects
							(font
								(size 1.27 1.27)
							)
						)
					)
				)
			)
			(symbol "74LS132_2_2"
				(arc
					(start -3.81 -3.81)
					(mid -2.589 0)
					(end -3.81 3.81)
					(stroke
						(width 0.254)
						(type default)
					)
					(fill
						(type none)
					)
				)
				(arc
					(start -0.6096 -3.81)
					(mid 2.1842 -2.5851)
					(end 3.81 0)
					(stroke
						(width 0.254)
						(type default)
					)
					(fill
						(type background)
					)
				)
				(polyline
					(pts
						(xy -3.81 -3.81) (xy -0.635 -3.81)
					)
					(stroke
						(width 0.254)
						(type default)
					)
					(fill
						(type background)
					)
				)
				(polyline
					(pts
						(xy -3.81 3.81) (xy -0.635 3.81)
					)
					(stroke
						(width 0.254)
						(type default)
					)
					(fill
						(type background)
					)
				)
				(polyline
					(pts
						(xy -0.635 3.81) (xy -3.81 3.81) (xy -3.81 3.81) (xy -3.556 3.4036) (xy -3.0226 2.2606) (xy -2.6924 1.0414)
						(xy -2.6162 -0.254) (xy -2.7686 -1.4986) (xy -3.175 -2.7178) (xy -3.81 -3.81) (xy -3.81 -3.81)
						(xy -0.635 -3.81)
					)
					(stroke
						(width -25.4)
						(type default)
					)
					(fill
						(type background)
					)
				)
				(arc
					(start 3.81 0)
					(mid 2.1915 2.5936)
					(end -0.6096 3.81)
					(stroke
						(width 0.254)
						(type default)
					)
					(fill
						(type background)
					)
				)
				(pin input inverted
					(at -7.62 2.54 0)
					(length 4.318)
					(name "~"
						(effects
							(font
								(size 1.27 1.27)
							)
						)
					)
					(number "4"
						(effects
							(font
								(size 1.27 1.27)
							)
						)
					)
				)
				(pin input inverted
					(at -7.62 -2.54 0)
					(length 4.318)
					(name "~"
						(effects
							(font
								(size 1.27 1.27)
							)
						)
					)
					(number "5"
						(effects
							(font
								(size 1.27 1.27)
							)
						)
					)
				)
				(pin output line
					(at 7.62 0 180)
					(length 3.81)
					(name "~"
						(effects
							(font
								(size 1.27 1.27)
							)
						)
					)
					(number "6"
						(effects
							(font
								(size 1.27 1.27)
							)
						)
					)
				)
			)
			(symbol "74LS132_3_0"
				(polyline
					(pts
						(xy -0.635 -1.27) (xy -0.635 1.27) (xy 0.635 1.27)
					)
					(stroke
						(width 0)
						(type default)
					)
					(fill
						(type none)
					)
				)
				(polyline
					(pts
						(xy -0.635 -1.27) (xy -0.635 1.27) (xy 0.635 1.27)
					)
					(stroke
						(width 0)
						(type default)
					)
					(fill
						(type none)
					)
				)
				(polyline
					(pts
						(xy -1.27 -1.27) (xy 0.635 -1.27) (xy 0.635 1.27) (xy 1.27 1.27)
					)
					(stroke
						(width 0)
						(type default)
					)
					(fill
						(type none)
					)
				)
				(polyline
					(pts
						(xy -1.27 -1.27) (xy 0.635 -1.27) (xy 0.635 1.27) (xy 1.27 1.27)
					)
					(stroke
						(width 0)
						(type default)
					)
					(fill
						(type none)
					)
				)
			)
			(symbol "74LS132_3_1"
				(arc
					(start 0 -3.81)
					(mid 3.7934 0)
					(end 0 3.81)
					(stroke
						(width 0.254)
						(type default)
					)
					(fill
						(type background)
					)
				)
				(polyline
					(pts
						(xy 0 3.81) (xy -3.81 3.81) (xy -3.81 -3.81) (xy 0 -3.81)
					)
					(stroke
						(width 0.254)
						(type default)
					)
					(fill
						(type background)
					)
				)
				(pin input line
					(at -7.62 -2.54 0)
					(length 3.81)
					(name "~"
						(effects
							(font
								(size 1.27 1.27)
							)
						)
					)
					(number "10"
						(effects
							(font
								(size 1.27 1.27)
							)
						)
					)
				)
				(pin output inverted
					(at 7.62 0 180)
					(length 3.81)
					(name "~"
						(effects
							(font
								(size 1.27 1.27)
							)
						)
					)
					(number "8"
						(effects
							(font
								(size 1.27 1.27)
							)
						)
					)
				)
				(pin input line
					(at -7.62 2.54 0)
					(length 3.81)
					(name "~"
						(effects
							(font
								(size 1.27 1.27)
							)
						)
					)
					(number "9"
						(effects
							(font
								(size 1.27 1.27)
							)
						)
					)
				)
			)
			(symbol "74LS132_3_2"
				(arc
					(start -3.81 -3.81)
					(mid -2.589 0)
					(end -3.81 3.81)
					(stroke
						(width 0.254)
						(type default)
					)
					(fill
						(type none)
					)
				)
				(arc
					(start -0.6096 -3.81)
					(mid 2.1842 -2.5851)
					(end 3.81 0)
					(stroke
						(width 0.254)
						(type default)
					)
					(fill
						(type background)
					)
				)
				(polyline
					(pts
						(xy -3.81 -3.81) (xy -0.635 -3.81)
					)
					(stroke
						(width 0.254)
						(type default)
					)
					(fill
						(type background)
					)
				)
				(polyline
					(pts
						(xy -3.81 3.81) (xy -0.635 3.81)
					)
					(stroke
						(width 0.254)
						(type default)
					)
					(fill
						(type background)
					)
				)
				(polyline
					(pts
						(xy -0.635 3.81) (xy -3.81 3.81) (xy -3.81 3.81) (xy -3.556 3.4036) (xy -3.0226 2.2606) (xy -2.6924 1.0414)
						(xy -2.6162 -0.254) (xy -2.7686 -1.4986) (xy -3.175 -2.7178) (xy -3.81 -3.81) (xy -3.81 -3.81)
						(xy -0.635 -3.81)
					)
					(stroke
						(width -25.4)
						(type default)
					)
					(fill
						(type background)
					)
				)
				(arc
					(start 3.81 0)
					(mid 2.1915 2.5936)
					(end -0.6096 3.81)
					(stroke
						(width 0.254)
						(type default)
					)
					(fill
						(type background)
					)
				)
				(pin input inverted
					(at -7.62 -2.54 0)
					(length 4.318)
					(name "~"
						(effects
							(font
								(size 1.27 1.27)
							)
						)
					)
					(number "10"
						(effects
							(font
								(size 1.27 1.27)
							)
						)
					)
				)
				(pin output line
					(at 7.62 0 180)
					(length 3.81)
					(name "~"
						(effects
							(font
								(size 1.27 1.27)
							)
						)
					)
					(number "8"
						(effects
							(font
								(size 1.27 1.27)
							)
						)
					)
				)
				(pin input inverted
					(at -7.62 2.54 0)
					(length 4.318)
					(name "~"
						(effects
							(font
								(size 1.27 1.27)
							)
						)
					)
					(number "9"
						(effects
							(font
								(size 1.27 1.27)
							)
						)
					)
				)
			)
			(symbol "74LS132_4_0"
				(polyline
					(pts
						(xy -0.635 -1.27) (xy -0.635 1.27) (xy 0.635 1.27)
					)
					(stroke
						(width 0)
						(type default)
					)
					(fill
						(type none)
					)
				)
				(polyline
					(pts
						(xy -0.635 -1.27) (xy -0.635 1.27) (xy 0.635 1.27)
					)
					(stroke
						(width 0)
						(type default)
					)
					(fill
						(type none)
					)
				)
				(polyline
					(pts
						(xy -1.27 -1.27) (xy 0.635 -1.27) (xy 0.635 1.27) (xy 1.27 1.27)
					)
					(stroke
						(width 0)
						(type default)
					)
					(fill
						(type none)
					)
				)
				(polyline
					(pts
						(xy -1.27 -1.27) (xy 0.635 -1.27) (xy 0.635 1.27) (xy 1.27 1.27)
					)
					(stroke
						(width 0)
						(type default)
					)
					(fill
						(type none)
					)
				)
			)
			(symbol "74LS132_4_1"
				(arc
					(start 0 -3.81)
					(mid 3.7934 0)
					(end 0 3.81)
					(stroke
						(width 0.254)
						(type default)
					)
					(fill
						(type background)
					)
				)
				(polyline
					(pts
						(xy 0 3.81) (xy -3.81 3.81) (xy -3.81 -3.81) (xy 0 -3.81)
					)
					(stroke
						(width 0.254)
						(type default)
					)
					(fill
						(type background)
					)
				)
				(pin output inverted
					(at 7.62 0 180)
					(length 3.81)
					(name "~"
						(effects
							(font
								(size 1.27 1.27)
							)
						)
					)
					(number "11"
						(effects
							(font
								(size 1.27 1.27)
							)
						)
					)
				)
				(pin input line
					(at -7.62 2.54 0)
					(length 3.81)
					(name "~"
						(effects
							(font
								(size 1.27 1.27)
							)
						)
					)
					(number "12"
						(effects
							(font
								(size 1.27 1.27)
							)
						)
					)
				)
				(pin input line
					(at -7.62 -2.54 0)
					(length 3.81)
					(name "~"
						(effects
							(font
								(size 1.27 1.27)
							)
						)
					)
					(number "13"
						(effects
							(font
								(size 1.27 1.27)
							)
						)
					)
				)
			)
			(symbol "74LS132_4_2"
				(arc
					(start -3.81 -3.81)
					(mid -2.589 0)
					(end -3.81 3.81)
					(stroke
						(width 0.254)
						(type default)
					)
					(fill
						(type none)
					)
				)
				(arc
					(start -0.6096 -3.81)
					(mid 2.1842 -2.5851)
					(end 3.81 0)
					(stroke
						(width 0.254)
						(type default)
					)
					(fill
						(type background)
					)
				)
				(polyline
					(pts
						(xy -3.81 -3.81) (xy -0.635 -3.81)
					)
					(stroke
						(width 0.254)
						(type default)
					)
					(fill
						(type background)
					)
				)
				(polyline
					(pts
						(xy -3.81 3.81) (xy -0.635 3.81)
					)
					(stroke
						(width 0.254)
						(type default)
					)
					(fill
						(type background)
					)
				)
				(polyline
					(pts
						(xy -0.635 3.81) (xy -3.81 3.81) (xy -3.81 3.81) (xy -3.556 3.4036) (xy -3.0226 2.2606) (xy -2.6924 1.0414)
						(xy -2.6162 -0.254) (xy -2.7686 -1.4986) (xy -3.175 -2.7178) (xy -3.81 -3.81) (xy -3.81 -3.81)
						(xy -0.635 -3.81)
					)
					(stroke
						(width -25.4)
						(type default)
					)
					(fill
						(type background)
					)
				)
				(arc
					(start 3.81 0)
					(mid 2.1915 2.5936)
					(end -0.6096 3.81)
					(stroke
						(width 0.254)
						(type default)
					)
					(fill
						(type background)
					)
				)
				(pin output line
					(at 7.62 0 180)
					(length 3.81)
					(name "~"
						(effects
							(font
								(size 1.27 1.27)
							)
						)
					)
					(number "11"
						(effects
							(font
								(size 1.27 1.27)
							)
						)
					)
				)
				(pin input inverted
					(at -7.62 2.54 0)
					(length 4.318)
					(name "~"
						(effects
							(font
								(size 1.27 1.27)
							)
						)
					)
					(number "12"
						(effects
							(font
								(size 1.27 1.27)
							)
						)
					)
				)
				(pin input inverted
					(at -7.62 -2.54 0)
					(length 4.318)
					(name "~"
						(effects
							(font
								(size 1.27 1.27)
							)
						)
					)
					(number "13"
						(effects
							(font
								(size 1.27 1.27)
							)
						)
					)
				)
			)
			(symbol "74LS132_5_0"
				(pin power_in line
					(at 0 12.7 270)
					(length 5.08)
					(name "VCC"
						(effects
							(font
								(size 1.27 1.27)
							)
						)
					)
					(number "14"
						(effects
							(font
								(size 1.27 1.27)
							)
						)
					)
				)
				(pin power_in line
					(at 0 -12.7 90)
					(length 5.08)
					(name "GND"
						(effects
							(font
								(size 1.27 1.27)
							)
						)
					)
					(number "7"
						(effects
							(font
								(size 1.27 1.27)
							)
						)
					)
				)
			)
			(symbol "74LS132_5_1"
				(rectangle
					(start -5.08 7.62)
					(end 5.08 -7.62)
					(stroke
						(width 0.254)
						(type default)
					)
					(fill
						(type background)
					)
				)
			)
		)
		(symbol "74xx:74LS138"
			(pin_names
				(offset 1.016)
			)
			(exclude_from_sim no)
			(in_bom yes)
			(on_board yes)
			(property "Reference" "U"
				(at -7.62 11.43 0)
				(effects
					(font
						(size 1.27 1.27)
					)
				)
			)
			(property "Value" "74LS138"
				(at -7.62 -13.97 0)
				(effects
					(font
						(size 1.27 1.27)
					)
				)
			)
			(property "Footprint" ""
				(at 0 0 0)
				(effects
					(font
						(size 1.27 1.27)
					)
					(hide yes)
				)
			)
			(property "Datasheet" "http://www.ti.com/lit/gpn/sn74LS138"
				(at 0 0 0)
				(effects
					(font
						(size 1.27 1.27)
					)
					(hide yes)
				)
			)
			(property "Description" "Decoder 3 to 8 active low outputs"
				(at 0 0 0)
				(effects
					(font
						(size 1.27 1.27)
					)
					(hide yes)
				)
			)
			(property "ki_locked" ""
				(at 0 0 0)
				(effects
					(font
						(size 1.27 1.27)
					)
				)
			)
			(property "ki_keywords" "TTL DECOD DECOD8"
				(at 0 0 0)
				(effects
					(font
						(size 1.27 1.27)
					)
					(hide yes)
				)
			)
			(property "ki_fp_filters" "DIP?16*"
				(at 0 0 0)
				(effects
					(font
						(size 1.27 1.27)
					)
					(hide yes)
				)
			)
			(symbol "74LS138_1_0"
				(pin input line
					(at -12.7 7.62 0)
					(length 5.08)
					(name "A0"
						(effects
							(font
								(size 1.27 1.27)
							)
						)
					)
					(number "1"
						(effects
							(font
								(size 1.27 1.27)
							)
						)
					)
				)
				(pin output output_low
					(at 12.7 -5.08 180)
					(length 5.08)
					(name "O5"
						(effects
							(font
								(size 1.27 1.27)
							)
						)
					)
					(number "10"
						(effects
							(font
								(size 1.27 1.27)
							)
						)
					)
				)
				(pin output output_low
					(at 12.7 -2.54 180)
					(length 5.08)
					(name "O4"
						(effects
							(font
								(size 1.27 1.27)
							)
						)
					)
					(number "11"
						(effects
							(font
								(size 1.27 1.27)
							)
						)
					)
				)
				(pin output output_low
					(at 12.7 0 180)
					(length 5.08)
					(name "O3"
						(effects
							(font
								(size 1.27 1.27)
							)
						)
					)
					(number "12"
						(effects
							(font
								(size 1.27 1.27)
							)
						)
					)
				)
				(pin output output_low
					(at 12.7 2.54 180)
					(length 5.08)
					(name "O2"
						(effects
							(font
								(size 1.27 1.27)
							)
						)
					)
					(number "13"
						(effects
							(font
								(size 1.27 1.27)
							)
						)
					)
				)
				(pin output output_low
					(at 12.7 5.08 180)
					(length 5.08)
					(name "O1"
						(effects
							(font
								(size 1.27 1.27)
							)
						)
					)
					(number "14"
						(effects
							(font
								(size 1.27 1.27)
							)
						)
					)
				)
				(pin output output_low
					(at 12.7 7.62 180)
					(length 5.08)
					(name "O0"
						(effects
							(font
								(size 1.27 1.27)
							)
						)
					)
					(number "15"
						(effects
							(font
								(size 1.27 1.27)
							)
						)
					)
				)
				(pin power_in line
					(at 0 15.24 270)
					(length 5.08)
					(name "VCC"
						(effects
							(font
								(size 1.27 1.27)
							)
						)
					)
					(number "16"
						(effects
							(font
								(size 1.27 1.27)
							)
						)
					)
				)
				(pin input line
					(at -12.7 5.08 0)
					(length 5.08)
					(name "A1"
						(effects
							(font
								(size 1.27 1.27)
							)
						)
					)
					(number "2"
						(effects
							(font
								(size 1.27 1.27)
							)
						)
					)
				)
				(pin input line
					(at -12.7 2.54 0)
					(length 5.08)
					(name "A2"
						(effects
							(font
								(size 1.27 1.27)
							)
						)
					)
					(number "3"
						(effects
							(font
								(size 1.27 1.27)
							)
						)
					)
				)
				(pin input input_low
					(at -12.7 -10.16 0)
					(length 5.08)
					(name "E1"
						(effects
							(font
								(size 1.27 1.27)
							)
						)
					)
					(number "4"
						(effects
							(font
								(size 1.27 1.27)
							)
						)
					)
				)
				(pin input input_low
					(at -12.7 -7.62 0)
					(length 5.08)
					(name "E2"
						(effects
							(font
								(size 1.27 1.27)
							)
						)
					)
					(number "5"
						(effects
							(font
								(size 1.27 1.27)
							)
						)
					)
				)
				(pin input line
					(at -12.7 -5.08 0)
					(length 5.08)
					(name "E3"
						(effects
							(font
								(size 1.27 1.27)
							)
						)
					)
					(number "6"
						(effects
							(font
								(size 1.27 1.27)
							)
						)
					)
				)
				(pin output output_low
					(at 12.7 -10.16 180)
					(length 5.08)
					(name "O7"
						(effects
							(font
								(size 1.27 1.27)
							)
						)
					)
					(number "7"
						(effects
							(font
								(size 1.27 1.27)
							)
						)
					)
				)
				(pin power_in line
					(at 0 -17.78 90)
					(length 5.08)
					(name "GND"
						(effects
							(font
								(size 1.27 1.27)
							)
						)
					)
					(number "8"
						(effects
							(font
								(size 1.27 1.27)
							)
						)
					)
				)
				(pin output output_low
					(at 12.7 -7.62 180)
					(length 5.08)
					(name "O6"
						(effects
							(font
								(size 1.27 1.27)
							)
						)
					)
					(number "9"
						(effects
							(font
								(size 1.27 1.27)
							)
						)
					)
				)
			)
			(symbol "74LS138_1_1"
				(rectangle
					(start -7.62 10.16)
					(end 7.62 -12.7)
					(stroke
						(width 0.254)
						(type default)
					)
					(fill
						(type background)
					)
				)
			)
		)
		(symbol "74xx:74LS165"
			(exclude_from_sim no)
			(in_bom yes)
			(on_board yes)
			(property "Reference" "U"
				(at -7.62 19.05 0)
				(effects
					(font
						(size 1.27 1.27)
					)
				)
			)
			(property "Value" "74LS165"
				(at -7.62 -21.59 0)
				(effects
					(font
						(size 1.27 1.27)
					)
				)
			)
			(property "Footprint" ""
				(at 0 0 0)
				(effects
					(font
						(size 1.27 1.27)
					)
					(hide yes)
				)
			)
			(property "Datasheet" "https://www.ti.com/lit/ds/symlink/sn74ls165a.pdf"
				(at 0 0 0)
				(effects
					(font
						(size 1.27 1.27)
					)
					(hide yes)
				)
			)
			(property "Description" "Shift Register 8-bit, parallel load"
				(at 0 0 0)
				(effects
					(font
						(size 1.27 1.27)
					)
					(hide yes)
				)
			)
			(property "ki_keywords" "TTL SR SR8"
				(at 0 0 0)
				(effects
					(font
						(size 1.27 1.27)
					)
					(hide yes)
				)
			)
			(property "ki_fp_filters" "DIP?16* SO*16*3.9x9.9mm*P1.27mm* SSOP*16*5.3x6.2mm*P0.65mm* TSSOP*16*4.4x5mm*P0.65*"
				(at 0 0 0)
				(effects
					(font
						(size 1.27 1.27)
					)
					(hide yes)
				)
			)
			(symbol "74LS165_1_0"
				(pin input line
					(at -12.7 -10.16 0)
					(length 5.08)
					(name "~{PL}"
						(effects
							(font
								(size 1.27 1.27)
							)
						)
					)
					(number "1"
						(effects
							(font
								(size 1.27 1.27)
							)
						)
					)
				)
				(pin input line
					(at -12.7 15.24 0)
					(length 5.08)
					(name "DS"
						(effects
							(font
								(size 1.27 1.27)
							)
						)
					)
					(number "10"
						(effects
							(font
								(size 1.27 1.27)
							)
						)
					)
				)
				(pin input line
					(at -12.7 12.7 0)
					(length 5.08)
					(name "D0"
						(effects
							(font
								(size 1.27 1.27)
							)
						)
					)
					(number "11"
						(effects
							(font
								(size 1.27 1.27)
							)
						)
					)
				)
				(pin input line
					(at -12.7 10.16 0)
					(length 5.08)
					(name "D1"
						(effects
							(font
								(size 1.27 1.27)
							)
						)
					)
					(number "12"
						(effects
							(font
								(size 1.27 1.27)
							)
						)
					)
				)
				(pin input line
					(at -12.7 7.62 0)
					(length 5.08)
					(name "D2"
						(effects
							(font
								(size 1.27 1.27)
							)
						)
					)
					(number "13"
						(effects
							(font
								(size 1.27 1.27)
							)
						)
					)
				)
				(pin input line
					(at -12.7 5.08 0)
					(length 5.08)
					(name "D3"
						(effects
							(font
								(size 1.27 1.27)
							)
						)
					)
					(number "14"
						(effects
							(font
								(size 1.27 1.27)
							)
						)
					)
				)
				(pin input line
					(at -12.7 -17.78 0)
					(length 5.08)
					(name "~{CE}"
						(effects
							(font
								(size 1.27 1.27)
							)
						)
					)
					(number "15"
						(effects
							(font
								(size 1.27 1.27)
							)
						)
					)
				)
				(pin power_in line
					(at 0 22.86 270)
					(length 5.08)
					(name "VCC"
						(effects
							(font
								(size 1.27 1.27)
							)
						)
					)
					(number "16"
						(effects
							(font
								(size 1.27 1.27)
							)
						)
					)
				)
				(pin input line
					(at -12.7 -15.24 0)
					(length 5.08)
					(name "CP"
						(effects
							(font
								(size 1.27 1.27)
							)
						)
					)
					(number "2"
						(effects
							(font
								(size 1.27 1.27)
							)
						)
					)
				)
				(pin input line
					(at -12.7 2.54 0)
					(length 5.08)
					(name "D4"
						(effects
							(font
								(size 1.27 1.27)
							)
						)
					)
					(number "3"
						(effects
							(font
								(size 1.27 1.27)
							)
						)
					)
				)
				(pin input line
					(at -12.7 0 0)
					(length 5.08)
					(name "D5"
						(effects
							(font
								(size 1.27 1.27)
							)
						)
					)
					(number "4"
						(effects
							(font
								(size 1.27 1.27)
							)
						)
					)
				)
				(pin input line
					(at -12.7 -2.54 0)
					(length 5.08)
					(name "D6"
						(effects
							(font
								(size 1.27 1.27)
							)
						)
					)
					(number "5"
						(effects
							(font
								(size 1.27 1.27)
							)
						)
					)
				)
				(pin input line
					(at -12.7 -5.08 0)
					(length 5.08)
					(name "D7"
						(effects
							(font
								(size 1.27 1.27)
							)
						)
					)
					(number "6"
						(effects
							(font
								(size 1.27 1.27)
							)
						)
					)
				)
				(pin output line
					(at 12.7 12.7 180)
					(length 5.08)
					(name "~{Q7}"
						(effects
							(font
								(size 1.27 1.27)
							)
						)
					)
					(number "7"
						(effects
							(font
								(size 1.27 1.27)
							)
						)
					)
				)
				(pin power_in line
					(at 0 -25.4 90)
					(length 5.08)
					(name "GND"
						(effects
							(font
								(size 1.27 1.27)
							)
						)
					)
					(number "8"
						(effects
							(font
								(size 1.27 1.27)
							)
						)
					)
				)
				(pin output line
					(at 12.7 15.24 180)
					(length 5.08)
					(name "Q7"
						(effects
							(font
								(size 1.27 1.27)
							)
						)
					)
					(number "9"
						(effects
							(font
								(size 1.27 1.27)
							)
						)
					)
				)
			)
			(symbol "74LS165_1_1"
				(rectangle
					(start -7.62 17.78)
					(end 7.62 -20.32)
					(stroke
						(width 0.254)
						(type default)
					)
					(fill
						(type background)
					)
				)
			)
		)
		(symbol "74xx:74LS174"
			(pin_names
				(offset 1.016)
			)
			(exclude_from_sim no)
			(in_bom yes)
			(on_board yes)
			(property "Reference" "U"
				(at -7.62 13.97 0)
				(effects
					(font
						(size 1.27 1.27)
					)
				)
			)
			(property "Value" "74LS174"
				(at -7.62 -16.51 0)
				(effects
					(font
						(size 1.27 1.27)
					)
				)
			)
			(property "Footprint" ""
				(at 0 0 0)
				(effects
					(font
						(size 1.27 1.27)
					)
					(hide yes)
				)
			)
			(property "Datasheet" "http://www.ti.com/lit/gpn/sn74LS174"
				(at 0 0 0)
				(effects
					(font
						(size 1.27 1.27)
					)
					(hide yes)
				)
			)
			(property "Description" "Hex D-type Flip-Flop, reset"
				(at 0 0 0)
				(effects
					(font
						(size 1.27 1.27)
					)
					(hide yes)
				)
			)
			(property "ki_locked" ""
				(at 0 0 0)
				(effects
					(font
						(size 1.27 1.27)
					)
				)
			)
			(property "ki_keywords" "TTL REG REG6 DFF"
				(at 0 0 0)
				(effects
					(font
						(size 1.27 1.27)
					)
					(hide yes)
				)
			)
			(property "ki_fp_filters" "DIP?16*"
				(at 0 0 0)
				(effects
					(font
						(size 1.27 1.27)
					)
					(hide yes)
				)
			)
			(symbol "74LS174_1_0"
				(pin input line
					(at -12.7 -12.7 0)
					(length 5.08)
					(name "~{Mr}"
						(effects
							(font
								(size 1.27 1.27)
							)
						)
					)
					(number "1"
						(effects
							(font
								(size 1.27 1.27)
							)
						)
					)
				)
				(pin output line
					(at 12.7 2.54 180)
					(length 5.08)
					(name "Q3"
						(effects
							(font
								(size 1.27 1.27)
							)
						)
					)
					(number "10"
						(effects
							(font
								(size 1.27 1.27)
							)
						)
					)
				)
				(pin input line
					(at -12.7 2.54 0)
					(length 5.08)
					(name "D3"
						(effects
							(font
								(size 1.27 1.27)
							)
						)
					)
					(number "11"
						(effects
							(font
								(size 1.27 1.27)
							)
						)
					)
				)
				(pin output line
					(at 12.7 0 180)
					(length 5.08)
					(name "Q4"
						(effects
							(font
								(size 1.27 1.27)
							)
						)
					)
					(number "12"
						(effects
							(font
								(size 1.27 1.27)
							)
						)
					)
				)
				(pin input line
					(at -12.7 0 0)
					(length 5.08)
					(name "D4"
						(effects
							(font
								(size 1.27 1.27)
							)
						)
					)
					(number "13"
						(effects
							(font
								(size 1.27 1.27)
							)
						)
					)
				)
				(pin input line
					(at -12.7 -2.54 0)
					(length 5.08)
					(name "D5"
						(effects
							(font
								(size 1.27 1.27)
							)
						)
					)
					(number "14"
						(effects
							(font
								(size 1.27 1.27)
							)
						)
					)
				)
				(pin output line
					(at 12.7 -2.54 180)
					(length 5.08)
					(name "Q5"
						(effects
							(font
								(size 1.27 1.27)
							)
						)
					)
					(number "15"
						(effects
							(font
								(size 1.27 1.27)
							)
						)
					)
				)
				(pin power_in line
					(at 0 17.78 270)
					(length 5.08)
					(name "VCC"
						(effects
							(font
								(size 1.27 1.27)
							)
						)
					)
					(number "16"
						(effects
							(font
								(size 1.27 1.27)
							)
						)
					)
				)
				(pin output line
					(at 12.7 10.16 180)
					(length 5.08)
					(name "Q0"
						(effects
							(font
								(size 1.27 1.27)
							)
						)
					)
					(number "2"
						(effects
							(font
								(size 1.27 1.27)
							)
						)
					)
				)
				(pin input line
					(at -12.7 10.16 0)
					(length 5.08)
					(name "D0"
						(effects
							(font
								(size 1.27 1.27)
							)
						)
					)
					(number "3"
						(effects
							(font
								(size 1.27 1.27)
							)
						)
					)
				)
				(pin input line
					(at -12.7 7.62 0)
					(length 5.08)
					(name "D1"
						(effects
							(font
								(size 1.27 1.27)
							)
						)
					)
					(number "4"
						(effects
							(font
								(size 1.27 1.27)
							)
						)
					)
				)
				(pin output line
					(at 12.7 7.62 180)
					(length 5.08)
					(name "Q1"
						(effects
							(font
								(size 1.27 1.27)
							)
						)
					)
					(number "5"
						(effects
							(font
								(size 1.27 1.27)
							)
						)
					)
				)
				(pin input line
					(at -12.7 5.08 0)
					(length 5.08)
					(name "D2"
						(effects
							(font
								(size 1.27 1.27)
							)
						)
					)
					(number "6"
						(effects
							(font
								(size 1.27 1.27)
							)
						)
					)
				)
				(pin output line
					(at 12.7 5.08 180)
					(length 5.08)
					(name "Q2"
						(effects
							(font
								(size 1.27 1.27)
							)
						)
					)
					(number "7"
						(effects
							(font
								(size 1.27 1.27)
							)
						)
					)
				)
				(pin power_in line
					(at 0 -20.32 90)
					(length 5.08)
					(name "GND"
						(effects
							(font
								(size 1.27 1.27)
							)
						)
					)
					(number "8"
						(effects
							(font
								(size 1.27 1.27)
							)
						)
					)
				)
				(pin input clock
					(at -12.7 -7.62 0)
					(length 5.08)
					(name "Cp"
						(effects
							(font
								(size 1.27 1.27)
							)
						)
					)
					(number "9"
						(effects
							(font
								(size 1.27 1.27)
							)
						)
					)
				)
			)
			(symbol "74LS174_1_1"
				(rectangle
					(start -7.62 12.7)
					(end 7.62 -15.24)
					(stroke
						(width 0.254)
						(type default)
					)
					(fill
						(type background)
					)
				)
			)
		)
		(symbol "Connector_Generic:Conn_01x05"
			(pin_names
				(offset 1.016) hide)
			(exclude_from_sim no)
			(in_bom yes)
			(on_board yes)
			(property "Reference" "J"
				(at 0 7.62 0)
				(effects
					(font
						(size 1.27 1.27)
					)
				)
			)
			(property "Value" "Conn_01x05"
				(at 0 -7.62 0)
				(effects
					(font
						(size 1.27 1.27)
					)
				)
			)
			(property "Footprint" ""
				(at 0 0 0)
				(effects
					(font
						(size 1.27 1.27)
					)
					(hide yes)
				)
			)
			(property "Datasheet" "~"
				(at 0 0 0)
				(effects
					(font
						(size 1.27 1.27)
					)
					(hide yes)
				)
			)
			(property "Description" "Generic connector, single row, 01x05, script generated (kicad-library-utils/schlib/autogen/connector/)"
				(at 0 0 0)
				(effects
					(font
						(size 1.27 1.27)
					)
					(hide yes)
				)
			)
			(property "ki_keywords" "connector"
				(at 0 0 0)
				(effects
					(font
						(size 1.27 1.27)
					)
					(hide yes)
				)
			)
			(property "ki_fp_filters" "Connector*:*_1x??_*"
				(at 0 0 0)
				(effects
					(font
						(size 1.27 1.27)
					)
					(hide yes)
				)
			)
			(symbol "Conn_01x05_1_1"
				(rectangle
					(start -1.27 -4.953)
					(end 0 -5.207)
					(stroke
						(width 0.1524)
						(type default)
					)
					(fill
						(type none)
					)
				)
				(rectangle
					(start -1.27 -2.413)
					(end 0 -2.667)
					(stroke
						(width 0.1524)
						(type default)
					)
					(fill
						(type none)
					)
				)
				(rectangle
					(start -1.27 0.127)
					(end 0 -0.127)
					(stroke
						(width 0.1524)
						(type default)
					)
					(fill
						(type none)
					)
				)
				(rectangle
					(start -1.27 2.667)
					(end 0 2.413)
					(stroke
						(width 0.1524)
						(type default)
					)
					(fill
						(type none)
					)
				)
				(rectangle
					(start -1.27 5.207)
					(end 0 4.953)
					(stroke
						(width 0.1524)
						(type default)
					)
					(fill
						(type none)
					)
				)
				(rectangle
					(start -1.27 6.35)
					(end 1.27 -6.35)
					(stroke
						(width 0.254)
						(type default)
					)
					(fill
						(type background)
					)
				)
				(pin passive line
					(at -5.08 5.08 0)
					(length 3.81)
					(name "Pin_1"
						(effects
							(font
								(size 1.27 1.27)
							)
						)
					)
					(number "1"
						(effects
							(font
								(size 1.27 1.27)
							)
						)
					)
				)
				(pin passive line
					(at -5.08 2.54 0)
					(length 3.81)
					(name "Pin_2"
						(effects
							(font
								(size 1.27 1.27)
							)
						)
					)
					(number "2"
						(effects
							(font
								(size 1.27 1.27)
							)
						)
					)
				)
				(pin passive line
					(at -5.08 0 0)
					(length 3.81)
					(name "Pin_3"
						(effects
							(font
								(size 1.27 1.27)
							)
						)
					)
					(number "3"
						(effects
							(font
								(size 1.27 1.27)
							)
						)
					)
				)
				(pin passive line
					(at -5.08 -2.54 0)
					(length 3.81)
					(name "Pin_4"
						(effects
							(font
								(size 1.27 1.27)
							)
						)
					)
					(number "4"
						(effects
							(font
								(size 1.27 1.27)
							)
						)
					)
				)
				(pin passive line
					(at -5.08 -5.08 0)
					(length 3.81)
					(name "Pin_5"
						(effects
							(font
								(size 1.27 1.27)
							)
						)
					)
					(number "5"
						(effects
							(font
								(size 1.27 1.27)
							)
						)
					)
				)
			)
		)
		(symbol "Connector_Generic:Conn_02x03_Odd_Even"
			(pin_names
				(offset 1.016) hide)
			(exclude_from_sim no)
			(in_bom yes)
			(on_board yes)
			(property "Reference" "J"
				(at 1.27 5.08 0)
				(effects
					(font
						(size 1.27 1.27)
					)
				)
			)
			(property "Value" "Conn_02x03_Odd_Even"
				(at 1.27 -5.08 0)
				(effects
					(font
						(size 1.27 1.27)
					)
				)
			)
			(property "Footprint" ""
				(at 0 0 0)
				(effects
					(font
						(size 1.27 1.27)
					)
					(hide yes)
				)
			)
			(property "Datasheet" "~"
				(at 0 0 0)
				(effects
					(font
						(size 1.27 1.27)
					)
					(hide yes)
				)
			)
			(property "Description" "Generic connector, double row, 02x03, odd/even pin numbering scheme (row 1 odd numbers, row 2 even numbers), script generated (kicad-library-utils/schlib/autogen/connector/)"
				(at 0 0 0)
				(effects
					(font
						(size 1.27 1.27)
					)
					(hide yes)
				)
			)
			(property "ki_keywords" "connector"
				(at 0 0 0)
				(effects
					(font
						(size 1.27 1.27)
					)
					(hide yes)
				)
			)
			(property "ki_fp_filters" "Connector*:*_2x??_*"
				(at 0 0 0)
				(effects
					(font
						(size 1.27 1.27)
					)
					(hide yes)
				)
			)
			(symbol "Conn_02x03_Odd_Even_1_1"
				(rectangle
					(start -1.27 -2.413)
					(end 0 -2.667)
					(stroke
						(width 0.1524)
						(type default)
					)
					(fill
						(type none)
					)
				)
				(rectangle
					(start -1.27 0.127)
					(end 0 -0.127)
					(stroke
						(width 0.1524)
						(type default)
					)
					(fill
						(type none)
					)
				)
				(rectangle
					(start -1.27 2.667)
					(end 0 2.413)
					(stroke
						(width 0.1524)
						(type default)
					)
					(fill
						(type none)
					)
				)
				(rectangle
					(start -1.27 3.81)
					(end 3.81 -3.81)
					(stroke
						(width 0.254)
						(type default)
					)
					(fill
						(type background)
					)
				)
				(rectangle
					(start 3.81 -2.413)
					(end 2.54 -2.667)
					(stroke
						(width 0.1524)
						(type default)
					)
					(fill
						(type none)
					)
				)
				(rectangle
					(start 3.81 0.127)
					(end 2.54 -0.127)
					(stroke
						(width 0.1524)
						(type default)
					)
					(fill
						(type none)
					)
				)
				(rectangle
					(start 3.81 2.667)
					(end 2.54 2.413)
					(stroke
						(width 0.1524)
						(type default)
					)
					(fill
						(type none)
					)
				)
				(pin passive line
					(at -5.08 2.54 0)
					(length 3.81)
					(name "Pin_1"
						(effects
							(font
								(size 1.27 1.27)
							)
						)
					)
					(number "1"
						(effects
							(font
								(size 1.27 1.27)
							)
						)
					)
				)
				(pin passive line
					(at 7.62 2.54 180)
					(length 3.81)
					(name "Pin_2"
						(effects
							(font
								(size 1.27 1.27)
							)
						)
					)
					(number "2"
						(effects
							(font
								(size 1.27 1.27)
							)
						)
					)
				)
				(pin passive line
					(at -5.08 0 0)
					(length 3.81)
					(name "Pin_3"
						(effects
							(font
								(size 1.27 1.27)
							)
						)
					)
					(number "3"
						(effects
							(font
								(size 1.27 1.27)
							)
						)
					)
				)
				(pin passive line
					(at 7.62 0 180)
					(length 3.81)
					(name "Pin_4"
						(effects
							(font
								(size 1.27 1.27)
							)
						)
					)
					(number "4"
						(effects
							(font
								(size 1.27 1.27)
							)
						)
					)
				)
				(pin passive line
					(at -5.08 -2.54 0)
					(length 3.81)
					(name "Pin_5"
						(effects
							(font
								(size 1.27 1.27)
							)
						)
					)
					(number "5"
						(effects
							(font
								(size 1.27 1.27)
							)
						)
					)
				)
				(pin passive line
					(at 7.62 -2.54 180)
					(length 3.81)
					(name "Pin_6"
						(effects
							(font
								(size 1.27 1.27)
							)
						)
					)
					(number "6"
						(effects
							(font
								(size 1.27 1.27)
							)
						)
					)
				)
			)
		)
		(symbol "Connector_Generic:Conn_02x08_Odd_Even"
			(pin_names
				(offset 1.016) hide)
			(exclude_from_sim no)
			(in_bom yes)
			(on_board yes)
			(property "Reference" "J"
				(at 1.27 10.16 0)
				(effects
					(font
						(size 1.27 1.27)
					)
				)
			)
			(property "Value" "Conn_02x08_Odd_Even"
				(at 1.27 -12.7 0)
				(effects
					(font
						(size 1.27 1.27)
					)
				)
			)
			(property "Footprint" ""
				(at 0 0 0)
				(effects
					(font
						(size 1.27 1.27)
					)
					(hide yes)
				)
			)
			(property "Datasheet" "~"
				(at 0 0 0)
				(effects
					(font
						(size 1.27 1.27)
					)
					(hide yes)
				)
			)
			(property "Description" "Generic connector, double row, 02x08, odd/even pin numbering scheme (row 1 odd numbers, row 2 even numbers), script generated (kicad-library-utils/schlib/autogen/connector/)"
				(at 0 0 0)
				(effects
					(font
						(size 1.27 1.27)
					)
					(hide yes)
				)
			)
			(property "ki_keywords" "connector"
				(at 0 0 0)
				(effects
					(font
						(size 1.27 1.27)
					)
					(hide yes)
				)
			)
			(property "ki_fp_filters" "Connector*:*_2x??_*"
				(at 0 0 0)
				(effects
					(font
						(size 1.27 1.27)
					)
					(hide yes)
				)
			)
			(symbol "Conn_02x08_Odd_Even_1_1"
				(rectangle
					(start -1.27 -10.033)
					(end 0 -10.287)
					(stroke
						(width 0.1524)
						(type default)
					)
					(fill
						(type none)
					)
				)
				(rectangle
					(start -1.27 -7.493)
					(end 0 -7.747)
					(stroke
						(width 0.1524)
						(type default)
					)
					(fill
						(type none)
					)
				)
				(rectangle
					(start -1.27 -4.953)
					(end 0 -5.207)
					(stroke
						(width 0.1524)
						(type default)
					)
					(fill
						(type none)
					)
				)
				(rectangle
					(start -1.27 -2.413)
					(end 0 -2.667)
					(stroke
						(width 0.1524)
						(type default)
					)
					(fill
						(type none)
					)
				)
				(rectangle
					(start -1.27 0.127)
					(end 0 -0.127)
					(stroke
						(width 0.1524)
						(type default)
					)
					(fill
						(type none)
					)
				)
				(rectangle
					(start -1.27 2.667)
					(end 0 2.413)
					(stroke
						(width 0.1524)
						(type default)
					)
					(fill
						(type none)
					)
				)
				(rectangle
					(start -1.27 5.207)
					(end 0 4.953)
					(stroke
						(width 0.1524)
						(type default)
					)
					(fill
						(type none)
					)
				)
				(rectangle
					(start -1.27 7.747)
					(end 0 7.493)
					(stroke
						(width 0.1524)
						(type default)
					)
					(fill
						(type none)
					)
				)
				(rectangle
					(start -1.27 8.89)
					(end 3.81 -11.43)
					(stroke
						(width 0.254)
						(type default)
					)
					(fill
						(type background)
					)
				)
				(rectangle
					(start 3.81 -10.033)
					(end 2.54 -10.287)
					(stroke
						(width 0.1524)
						(type default)
					)
					(fill
						(type none)
					)
				)
				(rectangle
					(start 3.81 -7.493)
					(end 2.54 -7.747)
					(stroke
						(width 0.1524)
						(type default)
					)
					(fill
						(type none)
					)
				)
				(rectangle
					(start 3.81 -4.953)
					(end 2.54 -5.207)
					(stroke
						(width 0.1524)
						(type default)
					)
					(fill
						(type none)
					)
				)
				(rectangle
					(start 3.81 -2.413)
					(end 2.54 -2.667)
					(stroke
						(width 0.1524)
						(type default)
					)
					(fill
						(type none)
					)
				)
				(rectangle
					(start 3.81 0.127)
					(end 2.54 -0.127)
					(stroke
						(width 0.1524)
						(type default)
					)
					(fill
						(type none)
					)
				)
				(rectangle
					(start 3.81 2.667)
					(end 2.54 2.413)
					(stroke
						(width 0.1524)
						(type default)
					)
					(fill
						(type none)
					)
				)
				(rectangle
					(start 3.81 5.207)
					(end 2.54 4.953)
					(stroke
						(width 0.1524)
						(type default)
					)
					(fill
						(type none)
					)
				)
				(rectangle
					(start 3.81 7.747)
					(end 2.54 7.493)
					(stroke
						(width 0.1524)
						(type default)
					)
					(fill
						(type none)
					)
				)
				(pin passive line
					(at -5.08 7.62 0)
					(length 3.81)
					(name "Pin_1"
						(effects
							(font
								(size 1.27 1.27)
							)
						)
					)
					(number "1"
						(effects
							(font
								(size 1.27 1.27)
							)
						)
					)
				)
				(pin passive line
					(at 7.62 -2.54 180)
					(length 3.81)
					(name "Pin_10"
						(effects
							(font
								(size 1.27 1.27)
							)
						)
					)
					(number "10"
						(effects
							(font
								(size 1.27 1.27)
							)
						)
					)
				)
				(pin passive line
					(at -5.08 -5.08 0)
					(length 3.81)
					(name "Pin_11"
						(effects
							(font
								(size 1.27 1.27)
							)
						)
					)
					(number "11"
						(effects
							(font
								(size 1.27 1.27)
							)
						)
					)
				)
				(pin passive line
					(at 7.62 -5.08 180)
					(length 3.81)
					(name "Pin_12"
						(effects
							(font
								(size 1.27 1.27)
							)
						)
					)
					(number "12"
						(effects
							(font
								(size 1.27 1.27)
							)
						)
					)
				)
				(pin passive line
					(at -5.08 -7.62 0)
					(length 3.81)
					(name "Pin_13"
						(effects
							(font
								(size 1.27 1.27)
							)
						)
					)
					(number "13"
						(effects
							(font
								(size 1.27 1.27)
							)
						)
					)
				)
				(pin passive line
					(at 7.62 -7.62 180)
					(length 3.81)
					(name "Pin_14"
						(effects
							(font
								(size 1.27 1.27)
							)
						)
					)
					(number "14"
						(effects
							(font
								(size 1.27 1.27)
							)
						)
					)
				)
				(pin passive line
					(at -5.08 -10.16 0)
					(length 3.81)
					(name "Pin_15"
						(effects
							(font
								(size 1.27 1.27)
							)
						)
					)
					(number "15"
						(effects
							(font
								(size 1.27 1.27)
							)
						)
					)
				)
				(pin passive line
					(at 7.62 -10.16 180)
					(length 3.81)
					(name "Pin_16"
						(effects
							(font
								(size 1.27 1.27)
							)
						)
					)
					(number "16"
						(effects
							(font
								(size 1.27 1.27)
							)
						)
					)
				)
				(pin passive line
					(at 7.62 7.62 180)
					(length 3.81)
					(name "Pin_2"
						(effects
							(font
								(size 1.27 1.27)
							)
						)
					)
					(number "2"
						(effects
							(font
								(size 1.27 1.27)
							)
						)
					)
				)
				(pin passive line
					(at -5.08 5.08 0)
					(length 3.81)
					(name "Pin_3"
						(effects
							(font
								(size 1.27 1.27)
							)
						)
					)
					(number "3"
						(effects
							(font
								(size 1.27 1.27)
							)
						)
					)
				)
				(pin passive line
					(at 7.62 5.08 180)
					(length 3.81)
					(name "Pin_4"
						(effects
							(font
								(size 1.27 1.27)
							)
						)
					)
					(number "4"
						(effects
							(font
								(size 1.27 1.27)
							)
						)
					)
				)
				(pin passive line
					(at -5.08 2.54 0)
					(length 3.81)
					(name "Pin_5"
						(effects
							(font
								(size 1.27 1.27)
							)
						)
					)
					(number "5"
						(effects
							(font
								(size 1.27 1.27)
							)
						)
					)
				)
				(pin passive line
					(at 7.62 2.54 180)
					(length 3.81)
					(name "Pin_6"
						(effects
							(font
								(size 1.27 1.27)
							)
						)
					)
					(number "6"
						(effects
							(font
								(size 1.27 1.27)
							)
						)
					)
				)
				(pin passive line
					(at -5.08 0 0)
					(length 3.81)
					(name "Pin_7"
						(effects
							(font
								(size 1.27 1.27)
							)
						)
					)
					(number "7"
						(effects
							(font
								(size 1.27 1.27)
							)
						)
					)
				)
				(pin passive line
					(at 7.62 0 180)
					(length 3.81)
					(name "Pin_8"
						(effects
							(font
								(size 1.27 1.27)
							)
						)
					)
					(number "8"
						(effects
							(font
								(size 1.27 1.27)
							)
						)
					)
				)
				(pin passive line
					(at -5.08 -2.54 0)
					(length 3.81)
					(name "Pin_9"
						(effects
							(font
								(size 1.27 1.27)
							)
						)
					)
					(number "9"
						(effects
							(font
								(size 1.27 1.27)
							)
						)
					)
				)
			)
		)
		(symbol "Device:C"
			(pin_numbers hide)
			(pin_names
				(offset 0.254)
			)
			(exclude_from_sim no)
			(in_bom yes)
			(on_board yes)
			(property "Reference" "C"
				(at 0.635 2.54 0)
				(effects
					(font
						(size 1.27 1.27)
					)
					(justify left)
				)
			)
			(property "Value" "C"
				(at 0.635 -2.54 0)
				(effects
					(font
						(size 1.27 1.27)
					)
					(justify left)
				)
			)
			(property "Footprint" ""
				(at 0.9652 -3.81 0)
				(effects
					(font
						(size 1.27 1.27)
					)
					(hide yes)
				)
			)
			(property "Datasheet" "~"
				(at 0 0 0)
				(effects
					(font
						(size 1.27 1.27)
					)
					(hide yes)
				)
			)
			(property "Description" "Unpolarized capacitor"
				(at 0 0 0)
				(effects
					(font
						(size 1.27 1.27)
					)
					(hide yes)
				)
			)
			(property "ki_keywords" "cap capacitor"
				(at 0 0 0)
				(effects
					(font
						(size 1.27 1.27)
					)
					(hide yes)
				)
			)
			(property "ki_fp_filters" "C_*"
				(at 0 0 0)
				(effects
					(font
						(size 1.27 1.27)
					)
					(hide yes)
				)
			)
			(symbol "C_0_1"
				(polyline
					(pts
						(xy -2.032 -0.762) (xy 2.032 -0.762)
					)
					(stroke
						(width 0.508)
						(type default)
					)
					(fill
						(type none)
					)
				)
				(polyline
					(pts
						(xy -2.032 0.762) (xy 2.032 0.762)
					)
					(stroke
						(width 0.508)
						(type default)
					)
					(fill
						(type none)
					)
				)
			)
			(symbol "C_1_1"
				(pin passive line
					(at 0 3.81 270)
					(length 2.794)
					(name "~"
						(effects
							(font
								(size 1.27 1.27)
							)
						)
					)
					(number "1"
						(effects
							(font
								(size 1.27 1.27)
							)
						)
					)
				)
				(pin passive line
					(at 0 -3.81 90)
					(length 2.794)
					(name "~"
						(effects
							(font
								(size 1.27 1.27)
							)
						)
					)
					(number "2"
						(effects
							(font
								(size 1.27 1.27)
							)
						)
					)
				)
			)
		)
		(symbol "Device:D"
			(pin_numbers hide)
			(pin_names
				(offset 1.016) hide)
			(exclude_from_sim no)
			(in_bom yes)
			(on_board yes)
			(property "Reference" "D"
				(at 0 2.54 0)
				(effects
					(font
						(size 1.27 1.27)
					)
				)
			)
			(property "Value" "D"
				(at 0 -2.54 0)
				(effects
					(font
						(size 1.27 1.27)
					)
				)
			)
			(property "Footprint" ""
				(at 0 0 0)
				(effects
					(font
						(size 1.27 1.27)
					)
					(hide yes)
				)
			)
			(property "Datasheet" "~"
				(at 0 0 0)
				(effects
					(font
						(size 1.27 1.27)
					)
					(hide yes)
				)
			)
			(property "Description" "Diode"
				(at 0 0 0)
				(effects
					(font
						(size 1.27 1.27)
					)
					(hide yes)
				)
			)
			(property "Sim.Device" "D"
				(at 0 0 0)
				(effects
					(font
						(size 1.27 1.27)
					)
					(hide yes)
				)
			)
			(property "Sim.Pins" "1=K 2=A"
				(at 0 0 0)
				(effects
					(font
						(size 1.27 1.27)
					)
					(hide yes)
				)
			)
			(property "ki_keywords" "diode"
				(at 0 0 0)
				(effects
					(font
						(size 1.27 1.27)
					)
					(hide yes)
				)
			)
			(property "ki_fp_filters" "TO-???* *_Diode_* *SingleDiode* D_*"
				(at 0 0 0)
				(effects
					(font
						(size 1.27 1.27)
					)
					(hide yes)
				)
			)
			(symbol "D_0_1"
				(polyline
					(pts
						(xy -1.27 1.27) (xy -1.27 -1.27)
					)
					(stroke
						(width 0.254)
						(type default)
					)
					(fill
						(type none)
					)
				)
				(polyline
					(pts
						(xy 1.27 0) (xy -1.27 0)
					)
					(stroke
						(width 0)
						(type default)
					)
					(fill
						(type none)
					)
				)
				(polyline
					(pts
						(xy 1.27 1.27) (xy 1.27 -1.27) (xy -1.27 0) (xy 1.27 1.27)
					)
					(stroke
						(width 0.254)
						(type default)
					)
					(fill
						(type none)
					)
				)
			)
			(symbol "D_1_1"
				(pin passive line
					(at -3.81 0 0)
					(length 2.54)
					(name "K"
						(effects
							(font
								(size 1.27 1.27)
							)
						)
					)
					(number "1"
						(effects
							(font
								(size 1.27 1.27)
							)
						)
					)
				)
				(pin passive line
					(at 3.81 0 180)
					(length 2.54)
					(name "A"
						(effects
							(font
								(size 1.27 1.27)
							)
						)
					)
					(number "2"
						(effects
							(font
								(size 1.27 1.27)
							)
						)
					)
				)
			)
		)
		(symbol "Device:R"
			(pin_numbers hide)
			(pin_names
				(offset 0)
			)
			(exclude_from_sim no)
			(in_bom yes)
			(on_board yes)
			(property "Reference" "R"
				(at 2.032 0 90)
				(effects
					(font
						(size 1.27 1.27)
					)
				)
			)
			(property "Value" "R"
				(at 0 0 90)
				(effects
					(font
						(size 1.27 1.27)
					)
				)
			)
			(property "Footprint" ""
				(at -1.778 0 90)
				(effects
					(font
						(size 1.27 1.27)
					)
					(hide yes)
				)
			)
			(property "Datasheet" "~"
				(at 0 0 0)
				(effects
					(font
						(size 1.27 1.27)
					)
					(hide yes)
				)
			)
			(property "Description" "Resistor"
				(at 0 0 0)
				(effects
					(font
						(size 1.27 1.27)
					)
					(hide yes)
				)
			)
			(property "ki_keywords" "R res resistor"
				(at 0 0 0)
				(effects
					(font
						(size 1.27 1.27)
					)
					(hide yes)
				)
			)
			(property "ki_fp_filters" "R_*"
				(at 0 0 0)
				(effects
					(font
						(size 1.27 1.27)
					)
					(hide yes)
				)
			)
			(symbol "R_0_1"
				(rectangle
					(start -1.016 -2.54)
					(end 1.016 2.54)
					(stroke
						(width 0.254)
						(type default)
					)
					(fill
						(type none)
					)
				)
			)
			(symbol "R_1_1"
				(pin passive line
					(at 0 3.81 270)
					(length 1.27)
					(name "~"
						(effects
							(font
								(size 1.27 1.27)
							)
						)
					)
					(number "1"
						(effects
							(font
								(size 1.27 1.27)
							)
						)
					)
				)
				(pin passive line
					(at 0 -3.81 90)
					(length 1.27)
					(name "~"
						(effects
							(font
								(size 1.27 1.27)
							)
						)
					)
					(number "2"
						(effects
							(font
								(size 1.27 1.27)
							)
						)
					)
				)
			)
		)
		(symbol "Graphic:Logo_Open_Hardware_Small"
			(exclude_from_sim no)
			(in_bom no)
			(on_board no)
			(property "Reference" "#SYM"
				(at 0 6.985 0)
				(effects
					(font
						(size 1.27 1.27)
					)
					(hide yes)
				)
			)
			(property "Value" "Logo_Open_Hardware_Small"
				(at 0 -5.715 0)
				(effects
					(font
						(size 1.27 1.27)
					)
					(hide yes)
				)
			)
			(property "Footprint" ""
				(at 0 0 0)
				(effects
					(font
						(size 1.27 1.27)
					)
					(hide yes)
				)
			)
			(property "Datasheet" "~"
				(at 0 0 0)
				(effects
					(font
						(size 1.27 1.27)
					)
					(hide yes)
				)
			)
			(property "Description" "Open Hardware logo, small"
				(at 0 0 0)
				(effects
					(font
						(size 1.27 1.27)
					)
					(hide yes)
				)
			)
			(property "Sim.Enable" "0"
				(at 0 0 0)
				(effects
					(font
						(size 1.27 1.27)
					)
					(hide yes)
				)
			)
			(property "ki_keywords" "Logo"
				(at 0 0 0)
				(effects
					(font
						(size 1.27 1.27)
					)
					(hide yes)
				)
			)
			(symbol "Logo_Open_Hardware_Small_0_1"
				(polyline
					(pts
						(xy 3.3528 -4.3434) (xy 3.302 -4.318) (xy 3.175 -4.2418) (xy 2.9972 -4.1148) (xy 2.7686 -3.9624)
						(xy 2.54 -3.81) (xy 2.3622 -3.7084) (xy 2.2352 -3.6068) (xy 2.1844 -3.5814) (xy 2.159 -3.6068)
						(xy 2.0574 -3.6576) (xy 1.905 -3.7338) (xy 1.8034 -3.7846) (xy 1.6764 -3.8354) (xy 1.6002 -3.8354)
						(xy 1.6002 -3.8354) (xy 1.5494 -3.7338) (xy 1.4732 -3.5306) (xy 1.3462 -3.302) (xy 1.2446 -3.0226)
						(xy 1.1176 -2.7178) (xy 0.9652 -2.413) (xy 0.8636 -2.1082) (xy 0.7366 -1.8288) (xy 0.6604 -1.6256)
						(xy 0.6096 -1.4732) (xy 0.5842 -1.397) (xy 0.5842 -1.397) (xy 0.6604 -1.3208) (xy 0.7874 -1.2446)
						(xy 1.0414 -1.016) (xy 1.2954 -0.6858) (xy 1.4478 -0.3302) (xy 1.524 0.0762) (xy 1.4732 0.4572)
						(xy 1.3208 0.8128) (xy 1.0668 1.143) (xy 0.762 1.3716) (xy 0.4064 1.524) (xy 0 1.5748) (xy -0.381 1.5494)
						(xy -0.7366 1.397) (xy -1.0668 1.143) (xy -1.2192 0.9906) (xy -1.397 0.6604) (xy -1.524 0.3048)
						(xy -1.524 0.2286) (xy -1.4986 -0.1778) (xy -1.397 -0.5334) (xy -1.1938 -0.8636) (xy -0.9144 -1.143)
						(xy -0.8636 -1.1684) (xy -0.7366 -1.27) (xy -0.635 -1.3462) (xy -0.5842 -1.397) (xy -1.0668 -2.5908)
						(xy -1.143 -2.794) (xy -1.2954 -3.1242) (xy -1.397 -3.4036) (xy -1.4986 -3.6322) (xy -1.5748 -3.7846)
						(xy -1.6002 -3.8354) (xy -1.6002 -3.8354) (xy -1.651 -3.8354) (xy -1.7272 -3.81) (xy -1.905 -3.7338)
						(xy -2.0066 -3.683) (xy -2.1336 -3.6068) (xy -2.2098 -3.5814) (xy -2.2606 -3.6068) (xy -2.3622 -3.683)
						(xy -2.54 -3.81) (xy -2.7686 -3.9624) (xy -2.9718 -4.0894) (xy -3.1496 -4.2164) (xy -3.302 -4.318)
						(xy -3.3528 -4.3434) (xy -3.3782 -4.3434) (xy -3.429 -4.318) (xy -3.5306 -4.2164) (xy -3.7084 -4.064)
						(xy -3.937 -3.8354) (xy -3.9624 -3.81) (xy -4.1656 -3.6068) (xy -4.318 -3.4544) (xy -4.4196 -3.3274)
						(xy -4.445 -3.2766) (xy -4.445 -3.2766) (xy -4.4196 -3.2258) (xy -4.318 -3.0734) (xy -4.2164 -2.8956)
						(xy -4.064 -2.667) (xy -3.6576 -2.0828) (xy -3.8862 -1.5494) (xy -3.937 -1.3716) (xy -4.0386 -1.1684)
						(xy -4.0894 -1.0414) (xy -4.1148 -0.9652) (xy -4.191 -0.9398) (xy -4.318 -0.9144) (xy -4.5466 -0.8636)
						(xy -4.8006 -0.8128) (xy -5.0546 -0.7874) (xy -5.2578 -0.7366) (xy -5.4356 -0.7112) (xy -5.5118 -0.6858)
						(xy -5.5118 -0.6858) (xy -5.5372 -0.635) (xy -5.5372 -0.5588) (xy -5.5372 -0.4318) (xy -5.5626 -0.2286)
						(xy -5.5626 0.0762) (xy -5.5626 0.127) (xy -5.5372 0.4064) (xy -5.5372 0.635) (xy -5.5372 0.762)
						(xy -5.5372 0.8382) (xy -5.5372 0.8382) (xy -5.461 0.8382) (xy -5.3086 0.889) (xy -5.08 0.9144)
						(xy -4.826 0.9652) (xy -4.8006 0.9906) (xy -4.5466 1.0414) (xy -4.318 1.0668) (xy -4.1656 1.1176)
						(xy -4.0894 1.143) (xy -4.0894 1.143) (xy -4.0386 1.2446) (xy -3.9624 1.4224) (xy -3.8608 1.6256)
						(xy -3.7846 1.8288) (xy -3.7084 2.0066) (xy -3.6576 2.159) (xy -3.6322 2.2098) (xy -3.6322 2.2098)
						(xy -3.683 2.286) (xy -3.7592 2.413) (xy -3.8862 2.5908) (xy -4.064 2.8194) (xy -4.064 2.8448)
						(xy -4.2164 3.0734) (xy -4.3434 3.2512) (xy -4.4196 3.3782) (xy -4.445 3.4544) (xy -4.445 3.4544)
						(xy -4.3942 3.5052) (xy -4.2926 3.6322) (xy -4.1148 3.81) (xy -3.937 4.0132) (xy -3.8608 4.064)
						(xy -3.6576 4.2926) (xy -3.5052 4.4196) (xy -3.4036 4.4958) (xy -3.3528 4.5212) (xy -3.3528 4.5212)
						(xy -3.302 4.4704) (xy -3.1496 4.3688) (xy -2.9718 4.2418) (xy -2.7432 4.0894) (xy -2.7178 4.0894)
						(xy -2.4892 3.937) (xy -2.3114 3.81) (xy -2.1844 3.7084) (xy -2.1336 3.683) (xy -2.1082 3.683)
						(xy -2.032 3.7084) (xy -1.8542 3.7592) (xy -1.6764 3.8354) (xy -1.4732 3.937) (xy -1.27 4.0132)
						(xy -1.143 4.064) (xy -1.0668 4.1148) (xy -1.0668 4.1148) (xy -1.0414 4.191) (xy -1.016 4.3434)
						(xy -0.9652 4.572) (xy -0.9144 4.8514) (xy -0.889 4.9022) (xy -0.8382 5.1562) (xy -0.8128 5.3848)
						(xy -0.7874 5.5372) (xy -0.762 5.588) (xy -0.7112 5.6134) (xy -0.5842 5.6134) (xy -0.4064 5.6134)
						(xy -0.1524 5.6134) (xy 0.0762 5.6134) (xy 0.3302 5.6134) (xy 0.5334 5.6134) (xy 0.6858 5.588)
						(xy 0.7366 5.588) (xy 0.7366 5.588) (xy 0.762 5.5118) (xy 0.8128 5.334) (xy 0.8382 5.1054) (xy 0.9144 4.826)
						(xy 0.9144 4.7752) (xy 0.9652 4.5212) (xy 1.016 4.2926) (xy 1.0414 4.1402) (xy 1.0668 4.0894)
						(xy 1.0668 4.0894) (xy 1.1938 4.0386) (xy 1.3716 3.9624) (xy 1.5748 3.8608) (xy 2.0828 3.6576)
						(xy 2.7178 4.0894) (xy 2.7686 4.1402) (xy 2.9972 4.2926) (xy 3.175 4.4196) (xy 3.302 4.4958) (xy 3.3782 4.5212)
						(xy 3.3782 4.5212) (xy 3.429 4.4704) (xy 3.556 4.3434) (xy 3.7338 4.191) (xy 3.9116 3.9878) (xy 4.064 3.8354)
						(xy 4.2418 3.6576) (xy 4.3434 3.556) (xy 4.4196 3.4798) (xy 4.4196 3.429) (xy 4.4196 3.4036) (xy 4.3942 3.3274)
						(xy 4.2926 3.2004) (xy 4.1656 2.9972) (xy 4.0132 2.794) (xy 3.8862 2.5908) (xy 3.7592 2.3876)
						(xy 3.6576 2.2352) (xy 3.6322 2.159) (xy 3.6322 2.1336) (xy 3.683 2.0066) (xy 3.7592 1.8288) (xy 3.8608 1.6002)
						(xy 4.064 1.1176) (xy 4.3942 1.0414) (xy 4.5974 1.016) (xy 4.8768 0.9652) (xy 5.1308 0.9144) (xy 5.5372 0.8382)
						(xy 5.5626 -0.6604) (xy 5.4864 -0.6858) (xy 5.4356 -0.6858) (xy 5.2832 -0.7366) (xy 5.0546 -0.762)
						(xy 4.8006 -0.8128) (xy 4.5974 -0.8636) (xy 4.3688 -0.9144) (xy 4.2164 -0.9398) (xy 4.1402 -0.9398)
						(xy 4.1148 -0.9652) (xy 4.064 -1.0668) (xy 3.9878 -1.2446) (xy 3.9116 -1.4478) (xy 3.81 -1.651)
						(xy 3.7338 -1.8542) (xy 3.683 -2.0066) (xy 3.6576 -2.0828) (xy 3.683 -2.1336) (xy 3.7846 -2.2606)
						(xy 3.8862 -2.4638) (xy 4.0386 -2.667) (xy 4.191 -2.8956) (xy 4.318 -3.0734) (xy 4.3942 -3.2004)
						(xy 4.445 -3.2766) (xy 4.4196 -3.3274) (xy 4.3434 -3.429) (xy 4.1656 -3.5814) (xy 3.937 -3.8354)
						(xy 3.8862 -3.8608) (xy 3.683 -4.064) (xy 3.5306 -4.2164) (xy 3.4036 -4.318) (xy 3.3528 -4.3434)
					)
					(stroke
						(width 0)
						(type default)
					)
					(fill
						(type outline)
					)
				)
			)
		)
		(symbol "rtc-sd-rescue:+5V-power"
			(power)
			(pin_names
				(offset 0)
			)
			(exclude_from_sim no)
			(in_bom yes)
			(on_board yes)
			(property "Reference" "#PWR"
				(at 0 -3.81 0)
				(effects
					(font
						(size 1.27 1.27)
					)
					(hide yes)
				)
			)
			(property "Value" "power_+5V"
				(at 0 3.556 0)
				(effects
					(font
						(size 1.27 1.27)
					)
				)
			)
			(property "Footprint" ""
				(at 0 0 0)
				(effects
					(font
						(size 1.27 1.27)
					)
					(hide yes)
				)
			)
			(property "Datasheet" ""
				(at 0 0 0)
				(effects
					(font
						(size 1.27 1.27)
					)
					(hide yes)
				)
			)
			(property "Description" ""
				(at 0 0 0)
				(effects
					(font
						(size 1.27 1.27)
					)
					(hide yes)
				)
			)
			(symbol "+5V-power_0_1"
				(polyline
					(pts
						(xy -0.762 1.27) (xy 0 2.54)
					)
					(stroke
						(width 0)
						(type solid)
					)
					(fill
						(type none)
					)
				)
				(polyline
					(pts
						(xy 0 0) (xy 0 2.54)
					)
					(stroke
						(width 0)
						(type solid)
					)
					(fill
						(type none)
					)
				)
				(polyline
					(pts
						(xy 0 2.54) (xy 0.762 1.27)
					)
					(stroke
						(width 0)
						(type solid)
					)
					(fill
						(type none)
					)
				)
			)
			(symbol "+5V-power_1_1"
				(pin power_in line
					(at 0 0 90)
					(length 0) hide
					(name "+5V"
						(effects
							(font
								(size 1.27 1.27)
							)
						)
					)
					(number "1"
						(effects
							(font
								(size 1.27 1.27)
							)
						)
					)
				)
			)
		)
		(symbol "rtc-sd-rescue:2N7000-dk_Transistors-FETs-MOSFETs-Single"
			(pin_names
				(offset 0)
			)
			(exclude_from_sim no)
			(in_bom yes)
			(on_board yes)
			(property "Reference" "Q"
				(at -2.6924 3.6322 0)
				(effects
					(font
						(size 1.524 1.524)
					)
					(justify right)
				)
			)
			(property "Value" "dk_Transistors-FETs-MOSFETs-Single_2N7000"
				(at 3.4544 0 90)
				(effects
					(font
						(size 1.524 1.524)
					)
				)
			)
			(property "Footprint" "digikey-footprints:TO-92-3"
				(at 5.08 5.08 0)
				(effects
					(font
						(size 1.524 1.524)
					)
					(justify left)
					(hide yes)
				)
			)
			(property "Datasheet" "https://www.onsemi.com/pub/Collateral/NDS7002A-D.PDF"
				(at 5.08 7.62 0)
				(effects
					(font
						(size 1.524 1.524)
					)
					(justify left)
					(hide yes)
				)
			)
			(property "Description" ""
				(at 0 0 0)
				(effects
					(font
						(size 1.27 1.27)
					)
					(hide yes)
				)
			)
			(property "Digi-Key_PN" "2N7000FS-ND"
				(at 5.08 10.16 0)
				(effects
					(font
						(size 1.524 1.524)
					)
					(justify left)
					(hide yes)
				)
			)
			(property "MPN" "2N7000"
				(at 5.08 12.7 0)
				(effects
					(font
						(size 1.524 1.524)
					)
					(justify left)
					(hide yes)
				)
			)
			(property "Category" "Discrete Semiconductor Products"
				(at 5.08 15.24 0)
				(effects
					(font
						(size 1.524 1.524)
					)
					(justify left)
					(hide yes)
				)
			)
			(property "Family" "Transistors - FETs, MOSFETs - Single"
				(at 5.08 17.78 0)
				(effects
					(font
						(size 1.524 1.524)
					)
					(justify left)
					(hide yes)
				)
			)
			(property "DK_Datasheet_Link" "https://www.onsemi.com/pub/Collateral/NDS7002A-D.PDF"
				(at 5.08 20.32 0)
				(effects
					(font
						(size 1.524 1.524)
					)
					(justify left)
					(hide yes)
				)
			)
			(property "DK_Detail_Page" "/product-detail/en/on-semiconductor/2N7000/2N7000FS-ND/244278"
				(at 5.08 22.86 0)
				(effects
					(font
						(size 1.524 1.524)
					)
					(justify left)
					(hide yes)
				)
			)
			(property "Description_1" "MOSFET N-CH 60V 200MA TO-92"
				(at 5.08 25.4 0)
				(effects
					(font
						(size 1.524 1.524)
					)
					(justify left)
					(hide yes)
				)
			)
			(property "Manufacturer" "ON Semiconductor"
				(at 5.08 27.94 0)
				(effects
					(font
						(size 1.524 1.524)
					)
					(justify left)
					(hide yes)
				)
			)
			(property "Status" "Active"
				(at 5.08 30.48 0)
				(effects
					(font
						(size 1.524 1.524)
					)
					(justify left)
					(hide yes)
				)
			)
			(symbol "2N7000-dk_Transistors-FETs-MOSFETs-Single_0_1"
				(circle
					(center -1.27 0)
					(radius 3.302)
					(stroke
						(width 0)
						(type solid)
					)
					(fill
						(type background)
					)
				)
				(circle
					(center 0 -1.905)
					(radius 0.127)
					(stroke
						(width 0)
						(type solid)
					)
					(fill
						(type none)
					)
				)
				(circle
					(center 0 -1.397)
					(radius 0.127)
					(stroke
						(width 0)
						(type solid)
					)
					(fill
						(type none)
					)
				)
				(polyline
					(pts
						(xy 0 -1.397) (xy -2.54 -1.397)
					)
					(stroke
						(width 0)
						(type solid)
					)
					(fill
						(type none)
					)
				)
				(polyline
					(pts
						(xy -5.08 -2.54) (xy -3.048 -2.54) (xy -3.048 1.397)
					)
					(stroke
						(width 0)
						(type solid)
					)
					(fill
						(type none)
					)
				)
				(polyline
					(pts
						(xy 0 -2.54) (xy 0 0) (xy -2.54 0)
					)
					(stroke
						(width 0)
						(type solid)
					)
					(fill
						(type none)
					)
				)
				(polyline
					(pts
						(xy 0 2.54) (xy 0 1.397) (xy -2.54 1.397)
					)
					(stroke
						(width 0)
						(type solid)
					)
					(fill
						(type none)
					)
				)
				(polyline
					(pts
						(xy -0.127 -1.905) (xy 1.016 -1.905) (xy 1.016 1.397) (xy 1.016 1.905) (xy -0.127 1.905)
					)
					(stroke
						(width 0)
						(type solid)
					)
					(fill
						(type none)
					)
				)
				(circle
					(center 0 1.905)
					(radius 0.127)
					(stroke
						(width 0)
						(type solid)
					)
					(fill
						(type none)
					)
				)
			)
			(symbol "2N7000-dk_Transistors-FETs-MOSFETs-Single_1_1"
				(polyline
					(pts
						(xy -2.54 -1.397) (xy -2.54 -1.905)
					)
					(stroke
						(width 0)
						(type solid)
					)
					(fill
						(type none)
					)
				)
				(polyline
					(pts
						(xy -2.54 -1.397) (xy -2.54 -0.889)
					)
					(stroke
						(width 0)
						(type solid)
					)
					(fill
						(type none)
					)
				)
				(polyline
					(pts
						(xy -2.54 0) (xy -2.54 -0.508)
					)
					(stroke
						(width 0)
						(type solid)
					)
					(fill
						(type none)
					)
				)
				(polyline
					(pts
						(xy -2.54 0) (xy -2.54 0.508)
					)
					(stroke
						(width 0)
						(type solid)
					)
					(fill
						(type none)
					)
				)
				(polyline
					(pts
						(xy -2.54 1.905) (xy -2.54 0.889)
					)
					(stroke
						(width 0)
						(type solid)
					)
					(fill
						(type none)
					)
				)
				(polyline
					(pts
						(xy 1.524 0.508) (xy 0.508 0.508)
					)
					(stroke
						(width 0)
						(type solid)
					)
					(fill
						(type none)
					)
				)
				(polyline
					(pts
						(xy -2.54 0) (xy -1.778 0.508) (xy -1.778 -0.508) (xy -2.54 0)
					)
					(stroke
						(width 0)
						(type solid)
					)
					(fill
						(type outline)
					)
				)
				(polyline
					(pts
						(xy 1.016 0.508) (xy 0.508 -0.254) (xy 1.524 -0.254) (xy 1.016 0.508)
					)
					(stroke
						(width 0)
						(type solid)
					)
					(fill
						(type outline)
					)
				)
				(pin bidirectional line
					(at 0 -5.08 90)
					(length 2.54)
					(name "S"
						(effects
							(font
								(size 1.27 1.27)
							)
						)
					)
					(number "1"
						(effects
							(font
								(size 1.27 1.27)
							)
						)
					)
				)
				(pin bidirectional line
					(at -7.62 -2.54 0)
					(length 2.54)
					(name "G"
						(effects
							(font
								(size 1.27 1.27)
							)
						)
					)
					(number "2"
						(effects
							(font
								(size 1.27 1.27)
							)
						)
					)
				)
				(pin bidirectional line
					(at 0 5.08 270)
					(length 2.54)
					(name "D"
						(effects
							(font
								(size 1.27 1.27)
							)
						)
					)
					(number "3"
						(effects
							(font
								(size 1.27 1.27)
							)
						)
					)
				)
			)
		)
		(symbol "rtc-sd-rescue:GND-power"
			(power)
			(pin_names
				(offset 0)
			)
			(exclude_from_sim no)
			(in_bom yes)
			(on_board yes)
			(property "Reference" "#PWR"
				(at 0 -6.35 0)
				(effects
					(font
						(size 1.27 1.27)
					)
					(hide yes)
				)
			)
			(property "Value" "power_GND"
				(at 0 -3.81 0)
				(effects
					(font
						(size 1.27 1.27)
					)
				)
			)
			(property "Footprint" ""
				(at 0 0 0)
				(effects
					(font
						(size 1.27 1.27)
					)
					(hide yes)
				)
			)
			(property "Datasheet" ""
				(at 0 0 0)
				(effects
					(font
						(size 1.27 1.27)
					)
					(hide yes)
				)
			)
			(property "Description" ""
				(at 0 0 0)
				(effects
					(font
						(size 1.27 1.27)
					)
					(hide yes)
				)
			)
			(symbol "GND-power_0_1"
				(polyline
					(pts
						(xy 0 0) (xy 0 -1.27) (xy 1.27 -1.27) (xy 0 -2.54) (xy -1.27 -1.27) (xy 0 -1.27)
					)
					(stroke
						(width 0)
						(type solid)
					)
					(fill
						(type none)
					)
				)
			)
			(symbol "GND-power_1_1"
				(pin power_in line
					(at 0 0 270)
					(length 0) hide
					(name "GND"
						(effects
							(font
								(size 1.27 1.27)
							)
						)
					)
					(number "1"
						(effects
							(font
								(size 1.27 1.27)
							)
						)
					)
				)
			)
		)
		(symbol "rtc-sd-rescue:PWR_FLAG-power"
			(power)
			(pin_numbers hide)
			(pin_names
				(offset 0) hide)
			(exclude_from_sim no)
			(in_bom yes)
			(on_board yes)
			(property "Reference" "#FLG"
				(at 0 1.905 0)
				(effects
					(font
						(size 1.27 1.27)
					)
					(hide yes)
				)
			)
			(property "Value" "power_PWR_FLAG"
				(at 0 3.81 0)
				(effects
					(font
						(size 1.27 1.27)
					)
				)
			)
			(property "Footprint" ""
				(at 0 0 0)
				(effects
					(font
						(size 1.27 1.27)
					)
					(hide yes)
				)
			)
			(property "Datasheet" ""
				(at 0 0 0)
				(effects
					(font
						(size 1.27 1.27)
					)
					(hide yes)
				)
			)
			(property "Description" ""
				(at 0 0 0)
				(effects
					(font
						(size 1.27 1.27)
					)
					(hide yes)
				)
			)
			(symbol "PWR_FLAG-power_0_0"
				(pin power_out line
					(at 0 0 90)
					(length 0)
					(name "pwr"
						(effects
							(font
								(size 1.27 1.27)
							)
						)
					)
					(number "1"
						(effects
							(font
								(size 1.27 1.27)
							)
						)
					)
				)
			)
			(symbol "PWR_FLAG-power_0_1"
				(polyline
					(pts
						(xy 0 0) (xy 0 1.27) (xy -1.016 1.905) (xy 0 2.54) (xy 1.016 1.905) (xy 0 1.27)
					)
					(stroke
						(width 0)
						(type solid)
					)
					(fill
						(type none)
					)
				)
			)
		)
	)
	(junction
		(at 220.98 144.78)
		(diameter 0)
		(color 0 0 0 0)
		(uuid "0a5a52a1-08fc-4e2f-9796-1afa45d81b91")
	)
	(junction
		(at 134.62 66.04)
		(diameter 0)
		(color 0 0 0 0)
		(uuid "1b2235b8-1e41-4f0c-a74e-d3f1c0ad395f")
	)
	(junction
		(at 142.24 81.28)
		(diameter 0)
		(color 0 0 0 0)
		(uuid "1d9e4419-6544-403f-925c-82700391c3b0")
	)
	(junction
		(at 220.98 149.86)
		(diameter 0)
		(color 0 0 0 0)
		(uuid "1ead2050-742b-4ec7-a869-012f32d3153d")
	)
	(junction
		(at 92.71 156.21)
		(diameter 0)
		(color 0 0 0 0)
		(uuid "229b0714-143d-484d-a6ba-886499bf7a43")
	)
	(junction
		(at 133.35 140.97)
		(diameter 0)
		(color 0 0 0 0)
		(uuid "288859e3-29ad-48f0-b55e-1aee58c1f2eb")
	)
	(junction
		(at 201.93 53.34)
		(diameter 0)
		(color 0 0 0 0)
		(uuid "2ac1407c-9bfc-4552-8031-7f2d36d2b67f")
	)
	(junction
		(at 232.41 142.24)
		(diameter 0)
		(color 0 0 0 0)
		(uuid "33b8658c-f8a5-4135-9f00-95224bd7f512")
	)
	(junction
		(at 138.43 125.73)
		(diameter 0)
		(color 0 0 0 0)
		(uuid "3fafd458-8bd4-461b-b21c-966fa3d4db07")
	)
	(junction
		(at 232.41 124.46)
		(diameter 0)
		(color 0 0 0 0)
		(uuid "44203913-3e2f-4133-a0e3-ccd95f2e3702")
	)
	(junction
		(at 195.58 60.96)
		(diameter 0)
		(color 0 0 0 0)
		(uuid "4a985bbc-802b-4be9-b6cc-bdf6b03121cc")
	)
	(junction
		(at 172.72 60.96)
		(diameter 0)
		(color 0 0 0 0)
		(uuid "571d051e-830b-45a8-b2b4-06bc56421a24")
	)
	(junction
		(at 116.84 93.98)
		(diameter 0)
		(color 0 0 0 0)
		(uuid "5aa3597d-682e-4c48-b9fe-8a9f59f8d538")
	)
	(junction
		(at 229.87 144.78)
		(diameter 0)
		(color 0 0 0 0)
		(uuid "610d18f4-d283-4581-b696-638ae304d152")
	)
	(junction
		(at 232.41 134.62)
		(diameter 0)
		(color 0 0 0 0)
		(uuid "69f78bd7-95ee-48ff-a2e4-38ba14401fdd")
	)
	(junction
		(at 144.78 78.74)
		(diameter 0)
		(color 0 0 0 0)
		(uuid "76bbdb58-8a25-469e-b370-7a37348e2c22")
	)
	(junction
		(at 180.34 53.34)
		(diameter 0)
		(color 0 0 0 0)
		(uuid "820ce30a-0c27-46fb-bb9d-19a552242776")
	)
	(junction
		(at 195.58 53.34)
		(diameter 0)
		(color 0 0 0 0)
		(uuid "843905e5-19d4-4bca-845f-97ac3ecaf19c")
	)
	(junction
		(at 102.87 123.19)
		(diameter 0)
		(color 0 0 0 0)
		(uuid "8c2f7bff-34a7-405d-a4ca-bbd18eb8d34c")
	)
	(junction
		(at 115.57 166.37)
		(diameter 0)
		(color 0 0 0 0)
		(uuid "8cda3900-45e2-4bf5-afc3-00547de60051")
	)
	(junction
		(at 115.57 118.11)
		(diameter 0)
		(color 0 0 0 0)
		(uuid "8fc1b9d6-2cd8-4e90-b12a-d73eabbf7c46")
	)
	(junction
		(at 128.27 55.88)
		(diameter 0)
		(color 0 0 0 0)
		(uuid "909948d1-122b-45ab-9a48-876d3b361148")
	)
	(junction
		(at 107.95 48.26)
		(diameter 0)
		(color 0 0 0 0)
		(uuid "90d85600-773f-495a-be18-d53a64a6d270")
	)
	(junction
		(at 229.87 125.73)
		(diameter 0)
		(color 0 0 0 0)
		(uuid "9b8766a5-bd3a-4ed7-af8d-b5029fb865e0")
	)
	(junction
		(at 63.5 63.5)
		(diameter 0)
		(color 0 0 0 0)
		(uuid "a3bf6f04-0265-43f3-8517-da8bc303876e")
	)
	(junction
		(at 102.87 166.37)
		(diameter 0)
		(color 0 0 0 0)
		(uuid "a44f378e-d944-4b77-ae61-04a25480b329")
	)
	(junction
		(at 118.11 110.49)
		(diameter 0)
		(color 0 0 0 0)
		(uuid "a5e0dbc6-0b70-4690-8b19-e30c61bd3a7f")
	)
	(junction
		(at 156.21 140.97)
		(diameter 0)
		(color 0 0 0 0)
		(uuid "a67c2373-0cf3-48a2-81f1-6bf902ad1a3f")
	)
	(junction
		(at 128.27 66.04)
		(diameter 0)
		(color 0 0 0 0)
		(uuid "beb31e02-48c8-45d3-9a33-5d72783833cf")
	)
	(junction
		(at 63.5 30.48)
		(diameter 0)
		(color 0 0 0 0)
		(uuid "c64aa6b5-bf5f-4241-871f-da777eef47ae")
	)
	(junction
		(at 133.35 166.37)
		(diameter 0)
		(color 0 0 0 0)
		(uuid "cce442ee-4434-4191-b711-6499c54f3329")
	)
	(junction
		(at 128.27 48.26)
		(diameter 0)
		(color 0 0 0 0)
		(uuid "d16901e6-9782-4436-b5f9-455b9ba36d14")
	)
	(junction
		(at 76.2 123.19)
		(diameter 0)
		(color 0 0 0 0)
		(uuid "d388414f-2a7c-4479-b1e5-a34f9365f427")
	)
	(junction
		(at 101.6 66.04)
		(diameter 0)
		(color 0 0 0 0)
		(uuid "e9fbff6d-a308-4fd5-b456-3ab47bef85df")
	)
	(junction
		(at 156.21 166.37)
		(diameter 0)
		(color 0 0 0 0)
		(uuid "ed0f9ae9-3a5a-4a60-9f05-71cd9f6333bf")
	)
	(junction
		(at 95.25 158.75)
		(diameter 0)
		(color 0 0 0 0)
		(uuid "f1775aeb-4046-4951-9009-347c9d80aed2")
	)
	(junction
		(at 60.96 166.37)
		(diameter 0)
		(color 0 0 0 0)
		(uuid "f28fce6d-177e-4e6a-9afb-5ec2801220f2")
	)
	(junction
		(at 72.39 133.35)
		(diameter 0)
		(color 0 0 0 0)
		(uuid "f2c344aa-5733-49dc-b50e-8d3b59bac421")
	)
	(junction
		(at 134.62 48.26)
		(diameter 0)
		(color 0 0 0 0)
		(uuid "f3382c9c-7a0f-414b-b0f4-ecab3dca8fb3")
	)
	(junction
		(at 128.27 73.66)
		(diameter 0)
		(color 0 0 0 0)
		(uuid "f44d610b-e1de-4e88-b153-8f8ffa9c8fbe")
	)
	(no_connect
		(at 128.27 128.27)
		(uuid "36c3a354-8d04-443c-b614-beaee2f07557")
	)
	(no_connect
		(at 101.6 40.64)
		(uuid "940b762a-5a3a-4261-8a6c-e3edb5ddc9ad")
	)
	(no_connect
		(at 227.33 149.86)
		(uuid "bfba9927-f911-443e-affe-093584c3e38b")
	)
	(no_connect
		(at 101.6 45.72)
		(uuid "c1bb07c5-9c46-4d2c-8865-338c10bfbb89")
	)
	(no_connect
		(at 101.6 38.1)
		(uuid "c7f04b23-be50-4a62-8749-2577a3ee3526")
	)
	(no_connect
		(at 101.6 43.18)
		(uuid "cc8a3396-d6ff-4c69-8554-22bc2f1fbe5a")
	)
	(no_connect
		(at 50.8 151.13)
		(uuid "e9160eb4-0773-4ed3-9916-1ccb01e651ce")
	)
	(bus_entry
		(at 43.18 83.82)
		(size 2.54 -2.54)
		(stroke
			(width 0)
			(type default)
		)
		(uuid "0308461a-a8d1-4ca6-a90f-801926f9eac5")
	)
	(bus_entry
		(at 278.13 144.78)
		(size 2.54 2.54)
		(stroke
			(width 0)
			(type default)
		)
		(uuid "032caf92-86f3-4f86-831a-9791379a7d55")
	)
	(bus_entry
		(at 43.18 86.36)
		(size 2.54 -2.54)
		(stroke
			(width 0)
			(type default)
		)
		(uuid "0cd5f019-125a-44f2-85e2-8a391cde832d")
	)
	(bus_entry
		(at 43.18 135.89)
		(size 2.54 -2.54)
		(stroke
			(width 0)
			(type default)
		)
		(uuid "17bfa3a4-a42d-45b7-a561-63c5b3561277")
	)
	(bus_entry
		(at 43.18 50.8)
		(size 2.54 -2.54)
		(stroke
			(width 0)
			(type default)
		)
		(uuid "1dd98c5d-0c77-4918-9fba-c4de72c389c2")
	)
	(bus_entry
		(at 95.25 146.05)
		(size 2.54 -2.54)
		(stroke
			(width 0)
			(type default)
		)
		(uuid "1f6fccef-51f7-4b8e-80c0-da856cc8abea")
	)
	(bus_entry
		(at 278.13 142.24)
		(size 2.54 2.54)
		(stroke
			(width 0)
			(type default)
		)
		(uuid "20b40138-dbb0-4633-a4ad-fdf88838d36b")
	)
	(bus_entry
		(at 43.18 43.18)
		(size 2.54 -2.54)
		(stroke
			(width 0)
			(type default)
		)
		(uuid "21b3767f-0471-4be9-8a13-1c7f8b33b11e")
	)
	(bus_entry
		(at 43.18 93.98)
		(size 2.54 -2.54)
		(stroke
			(width 0)
			(type default)
		)
		(uuid "23582e9c-07aa-48f9-82e3-cb49f75a9967")
	)
	(bus_entry
		(at 95.25 143.51)
		(size 2.54 -2.54)
		(stroke
			(width 0)
			(type default)
		)
		(uuid "28a6c244-62e1-4c73-88dd-d3220d1dd01a")
	)
	(bus_entry
		(at 278.13 132.08)
		(size 2.54 2.54)
		(stroke
			(width 0)
			(type default)
		)
		(uuid "2aadc199-6c96-4f53-8015-2895e98fed5a")
	)
	(bus_entry
		(at 278.13 139.7)
		(size 2.54 2.54)
		(stroke
			(width 0)
			(type default)
		)
		(uuid "3561a1a4-99e3-41ab-ba05-09b6b71df06f")
	)
	(bus_entry
		(at 278.13 134.62)
		(size 2.54 2.54)
		(stroke
			(width 0)
			(type default)
		)
		(uuid "3ad276a4-77fe-4f18-9cb2-a3ef123f3a57")
	)
	(bus_entry
		(at 43.18 40.64)
		(size 2.54 -2.54)
		(stroke
			(width 0)
			(type default)
		)
		(uuid "3df19460-8af4-4d50-a8d1-04778eb1ec35")
	)
	(bus_entry
		(at 43.18 55.88)
		(size 2.54 -2.54)
		(stroke
			(width 0)
			(type default)
		)
		(uuid "530b5470-58b7-477d-abf4-f2944c153c2b")
	)
	(bus_entry
		(at 43.18 138.43)
		(size 2.54 -2.54)
		(stroke
			(width 0)
			(type default)
		)
		(uuid "59dc2357-0cbb-4354-9002-3652a5009554")
	)
	(bus_entry
		(at 43.18 91.44)
		(size 2.54 -2.54)
		(stroke
			(width 0)
			(type default)
		)
		(uuid "5a165757-5b78-4192-84e2-90f3711cb325")
	)
	(bus_entry
		(at 43.18 96.52)
		(size 2.54 -2.54)
		(stroke
			(width 0)
			(type default)
		)
		(uuid "66ab39a1-bca6-4b66-afb6-73d52ecd32c3")
	)
	(bus_entry
		(at 278.13 127)
		(size 2.54 2.54)
		(stroke
			(width 0)
			(type default)
		)
		(uuid "6b4c8dad-9a66-4b99-a625-309b811bbff9")
	)
	(bus_entry
		(at 43.18 130.81)
		(size 2.54 -2.54)
		(stroke
			(width 0)
			(type default)
		)
		(uuid "7430f341-66fc-4799-a96b-64a4ebfbff73")
	)
	(bus_entry
		(at 43.18 133.35)
		(size 2.54 -2.54)
		(stroke
			(width 0)
			(type default)
		)
		(uuid "7608d18b-702a-4308-ab96-9f7f54257645")
	)
	(bus_entry
		(at 95.25 140.97)
		(size 2.54 -2.54)
		(stroke
			(width 0)
			(type default)
		)
		(uuid "799dc4f8-738f-4fb3-b964-54aeb3ecd0a4")
	)
	(bus_entry
		(at 278.13 129.54)
		(size 2.54 2.54)
		(stroke
			(width 0)
			(type default)
		)
		(uuid "82406320-f173-4a4e-a021-ea48e5212b9f")
	)
	(bus_entry
		(at 43.18 88.9)
		(size 2.54 -2.54)
		(stroke
			(width 0)
			(type default)
		)
		(uuid "8c15b4df-f124-4fec-a0dc-585c5ebf6bd1")
	)
	(bus_entry
		(at 43.18 53.34)
		(size 2.54 -2.54)
		(stroke
			(width 0)
			(type default)
		)
		(uuid "8ec12675-ceca-40d3-b04c-dd1c07df9312")
	)
	(bus_entry
		(at 43.18 45.72)
		(size 2.54 -2.54)
		(stroke
			(width 0)
			(type default)
		)
		(uuid "97966dee-96dd-4ebf-bf21-4fcda8eaa184")
	)
	(bus_entry
		(at 43.18 140.97)
		(size 2.54 -2.54)
		(stroke
			(width 0)
			(type default)
		)
		(uuid "9ca12161-944e-4760-8f99-9d433b85a83d")
	)
	(bus_entry
		(at 43.18 148.59)
		(size 2.54 -2.54)
		(stroke
			(width 0)
			(type default)
		)
		(uuid "aacfef19-1d68-4abb-8d41-616bef7b30c9")
	)
	(bus_entry
		(at 43.18 58.42)
		(size 2.54 -2.54)
		(stroke
			(width 0)
			(type default)
		)
		(uuid "b2183a6c-fba5-46a3-9fb0-5531d6c13a18")
	)
	(bus_entry
		(at 43.18 143.51)
		(size 2.54 -2.54)
		(stroke
			(width 0)
			(type default)
		)
		(uuid "b69daff4-c9c1-4ca1-8694-9202a4033346")
	)
	(bus_entry
		(at 95.25 133.35)
		(size 2.54 -2.54)
		(stroke
			(width 0)
			(type default)
		)
		(uuid "b7099b10-c684-42b3-bd6a-15e93d7ffbcd")
	)
	(bus_entry
		(at 43.18 48.26)
		(size 2.54 -2.54)
		(stroke
			(width 0)
			(type default)
		)
		(uuid "b85a6d7b-a967-4480-a991-8bbd80847ee6")
	)
	(bus_entry
		(at 43.18 146.05)
		(size 2.54 -2.54)
		(stroke
			(width 0)
			(type default)
		)
		(uuid "c06371c3-d4d0-4c61-b129-e16b488c3a84")
	)
	(bus_entry
		(at 95.25 148.59)
		(size 2.54 -2.54)
		(stroke
			(width 0)
			(type default)
		)
		(uuid "c2c4b651-c742-470c-b202-6b3c8708f9a8")
	)
	(bus_entry
		(at 278.13 137.16)
		(size 2.54 2.54)
		(stroke
			(width 0)
			(type default)
		)
		(uuid "efd77788-dd81-48f1-997e-8b38e018673f")
	)
	(bus_entry
		(at 95.25 135.89)
		(size 2.54 -2.54)
		(stroke
			(width 0)
			(type default)
		)
		(uuid "f82e7253-4f42-410c-9a78-092a25fa38cf")
	)
	(bus_entry
		(at 95.25 130.81)
		(size 2.54 -2.54)
		(stroke
			(width 0)
			(type default)
		)
		(uuid "facbd3e6-6cce-422a-a251-dd7c17f1ee3e")
	)
	(bus_entry
		(at 95.25 138.43)
		(size 2.54 -2.54)
		(stroke
			(width 0)
			(type default)
		)
		(uuid "ff49949b-b972-4c00-9459-d0fca28f0fc3")
	)
	(wire
		(pts
			(xy 116.84 93.98) (xy 116.84 90.17)
		)
		(stroke
			(width 0)
			(type default)
		)
		(uuid "0156fcb5-f841-4c0e-95bb-98496f2ac04d")
	)
	(wire
		(pts
			(xy 72.39 133.35) (xy 71.12 133.35)
		)
		(stroke
			(width 0)
			(type default)
		)
		(uuid "036e8926-4153-4790-b86a-adb74a18c570")
	)
	(wire
		(pts
			(xy 45.72 55.88) (xy 50.8 55.88)
		)
		(stroke
			(width 0)
			(type default)
		)
		(uuid "0397d47f-131f-4f45-8289-a66fb76460a2")
	)
	(wire
		(pts
			(xy 45.72 83.82) (xy 50.8 83.82)
		)
		(stroke
			(width 0)
			(type default)
		)
		(uuid "057dfa82-8b73-4da9-9b49-9267acc29551")
	)
	(wire
		(pts
			(xy 72.39 140.97) (xy 72.39 133.35)
		)
		(stroke
			(width 0)
			(type default)
		)
		(uuid "05f1e845-1cf4-4f4a-aa9a-582314a78ad2")
	)
	(bus
		(pts
			(xy 43.18 133.35) (xy 43.18 135.89)
		)
		(stroke
			(width 0)
			(type default)
		)
		(uuid "08dc0c35-0a3f-4027-b9da-78578cf050fe")
	)
	(wire
		(pts
			(xy 97.79 138.43) (xy 102.87 138.43)
		)
		(stroke
			(width 0)
			(type default)
		)
		(uuid "08fc9a89-d66d-4dbf-b4b6-800fecd6d1a6")
	)
	(wire
		(pts
			(xy 248.92 90.17) (xy 248.92 127)
		)
		(stroke
			(width 0)
			(type default)
		)
		(uuid "096471f3-b2df-4881-9921-7c7b2223b520")
	)
	(bus
		(pts
			(xy 280.67 144.78) (xy 280.67 147.32)
		)
		(stroke
			(width 0)
			(type default)
		)
		(uuid "0a89ed8d-4f37-4bf4-b2ca-be686497c2a2")
	)
	(wire
		(pts
			(xy 238.76 139.7) (xy 248.92 139.7)
		)
		(stroke
			(width 0)
			(type default)
		)
		(uuid "0ac661ca-4836-446d-b8aa-70017556c87d")
	)
	(wire
		(pts
			(xy 73.66 55.88) (xy 76.2 55.88)
		)
		(stroke
			(width 0)
			(type default)
		)
		(uuid "0d772d2d-cae8-4091-b4b9-ccc8076194e0")
	)
	(wire
		(pts
			(xy 133.35 118.11) (xy 133.35 140.97)
		)
		(stroke
			(width 0)
			(type default)
		)
		(uuid "0e9d3663-76d2-4523-ad2e-ce5ba180e85b")
	)
	(wire
		(pts
			(xy 97.79 140.97) (xy 102.87 140.97)
		)
		(stroke
			(width 0)
			(type default)
		)
		(uuid "0f4f0f43-9721-4d8a-a70c-e0dfb87a1ab9")
	)
	(wire
		(pts
			(xy 45.72 135.89) (xy 50.8 135.89)
		)
		(stroke
			(width 0)
			(type default)
		)
		(uuid "115f650b-d804-4324-9416-49de9ff9f841")
	)
	(bus
		(pts
			(xy 43.18 88.9) (xy 43.18 91.44)
		)
		(stroke
			(width 0)
			(type default)
		)
		(uuid "119602b1-6605-45ec-995f-3498e32dd490")
	)
	(wire
		(pts
			(xy 229.87 125.73) (xy 238.76 125.73)
		)
		(stroke
			(width 0)
			(type default)
		)
		(uuid "15514cb1-e5bf-4de1-be93-d9aa3c7ae866")
	)
	(wire
		(pts
			(xy 63.5 38.1) (xy 63.5 30.48)
		)
		(stroke
			(width 0)
			(type default)
		)
		(uuid "15b7b110-d8f6-4430-ac63-c8f9a359bc6f")
	)
	(bus
		(pts
			(xy 95.25 130.81) (xy 95.25 133.35)
		)
		(stroke
			(width 0)
			(type default)
		)
		(uuid "163c6a07-71b1-421e-804d-345387efcf5b")
	)
	(wire
		(pts
			(xy 242.57 91.44) (xy 242.57 132.08)
		)
		(stroke
			(width 0)
			(type default)
		)
		(uuid "171d6e81-e86b-4863-bf52-b9bdf0fea639")
	)
	(wire
		(pts
			(xy 220.98 149.86) (xy 220.98 144.78)
		)
		(stroke
			(width 0)
			(type default)
		)
		(uuid "181244db-2716-4d05-a44c-6506f9d24dc4")
	)
	(wire
		(pts
			(xy 33.02 99.06) (xy 50.8 99.06)
		)
		(stroke
			(width 0)
			(type default)
		)
		(uuid "1a3f84f5-999d-431a-be5b-89d1e87af3f1")
	)
	(bus
		(pts
			(xy 43.18 91.44) (xy 43.18 93.98)
		)
		(stroke
			(width 0)
			(type default)
		)
		(uuid "1af5c951-463c-48f8-abdc-5c4c5fb08245")
	)
	(wire
		(pts
			(xy 71.12 135.89) (xy 76.2 135.89)
		)
		(stroke
			(width 0)
			(type default)
		)
		(uuid "1b37d3c4-ad06-41c4-9ab3-b6455f27c047")
	)
	(bus
		(pts
			(xy 43.18 55.88) (xy 43.18 58.42)
		)
		(stroke
			(width 0)
			(type default)
		)
		(uuid "1de5c909-2ccb-4249-81f8-16649161f2ed")
	)
	(wire
		(pts
			(xy 116.84 102.87) (xy 123.19 102.87)
		)
		(stroke
			(width 0)
			(type default)
		)
		(uuid "1e210d8b-bd24-4b76-a54e-b5ad49f3b5d3")
	)
	(wire
		(pts
			(xy 63.5 63.5) (xy 88.9 63.5)
		)
		(stroke
			(width 0)
			(type default)
		)
		(uuid "1f555533-858a-4ae4-846d-7605a2c6c4d3")
	)
	(wire
		(pts
			(xy 72.39 133.35) (xy 72.39 114.3)
		)
		(stroke
			(width 0)
			(type default)
		)
		(uuid "21582055-aca2-46db-94a0-cb08f9794c36")
	)
	(wire
		(pts
			(xy 161.29 97.79) (xy 161.29 96.52)
		)
		(stroke
			(width 0)
			(type default)
		)
		(uuid "22b56d87-05d8-4f8b-8023-535bbd3ac4a7")
	)
	(wire
		(pts
			(xy 76.2 123.19) (xy 60.96 123.19)
		)
		(stroke
			(width 0)
			(type default)
		)
		(uuid "2409fda4-fb71-465f-9939-379706be255b")
	)
	(wire
		(pts
			(xy 60.96 166.37) (xy 60.96 156.21)
		)
		(stroke
			(width 0)
			(type default)
		)
		(uuid "2438ad3c-3428-497c-b188-627e30f607b4")
	)
	(wire
		(pts
			(xy 142.24 81.28) (xy 76.2 81.28)
		)
		(stroke
			(width 0)
			(type default)
		)
		(uuid "26dd7b65-bb88-4572-9d23-3cccab9908ac")
	)
	(wire
		(pts
			(xy 163.83 100.33) (xy 163.83 125.73)
		)
		(stroke
			(width 0)
			(type default)
		)
		(uuid "27290514-ba0a-467e-a96a-94c1b97b0a7a")
	)
	(wire
		(pts
			(xy 142.24 81.28) (xy 142.24 102.87)
		)
		(stroke
			(width 0)
			(type default)
		)
		(uuid "276d44e6-fada-4777-9a0f-7c4063fcb5d9")
	)
	(wire
		(pts
			(xy 128.27 55.88) (xy 134.62 55.88)
		)
		(stroke
			(width 0)
			(type default)
		)
		(uuid "278e1b08-f99f-4d63-8376-0c04340698c4")
	)
	(wire
		(pts
			(xy 128.27 73.66) (xy 134.62 73.66)
		)
		(stroke
			(width 0)
			(type default)
		)
		(uuid "27a6f68d-fd25-4ffc-b204-0914ab72dc1e")
	)
	(bus
		(pts
			(xy 95.25 135.89) (xy 95.25 138.43)
		)
		(stroke
			(width 0)
			(type default)
		)
		(uuid "2909fe65-be91-447e-a2b3-be2ca5d48d00")
	)
	(wire
		(pts
			(xy 232.41 142.24) (xy 232.41 149.86)
		)
		(stroke
			(width 0)
			(type default)
		)
		(uuid "2b867749-7192-4af2-a097-9f0dd45a5357")
	)
	(wire
		(pts
			(xy 76.2 83.82) (xy 241.3 83.82)
		)
		(stroke
			(width 0)
			(type default)
		)
		(uuid "2e18ef90-1c28-49dc-b212-41e18a31eef3")
	)
	(wire
		(pts
			(xy 50.8 81.28) (xy 45.72 81.28)
		)
		(stroke
			(width 0)
			(type default)
		)
		(uuid "2e6ee2e6-d77f-4fc3-a55b-1c430d0e3fc2")
	)
	(wire
		(pts
			(xy 45.72 146.05) (xy 50.8 146.05)
		)
		(stroke
			(width 0)
			(type default)
		)
		(uuid "2e739716-790e-4032-b23e-0aa8e664b7ac")
	)
	(wire
		(pts
			(xy 241.3 83.82) (xy 241.3 134.62)
		)
		(stroke
			(width 0)
			(type default)
		)
		(uuid "2ea9ff6a-f94a-4d4d-b004-c4a250dddcaa")
	)
	(wire
		(pts
			(xy 101.6 121.92) (xy 92.71 121.92)
		)
		(stroke
			(width 0)
			(type default)
		)
		(uuid "2f45079e-35ad-482f-8547-b5a564087b2b")
	)
	(wire
		(pts
			(xy 92.71 156.21) (xy 92.71 173.99)
		)
		(stroke
			(width 0)
			(type default)
		)
		(uuid "30f551b1-ecb8-417f-b577-6150e173b1b7")
	)
	(bus
		(pts
			(xy 43.18 146.05) (xy 43.18 148.59)
		)
		(stroke
			(width 0)
			(type default)
		)
		(uuid "30f630a1-9ac2-447b-bd52-95ec5c88a89a")
	)
	(bus
		(pts
			(xy 43.18 43.18) (xy 43.18 45.72)
		)
		(stroke
			(width 0)
			(type default)
		)
		(uuid "319c1f0b-f2c5-474b-89b0-6d31f4eb069b")
	)
	(wire
		(pts
			(xy 143.51 97.79) (xy 148.59 97.79)
		)
		(stroke
			(width 0)
			(type default)
		)
		(uuid "33fc2aaf-d77f-4915-b579-3da3d34f65c1")
	)
	(wire
		(pts
			(xy 45.72 93.98) (xy 50.8 93.98)
		)
		(stroke
			(width 0)
			(type default)
		)
		(uuid "357b0029-a382-4dbc-a9af-205d11e8bcf6")
	)
	(wire
		(pts
			(xy 229.87 125.73) (xy 229.87 86.36)
		)
		(stroke
			(width 0)
			(type default)
		)
		(uuid "35da7871-8683-405f-a611-9ec200bce444")
	)
	(wire
		(pts
			(xy 116.84 93.98) (xy 116.84 102.87)
		)
		(stroke
			(width 0)
			(type default)
		)
		(uuid "365d0bfa-41cf-4a1a-8c0d-0f7ec52c20c9")
	)
	(wire
		(pts
			(xy 101.6 66.04) (xy 101.6 121.92)
		)
		(stroke
			(width 0)
			(type default)
		)
		(uuid "3951c58a-e4bf-4e47-a9e7-1ec0018833d3")
	)
	(wire
		(pts
			(xy 161.29 102.87) (xy 161.29 104.14)
		)
		(stroke
			(width 0)
			(type default)
		)
		(uuid "3bc5a0df-7184-414b-8a69-45a90406eaa3")
	)
	(wire
		(pts
			(xy 157.48 45.72) (xy 157.48 58.42)
		)
		(stroke
			(width 0)
			(type default)
		)
		(uuid "3c0c8660-1485-4989-9b72-07c41d50430f")
	)
	(wire
		(pts
			(xy 106.68 50.8) (xy 101.6 50.8)
		)
		(stroke
			(width 0)
			(type default)
		)
		(uuid "3c632dcb-64ad-4321-83a8-566d3a0894a8")
	)
	(wire
		(pts
			(xy 63.5 40.64) (xy 76.2 40.64)
		)
		(stroke
			(width 0)
			(type default)
		)
		(uuid "3efc7140-9d9d-4fda-8973-79c2dcd87031")
	)
	(wire
		(pts
			(xy 45.72 86.36) (xy 50.8 86.36)
		)
		(stroke
			(width 0)
			(type default)
		)
		(uuid "40364525-aba8-404c-9f32-a1c06a51186d")
	)
	(wire
		(pts
			(xy 144.78 78.74) (xy 172.72 78.74)
		)
		(stroke
			(width 0)
			(type default)
		)
		(uuid "404bc486-20b9-4ac9-908b-0a7538e86c69")
	)
	(wire
		(pts
			(xy 115.57 166.37) (xy 133.35 166.37)
		)
		(stroke
			(width 0)
			(type default)
		)
		(uuid "409a3316-6a6d-4c73-9fa6-ed62ebe12f08")
	)
	(bus
		(pts
			(xy 280.67 142.24) (xy 280.67 144.78)
		)
		(stroke
			(width 0)
			(type default)
		)
		(uuid "43acecf3-3759-43e2-95ed-8b0fb1f0e3b2")
	)
	(wire
		(pts
			(xy 135.89 97.79) (xy 135.89 96.52)
		)
		(stroke
			(width 0)
			(type default)
		)
		(uuid "43b226fa-2266-48e2-a7d7-424384a291b8")
	)
	(wire
		(pts
			(xy 50.8 38.1) (xy 45.72 38.1)
		)
		(stroke
			(width 0)
			(type default)
		)
		(uuid "43cf4f0b-bf09-4d2e-9b23-e47eafff7f52")
	)
	(wire
		(pts
			(xy 50.8 128.27) (xy 45.72 128.27)
		)
		(stroke
			(width 0)
			(type default)
		)
		(uuid "45039b54-1292-4bc9-b56b-b9fe4d70d16e")
	)
	(wire
		(pts
			(xy 278.13 139.7) (xy 274.32 139.7)
		)
		(stroke
			(width 0)
			(type default)
		)
		(uuid "46ef70fd-44c8-42e7-87ae-f4b42c32ce12")
	)
	(wire
		(pts
			(xy 71.12 128.27) (xy 78.74 128.27)
		)
		(stroke
			(width 0)
			(type default)
		)
		(uuid "47050f0b-14a4-4db9-81ad-3f22882b4371")
	)
	(wire
		(pts
			(xy 241.3 134.62) (xy 248.92 134.62)
		)
		(stroke
			(width 0)
			(type default)
		)
		(uuid "48809729-af64-48d0-a2f8-171b8dc4cf0b")
	)
	(wire
		(pts
			(xy 45.72 138.43) (xy 50.8 138.43)
		)
		(stroke
			(width 0)
			(type default)
		)
		(uuid "48991d6e-e67b-469c-ad87-22076d708732")
	)
	(wire
		(pts
			(xy 106.68 113.03) (xy 106.68 50.8)
		)
		(stroke
			(width 0)
			(type default)
		)
		(uuid "491c360e-4b4d-4109-8c51-b42426ba1a6c")
	)
	(wire
		(pts
			(xy 33.02 68.58) (xy 33.02 99.06)
		)
		(stroke
			(width 0)
			(type default)
		)
		(uuid "4a223cbf-f240-4211-8e06-68c8a29d33fd")
	)
	(wire
		(pts
			(xy 142.24 102.87) (xy 148.59 102.87)
		)
		(stroke
			(width 0)
			(type default)
		)
		(uuid "4a618c11-0fbd-4ed9-b9ce-633151e20fc4")
	)
	(wire
		(pts
			(xy 115.57 118.11) (xy 133.35 118.11)
		)
		(stroke
			(width 0)
			(type default)
		)
		(uuid "4a8fbe0a-a9dc-45a4-8e78-d928a4dcab46")
	)
	(wire
		(pts
			(xy 76.2 45.72) (xy 76.2 50.8)
		)
		(stroke
			(width 0)
			(type default)
		)
		(uuid "4ac3129b-d056-40e7-b81b-481ece0bf85e")
	)
	(bus
		(pts
			(xy 43.18 83.82) (xy 43.18 86.36)
		)
		(stroke
			(width 0)
			(type default)
		)
		(uuid "4f3575ff-1ef2-4152-b61b-4247d77d3572")
	)
	(wire
		(pts
			(xy 92.71 156.21) (xy 102.87 156.21)
		)
		(stroke
			(width 0)
			(type default)
		)
		(uuid "53d0c4b5-945d-4097-9b0f-a39778eb3af2")
	)
	(wire
		(pts
			(xy 76.2 88.9) (xy 232.41 88.9)
		)
		(stroke
			(width 0)
			(type default)
		)
		(uuid "547332d0-f31e-473f-a15c-67c1f68d6927")
	)
	(wire
		(pts
			(xy 97.79 133.35) (xy 102.87 133.35)
		)
		(stroke
			(width 0)
			(type default)
		)
		(uuid "54c151de-48d5-43fa-8bea-e18439040c29")
	)
	(wire
		(pts
			(xy 105.41 53.34) (xy 105.41 68.58)
		)
		(stroke
			(width 0)
			(type default)
		)
		(uuid "560c93c0-6600-4f0b-bbcb-916d236cce81")
	)
	(bus
		(pts
			(xy 95.25 138.43) (xy 95.25 140.97)
		)
		(stroke
			(width 0)
			(type default)
		)
		(uuid "56e8bbe1-ae1f-42c6-be05-1a65d0021289")
	)
	(wire
		(pts
			(xy 76.2 123.19) (xy 102.87 123.19)
		)
		(stroke
			(width 0)
			(type default)
		)
		(uuid "573faf64-964f-4a20-b492-a10d07bbd3f7")
	)
	(wire
		(pts
			(xy 63.5 45.72) (xy 76.2 45.72)
		)
		(stroke
			(width 0)
			(type default)
		)
		(uuid "5794f083-7771-46b6-b573-015e4c227940")
	)
	(bus
		(pts
			(xy 95.25 140.97) (xy 95.25 143.51)
		)
		(stroke
			(width 0)
			(type default)
		)
		(uuid "57f4b08b-321a-4487-933d-e9b72f162f79")
	)
	(wire
		(pts
			(xy 63.5 55.88) (xy 63.5 63.5)
		)
		(stroke
			(width 0)
			(type default)
		)
		(uuid "58150d9a-d5ea-41b9-a844-5d3a70c1fc4b")
	)
	(wire
		(pts
			(xy 232.41 142.24) (xy 232.41 134.62)
		)
		(stroke
			(width 0)
			(type default)
		)
		(uuid "58980733-6151-4312-913f-97fa0c7e01ea")
	)
	(wire
		(pts
			(xy 45.72 91.44) (xy 50.8 91.44)
		)
		(stroke
			(width 0)
			(type default)
		)
		(uuid "58ca9ba4-181f-4f4d-a82a-b496fdb8337e")
	)
	(wire
		(pts
			(xy 45.72 45.72) (xy 50.8 45.72)
		)
		(stroke
			(width 0)
			(type default)
		)
		(uuid "5b8659c4-e75e-4b71-9110-75b7b1103f6c")
	)
	(wire
		(pts
			(xy 101.6 48.26) (xy 107.95 48.26)
		)
		(stroke
			(width 0)
			(type default)
		)
		(uuid "5bb4278c-5c72-400a-bc16-da30c4febd07")
	)
	(wire
		(pts
			(xy 97.79 143.51) (xy 102.87 143.51)
		)
		(stroke
			(width 0)
			(type default)
		)
		(uuid "5dcf3ab3-55d6-4daf-b61b-3403ad7dda9d")
	)
	(wire
		(pts
			(xy 278.13 144.78) (xy 274.32 144.78)
		)
		(stroke
			(width 0)
			(type default)
		)
		(uuid "5fef93f3-af40-4a21-a5c5-be79cc90f7dd")
	)
	(wire
		(pts
			(xy 187.96 53.34) (xy 180.34 53.34)
		)
		(stroke
			(width 0)
			(type default)
		)
		(uuid "61e176cd-bc99-4624-b1b2-ed394b5f70e1")
	)
	(wire
		(pts
			(xy 118.11 97.79) (xy 118.11 110.49)
		)
		(stroke
			(width 0)
			(type default)
		)
		(uuid "62638386-401c-4e5d-9f2d-bbe4d8a13128")
	)
	(wire
		(pts
			(xy 232.41 134.62) (xy 228.6 134.62)
		)
		(stroke
			(width 0)
			(type default)
		)
		(uuid "64964a59-773d-4eae-8b11-641a5c2ba716")
	)
	(wire
		(pts
			(xy 63.5 48.26) (xy 74.93 48.26)
		)
		(stroke
			(width 0)
			(type default)
		)
		(uuid "65e1d482-521f-45a6-b98f-f52e77a66b7a")
	)
	(wire
		(pts
			(xy 278.13 142.24) (xy 274.32 142.24)
		)
		(stroke
			(width 0)
			(type default)
		)
		(uuid "667d99d7-f539-4aa7-9f39-55741a116233")
	)
	(wire
		(pts
			(xy 101.6 66.04) (xy 120.65 66.04)
		)
		(stroke
			(width 0)
			(type default)
		)
		(uuid "67454e33-107a-427f-b500-6349800c511f")
	)
	(bus
		(pts
			(xy 280.67 132.08) (xy 280.67 134.62)
		)
		(stroke
			(width 0)
			(type default)
		)
		(uuid "684bea32-321d-4415-9c59-73c82908918b")
	)
	(wire
		(pts
			(xy 161.29 100.33) (xy 163.83 100.33)
		)
		(stroke
			(width 0)
			(type default)
		)
		(uuid "68c8c73f-a35a-4b37-89a0-3689b93aa092")
	)
	(wire
		(pts
			(xy 138.43 100.33) (xy 138.43 125.73)
		)
		(stroke
			(width 0)
			(type default)
		)
		(uuid "6a52e715-396c-4eda-8bde-182d3d09be31")
	)
	(wire
		(pts
			(xy 229.87 144.78) (xy 229.87 149.86)
		)
		(stroke
			(width 0)
			(type default)
		)
		(uuid "6efef8df-5a04-419d-82ee-aea611a1be74")
	)
	(wire
		(pts
			(xy 78.74 128.27) (xy 78.74 110.49)
		)
		(stroke
			(width 0)
			(type default)
		)
		(uuid "704b4cc1-016f-4780-8e91-66819110ab19")
	)
	(bus
		(pts
			(xy 280.67 137.16) (xy 280.67 139.7)
		)
		(stroke
			(width 0)
			(type default)
		)
		(uuid "73f603ed-8214-4400-85f8-4d2dad5b0f85")
	)
	(wire
		(pts
			(xy 101.6 55.88) (xy 101.6 66.04)
		)
		(stroke
			(width 0)
			(type default)
		)
		(uuid "742a5090-1c25-42d7-b3fb-7dab975a1d28")
	)
	(wire
		(pts
			(xy 45.72 133.35) (xy 50.8 133.35)
		)
		(stroke
			(width 0)
			(type default)
		)
		(uuid "747f8b41-32d8-4fc8-8c55-4e2a8ac33bd7")
	)
	(wire
		(pts
			(xy 76.2 91.44) (xy 242.57 91.44)
		)
		(stroke
			(width 0)
			(type default)
		)
		(uuid "74d65ef9-0e0a-4b3c-a169-79ba694a10b4")
	)
	(wire
		(pts
			(xy 76.2 135.89) (xy 76.2 123.19)
		)
		(stroke
			(width 0)
			(type default)
		)
		(uuid "74e72878-3276-46d9-9276-99e4ac7ae82c")
	)
	(wire
		(pts
			(xy 102.87 118.11) (xy 115.57 118.11)
		)
		(stroke
			(width 0)
			(type default)
		)
		(uuid "76ea4c2d-99f3-4c9c-8dbf-cbe817ab6a26")
	)
	(wire
		(pts
			(xy 92.71 121.92) (xy 92.71 156.21)
		)
		(stroke
			(width 0)
			(type default)
		)
		(uuid "76f40472-226b-41d7-902e-da01c6ac3abf")
	)
	(wire
		(pts
			(xy 119.38 100.33) (xy 119.38 78.74)
		)
		(stroke
			(width 0)
			(type default)
		)
		(uuid "774eed9b-a99b-4e45-977a-83d207a30a1c")
	)
	(bus
		(pts
			(xy 43.18 135.89) (xy 43.18 138.43)
		)
		(stroke
			(width 0)
			(type default)
		)
		(uuid "7888a7e2-a920-4161-a1fe-18deb41d5307")
	)
	(wire
		(pts
			(xy 128.27 66.04) (xy 134.62 66.04)
		)
		(stroke
			(width 0)
			(type default)
		)
		(uuid "78d8cda3-8110-45a7-82f2-6a2d89aa3f50")
	)
	(wire
		(pts
			(xy 143.51 97.79) (xy 143.51 110.49)
		)
		(stroke
			(width 0)
			(type default)
		)
		(uuid "7b7c5960-d0e5-4d10-82c6-7dbd721a8f10")
	)
	(wire
		(pts
			(xy 156.21 149.86) (xy 156.21 140.97)
		)
		(stroke
			(width 0)
			(type default)
		)
		(uuid "7f79d6d5-a3f9-4fd8-963c-abbb3a478adc")
	)
	(wire
		(pts
			(xy 118.11 97.79) (xy 123.19 97.79)
		)
		(stroke
			(width 0)
			(type default)
		)
		(uuid "8217064a-22b9-497f-9f75-45e7b32e51a0")
	)
	(bus
		(pts
			(xy 95.25 172.72) (xy 280.67 172.72)
		)
		(stroke
			(width 0)
			(type default)
		)
		(uuid "8272be42-083f-4ef1-b0ef-9bf6bfc2f475")
	)
	(wire
		(pts
			(xy 45.72 53.34) (xy 50.8 53.34)
		)
		(stroke
			(width 0)
			(type default)
		)
		(uuid "82d22b6d-35da-40d0-8ac0-2ef82a52e909")
	)
	(wire
		(pts
			(xy 73.66 53.34) (xy 73.66 55.88)
		)
		(stroke
			(width 0)
			(type default)
		)
		(uuid "836630d2-a608-41cd-8d0e-54e515acb455")
	)
	(wire
		(pts
			(xy 138.43 125.73) (xy 163.83 125.73)
		)
		(stroke
			(width 0)
			(type default)
		)
		(uuid "83fa5bc3-52c8-4cee-80fa-1dfc7be8398a")
	)
	(bus
		(pts
			(xy 43.18 86.36) (xy 43.18 88.9)
		)
		(stroke
			(width 0)
			(type default)
		)
		(uuid "84aa2c29-2b84-4692-bcbd-653ec1cac57d")
	)
	(wire
		(pts
			(xy 71.12 140.97) (xy 72.39 140.97)
		)
		(stroke
			(width 0)
			(type default)
		)
		(uuid "84abd6cf-695b-4b8f-86c1-bd50e4edf6bc")
	)
	(wire
		(pts
			(xy 201.93 48.26) (xy 201.93 53.34)
		)
		(stroke
			(width 0)
			(type default)
		)
		(uuid "8839a0e7-c026-4b71-86b2-97b589c27d60")
	)
	(wire
		(pts
			(xy 63.5 50.8) (xy 73.66 50.8)
		)
		(stroke
			(width 0)
			(type default)
		)
		(uuid "8de24d4d-82bf-4ee1-92a5-866008e971db")
	)
	(wire
		(pts
			(xy 102.87 166.37) (xy 60.96 166.37)
		)
		(stroke
			(width 0)
			(type default)
		)
		(uuid "8e02350a-a31e-4e8d-87d4-d52cfcd12741")
	)
	(wire
		(pts
			(xy 195.58 60.96) (xy 201.93 60.96)
		)
		(stroke
			(width 0)
			(type default)
		)
		(uuid "8e220aa6-d509-494b-9d97-79919230963a")
	)
	(bus
		(pts
			(xy 280.67 139.7) (xy 280.67 142.24)
		)
		(stroke
			(width 0)
			(type default)
		)
		(uuid "8ecf851e-a598-43d6-8297-7f9a9a24341d")
	)
	(bus
		(pts
			(xy 95.25 158.75) (xy 95.25 172.72)
		)
		(stroke
			(width 0)
			(type default)
		)
		(uuid "8f346e81-5983-4c20-8d6f-ac62ac490d49")
	)
	(wire
		(pts
			(xy 128.27 48.26) (xy 134.62 48.26)
		)
		(stroke
			(width 0)
			(type default)
		)
		(uuid "9062be67-88e8-4cd5-b8a5-6d5341fb16e8")
	)
	(wire
		(pts
			(xy 63.5 43.18) (xy 76.2 43.18)
		)
		(stroke
			(width 0)
			(type default)
		)
		(uuid "92911da2-c37c-4092-8471-9a4326609ad6")
	)
	(wire
		(pts
			(xy 107.95 48.26) (xy 120.65 48.26)
		)
		(stroke
			(width 0)
			(type default)
		)
		(uuid "9564989d-ea17-41bc-ae70-3fb758c27393")
	)
	(wire
		(pts
			(xy 156.21 157.48) (xy 156.21 166.37)
		)
		(stroke
			(width 0)
			(type default)
		)
		(uuid "95d6d311-5498-47cf-96ee-97036bb0ba56")
	)
	(bus
		(pts
			(xy 43.18 48.26) (xy 43.18 50.8)
		)
		(stroke
			(width 0)
			(type default)
		)
		(uuid "9623a3ab-d042-45fd-8b50-6cd678d1abda")
	)
	(wire
		(pts
			(xy 45.72 130.81) (xy 50.8 130.81)
		)
		(stroke
			(width 0)
			(type default)
		)
		(uuid "96636d42-04ad-48eb-88ff-c54008eeaf8f")
	)
	(wire
		(pts
			(xy 81.28 113.03) (xy 106.68 113.03)
		)
		(stroke
			(width 0)
			(type default)
		)
		(uuid "973b68fa-ce82-4dba-8819-7beb0a4faef0")
	)
	(wire
		(pts
			(xy 102.87 158.75) (xy 102.87 166.37)
		)
		(stroke
			(width 0)
			(type default)
		)
		(uuid "98a73a6c-f8e9-4327-ba53-1afd166f7a88")
	)
	(bus
		(pts
			(xy 280.67 147.32) (xy 280.67 172.72)
		)
		(stroke
			(width 0)
			(type default)
		)
		(uuid "9b4a5222-0ba3-4916-a0a4-c676a982ac00")
	)
	(wire
		(pts
			(xy 156.21 140.97) (xy 133.35 140.97)
		)
		(stroke
			(width 0)
			(type default)
		)
		(uuid "9ccc1f08-1c9f-4052-88a8-241c1c3e5d69")
	)
	(wire
		(pts
			(xy 45.72 50.8) (xy 50.8 50.8)
		)
		(stroke
			(width 0)
			(type default)
		)
		(uuid "9e201b54-f403-4ac7-970e-3451c766b2c1")
	)
	(wire
		(pts
			(xy 71.12 143.51) (xy 81.28 143.51)
		)
		(stroke
			(width 0)
			(type default)
		)
		(uuid "a1d34b8d-07ed-46a7-9771-4777a4dc0a3a")
	)
	(wire
		(pts
			(xy 135.89 100.33) (xy 138.43 100.33)
		)
		(stroke
			(width 0)
			(type default)
		)
		(uuid "a20830ee-6245-40e9-85cf-a73696cab1cb")
	)
	(wire
		(pts
			(xy 278.13 129.54) (xy 274.32 129.54)
		)
		(stroke
			(width 0)
			(type default)
		)
		(uuid "a38dc367-865f-4670-a229-c878f0f0a1fc")
	)
	(wire
		(pts
			(xy 63.5 30.48) (xy 88.9 30.48)
		)
		(stroke
			(width 0)
			(type default)
		)
		(uuid "a46fe448-1ff4-4d6a-8334-b987c328606d")
	)
	(wire
		(pts
			(xy 195.58 53.34) (xy 201.93 53.34)
		)
		(stroke
			(width 0)
			(type default)
		)
		(uuid "a69a0627-b384-4bef-9271-d7394f4fa3fd")
	)
	(wire
		(pts
			(xy 102.87 128.27) (xy 97.79 128.27)
		)
		(stroke
			(width 0)
			(type default)
		)
		(uuid "a85ee920-881d-494e-b813-0c30c7d9a0cf")
	)
	(wire
		(pts
			(xy 72.39 114.3) (xy 217.17 114.3)
		)
		(stroke
			(width 0)
			(type default)
		)
		(uuid "a8dc49fd-20ec-47ee-95fd-ea1b5885d2db")
	)
	(wire
		(pts
			(xy 45.72 48.26) (xy 50.8 48.26)
		)
		(stroke
			(width 0)
			(type default)
		)
		(uuid "aa0b75c7-f46d-4ab7-9002-e5648cb82fab")
	)
	(wire
		(pts
			(xy 116.84 90.17) (xy 248.92 90.17)
		)
		(stroke
			(width 0)
			(type default)
		)
		(uuid "acd2f12b-2ed7-4a36-b038-20341ae25e94")
	)
	(bus
		(pts
			(xy 43.18 93.98) (xy 43.18 96.52)
		)
		(stroke
			(width 0)
			(type default)
		)
		(uuid "ad3e4916-8328-4f7c-9665-d1be859ccb18")
	)
	(wire
		(pts
			(xy 240.03 124.46) (xy 232.41 124.46)
		)
		(stroke
			(width 0)
			(type default)
		)
		(uuid "aeda0d50-5a41-43b6-8a40-1a2d830fd616")
	)
	(wire
		(pts
			(xy 97.79 130.81) (xy 102.87 130.81)
		)
		(stroke
			(width 0)
			(type default)
		)
		(uuid "af11131f-3c97-49b2-a22f-b79aba84ef15")
	)
	(wire
		(pts
			(xy 73.66 38.1) (xy 76.2 38.1)
		)
		(stroke
			(width 0)
			(type default)
		)
		(uuid "b16de62a-b2dd-40b7-b3a1-7441b1c9d7cb")
	)
	(wire
		(pts
			(xy 107.95 116.84) (xy 83.82 116.84)
		)
		(stroke
			(width 0)
			(type default)
		)
		(uuid "b4294aad-475a-49b5-8420-3721eba7e870")
	)
	(bus
		(pts
			(xy 43.18 138.43) (xy 43.18 140.97)
		)
		(stroke
			(width 0)
			(type default)
		)
		(uuid "b486bff2-33df-46e2-8b05-a1fceef25737")
	)
	(wire
		(pts
			(xy 144.78 100.33) (xy 144.78 78.74)
		)
		(stroke
			(width 0)
			(type default)
		)
		(uuid "b5a0fec5-b915-49ef-9064-f022add275d7")
	)
	(wire
		(pts
			(xy 142.24 81.28) (xy 243.84 81.28)
		)
		(stroke
			(width 0)
			(type default)
		)
		(uuid "b5b77bf1-d69e-486d-aab4-2c1be8e4dfa8")
	)
	(wire
		(pts
			(xy 102.87 123.19) (xy 102.87 118.11)
		)
		(stroke
			(width 0)
			(type default)
		)
		(uuid "b666e029-2bbd-4af7-8636-d67e1d793467")
	)
	(wire
		(pts
			(xy 92.71 173.99) (xy 248.92 173.99)
		)
		(stroke
			(width 0)
			(type default)
		)
		(uuid "b6d6356a-ca26-4f30-a866-7d8f1d62e339")
	)
	(wire
		(pts
			(xy 242.57 132.08) (xy 248.92 132.08)
		)
		(stroke
			(width 0)
			(type default)
		)
		(uuid "b788f589-9858-41a3-85b4-5851ec35d758")
	)
	(wire
		(pts
			(xy 232.41 88.9) (xy 232.41 124.46)
		)
		(stroke
			(width 0)
			(type default)
		)
		(uuid "b7b6dcfe-bb9d-4c07-a2a4-0fe25de48fc1")
	)
	(wire
		(pts
			(xy 134.62 43.18) (xy 134.62 48.26)
		)
		(stroke
			(width 0)
			(type default)
		)
		(uuid "b992aed8-ad1e-4b0a-8e9a-5f5a2b7b9fbf")
	)
	(wire
		(pts
			(xy 248.92 142.24) (xy 232.41 142.24)
		)
		(stroke
			(width 0)
			(type default)
		)
		(uuid "b9b5e66d-6c7f-402c-bf1a-5ef58e5b7dd5")
	)
	(bus
		(pts
			(xy 280.67 134.62) (xy 280.67 137.16)
		)
		(stroke
			(width 0)
			(type default)
		)
		(uuid "bb27fd63-d52c-46e7-b7cf-acd5b73c916d")
	)
	(bus
		(pts
			(xy 280.67 129.54) (xy 280.67 132.08)
		)
		(stroke
			(width 0)
			(type default)
		)
		(uuid "bb3042ec-ac04-4681-af8d-5a7ec8338eb3")
	)
	(bus
		(pts
			(xy 95.25 143.51) (xy 95.25 146.05)
		)
		(stroke
			(width 0)
			(type default)
		)
		(uuid "bc1a8bdd-c4c6-486b-8ea7-ed3e84b8eb88")
	)
	(bus
		(pts
			(xy 43.18 158.75) (xy 95.25 158.75)
		)
		(stroke
			(width 0)
			(type default)
		)
		(uuid "bcc12967-22f5-4cea-ac26-6f2b7c210293")
	)
	(wire
		(pts
			(xy 217.17 114.3) (xy 217.17 50.8)
		)
		(stroke
			(width 0)
			(type default)
		)
		(uuid "be841892-86cd-4bdb-a4c1-d3910a282b75")
	)
	(wire
		(pts
			(xy 228.6 144.78) (xy 229.87 144.78)
		)
		(stroke
			(width 0)
			(type default)
		)
		(uuid "beb97d8e-bd82-4260-a780-476b19dee33f")
	)
	(wire
		(pts
			(xy 248.92 152.4) (xy 248.92 173.99)
		)
		(stroke
			(width 0)
			(type default)
		)
		(uuid "bebdcdbc-af11-496f-9b93-406c58763367")
	)
	(wire
		(pts
			(xy 45.72 88.9) (xy 50.8 88.9)
		)
		(stroke
			(width 0)
			(type default)
		)
		(uuid "bee111b0-a07d-4c40-91ae-cd41ba2b3fe7")
	)
	(wire
		(pts
			(xy 45.72 40.64) (xy 50.8 40.64)
		)
		(stroke
			(width 0)
			(type default)
		)
		(uuid "bf8eee6d-ed49-4f94-a5ba-096597242cf6")
	)
	(wire
		(pts
			(xy 74.93 53.34) (xy 76.2 53.34)
		)
		(stroke
			(width 0)
			(type default)
		)
		(uuid "c0043049-6e51-42cf-916c-d72a759c011f")
	)
	(bus
		(pts
			(xy 43.18 40.64) (xy 43.18 43.18)
		)
		(stroke
			(width 0)
			(type default)
		)
		(uuid "c04d85ba-8be1-42ac-8d39-94fec731fad9")
	)
	(wire
		(pts
			(xy 240.03 137.16) (xy 240.03 124.46)
		)
		(stroke
			(width 0)
			(type default)
		)
		(uuid "c0b1b04e-bd7c-4b9e-84d7-324cbe66b66a")
	)
	(wire
		(pts
			(xy 128.27 125.73) (xy 138.43 125.73)
		)
		(stroke
			(width 0)
			(type default)
		)
		(uuid "c17178ef-4c51-489e-ab00-84b67e00c73a")
	)
	(wire
		(pts
			(xy 274.32 127) (xy 278.13 127)
		)
		(stroke
			(width 0)
			(type default)
		)
		(uuid "c238d5bf-4f2b-468f-9db5-298565cbd64e")
	)
	(wire
		(pts
			(xy 243.84 129.54) (xy 248.92 129.54)
		)
		(stroke
			(width 0)
			(type default)
		)
		(uuid "c298d655-2844-4d90-b435-98f16ce524e9")
	)
	(bus
		(pts
			(xy 43.18 50.8) (xy 43.18 53.34)
		)
		(stroke
			(width 0)
			(type default)
		)
		(uuid "c2e6cc4f-d704-49f2-a0c8-8f6d93d28314")
	)
	(wire
		(pts
			(xy 149.86 45.72) (xy 157.48 45.72)
		)
		(stroke
			(width 0)
			(type default)
		)
		(uuid "c377b34a-98a9-468f-959c-ef8de733df89")
	)
	(wire
		(pts
			(xy 78.74 110.49) (xy 118.11 110.49)
		)
		(stroke
			(width 0)
			(type default)
		)
		(uuid "c423b5d0-28dd-4b81-9b6b-720012f80184")
	)
	(wire
		(pts
			(xy 73.66 50.8) (xy 73.66 38.1)
		)
		(stroke
			(width 0)
			(type default)
		)
		(uuid "c467940a-a965-4e0f-8b80-90096d912bf4")
	)
	(wire
		(pts
			(xy 278.13 134.62) (xy 274.32 134.62)
		)
		(stroke
			(width 0)
			(type default)
		)
		(uuid "c63a7dd3-99b5-439e-859f-0c844fe7cd35")
	)
	(bus
		(pts
			(xy 95.25 133.35) (xy 95.25 135.89)
		)
		(stroke
			(width 0)
			(type default)
		)
		(uuid "c65e6da5-f2c2-4b1f-b8b9-48ab188e164e")
	)
	(wire
		(pts
			(xy 224.79 149.86) (xy 220.98 149.86)
		)
		(stroke
			(width 0)
			(type default)
		)
		(uuid "c6bceb03-e7bc-4239-a7dd-01b823d60efc")
	)
	(bus
		(pts
			(xy 95.25 146.05) (xy 95.25 148.59)
		)
		(stroke
			(width 0)
			(type default)
		)
		(uuid "c8333f36-e925-4ee3-961e-a9a13fe60360")
	)
	(bus
		(pts
			(xy 43.18 148.59) (xy 43.18 158.75)
		)
		(stroke
			(width 0)
			(type default)
		)
		(uuid "c91395a5-c9c6-4978-ab5e-c610fc7db85c")
	)
	(wire
		(pts
			(xy 116.84 93.98) (xy 76.2 93.98)
		)
		(stroke
			(width 0)
			(type default)
		)
		(uuid "cc8a0286-8594-45ba-8597-ed437acfe51b")
	)
	(wire
		(pts
			(xy 278.13 132.08) (xy 274.32 132.08)
		)
		(stroke
			(width 0)
			(type default)
		)
		(uuid "cc8c1726-4c6b-4185-89a4-b171419ec4be")
	)
	(bus
		(pts
			(xy 43.18 143.51) (xy 43.18 146.05)
		)
		(stroke
			(width 0)
			(type default)
		)
		(uuid "cce452f4-d83e-4439-aa9c-77d9fb645e03")
	)
	(wire
		(pts
			(xy 172.72 60.96) (xy 172.72 78.74)
		)
		(stroke
			(width 0)
			(type default)
		)
		(uuid "ce065ecb-6ed6-4f1d-a67b-a12f61dc6265")
	)
	(bus
		(pts
			(xy 95.25 148.59) (xy 95.25 158.75)
		)
		(stroke
			(width 0)
			(type default)
		)
		(uuid "ce0f2116-8579-4452-a62a-9decb765a5dd")
	)
	(wire
		(pts
			(xy 232.41 124.46) (xy 232.41 127)
		)
		(stroke
			(width 0)
			(type default)
		)
		(uuid "cfc574dc-a4cb-4db7-bed2-bb4a6edae850")
	)
	(wire
		(pts
			(xy 101.6 53.34) (xy 105.41 53.34)
		)
		(stroke
			(width 0)
			(type default)
		)
		(uuid "d19f6f14-e0d1-4549-b7cd-302df1d4c9ba")
	)
	(wire
		(pts
			(xy 107.95 116.84) (xy 107.95 48.26)
		)
		(stroke
			(width 0)
			(type default)
		)
		(uuid "d3205d21-8465-4bad-9f0d-33b845ead875")
	)
	(wire
		(pts
			(xy 119.38 78.74) (xy 144.78 78.74)
		)
		(stroke
			(width 0)
			(type default)
		)
		(uuid "d49ef040-83c7-4c20-82ab-0c1dda0f66c0")
	)
	(wire
		(pts
			(xy 97.79 135.89) (xy 102.87 135.89)
		)
		(stroke
			(width 0)
			(type default)
		)
		(uuid "d50fd9dd-5d42-40ad-ba11-e8cf28c4a9ae")
	)
	(wire
		(pts
			(xy 74.93 48.26) (xy 74.93 53.34)
		)
		(stroke
			(width 0)
			(type default)
		)
		(uuid "d7380ede-07ab-46b4-a450-4f5ab4f547a2")
	)
	(wire
		(pts
			(xy 45.72 140.97) (xy 50.8 140.97)
		)
		(stroke
			(width 0)
			(type default)
		)
		(uuid "d7f4032a-18d3-463b-ae3c-cefeb781e54c")
	)
	(wire
		(pts
			(xy 229.87 144.78) (xy 248.92 144.78)
		)
		(stroke
			(width 0)
			(type default)
		)
		(uuid "db8aedf3-0fe5-4646-bdf3-b4ff2c79a42f")
	)
	(wire
		(pts
			(xy 118.11 110.49) (xy 143.51 110.49)
		)
		(stroke
			(width 0)
			(type default)
		)
		(uuid "dbcf5b20-249d-4225-b912-7d64a9318117")
	)
	(wire
		(pts
			(xy 134.62 60.96) (xy 134.62 66.04)
		)
		(stroke
			(width 0)
			(type default)
		)
		(uuid "dc23ceb3-70e2-43ab-ab78-9f5570d2810c")
	)
	(wire
		(pts
			(xy 83.82 116.84) (xy 83.82 151.13)
		)
		(stroke
			(width 0)
			(type default)
		)
		(uuid "dc457cde-9861-44d6-bed4-71773d4da312")
	)
	(wire
		(pts
			(xy 238.76 125.73) (xy 238.76 139.7)
		)
		(stroke
			(width 0)
			(type default)
		)
		(uuid "dc9b0101-3ec6-4aff-bb1c-cfddc4e4c9fd")
	)
	(wire
		(pts
			(xy 83.82 151.13) (xy 102.87 151.13)
		)
		(stroke
			(width 0)
			(type default)
		)
		(uuid "dcb41ac3-e489-463b-907e-9a7750060801")
	)
	(wire
		(pts
			(xy 248.92 137.16) (xy 240.03 137.16)
		)
		(stroke
			(width 0)
			(type default)
		)
		(uuid "de8635f0-9a1f-40bd-9d1e-d9df39e14912")
	)
	(wire
		(pts
			(xy 229.87 137.16) (xy 229.87 125.73)
		)
		(stroke
			(width 0)
			(type default)
		)
		(uuid "e1ba64b0-0c0d-48ad-9d49-07fd80f94f60")
	)
	(wire
		(pts
			(xy 102.87 166.37) (xy 115.57 166.37)
		)
		(stroke
			(width 0)
			(type default)
		)
		(uuid "e38f2e54-0b1a-4f3c-b9ea-79fe1928050e")
	)
	(wire
		(pts
			(xy 135.89 102.87) (xy 135.89 104.14)
		)
		(stroke
			(width 0)
			(type default)
		)
		(uuid "e4249255-5846-4614-bebb-45d46bd802ad")
	)
	(wire
		(pts
			(xy 97.79 146.05) (xy 102.87 146.05)
		)
		(stroke
			(width 0)
			(type default)
		)
		(uuid "e50f70e6-9e85-4aef-a429-7d28f84a899f")
	)
	(wire
		(pts
			(xy 220.98 144.78) (xy 220.98 134.62)
		)
		(stroke
			(width 0)
			(type default)
		)
		(uuid "e5bef39c-81b6-4301-9a51-f60659ac5c7f")
	)
	(bus
		(pts
			(xy 43.18 96.52) (xy 43.18 130.81)
		)
		(stroke
			(width 0)
			(type default)
		)
		(uuid "e5e8c8b0-f1aa-4637-8e24-9f93fadff0ff")
	)
	(bus
		(pts
			(xy 43.18 58.42) (xy 43.18 83.82)
		)
		(stroke
			(width 0)
			(type default)
		)
		(uuid "e5eec9f3-63ed-483c-9a9e-d89ecc5ffed4")
	)
	(bus
		(pts
			(xy 43.18 45.72) (xy 43.18 48.26)
		)
		(stroke
			(width 0)
			(type default)
		)
		(uuid "e6360e81-5151-4855-a1cb-4623cef4afdb")
	)
	(wire
		(pts
			(xy 133.35 166.37) (xy 156.21 166.37)
		)
		(stroke
			(width 0)
			(type default)
		)
		(uuid "e8c3184b-2f11-4953-aa1e-42dd8353b252")
	)
	(wire
		(pts
			(xy 81.28 143.51) (xy 81.28 113.03)
		)
		(stroke
			(width 0)
			(type default)
		)
		(uuid "e9102b78-8d7f-413a-bc0b-e4e16635027b")
	)
	(wire
		(pts
			(xy 243.84 81.28) (xy 243.84 129.54)
		)
		(stroke
			(width 0)
			(type default)
		)
		(uuid "e9842817-f7b8-4124-bfe5-8e6932abd50f")
	)
	(bus
		(pts
			(xy 43.18 53.34) (xy 43.18 55.88)
		)
		(stroke
			(width 0)
			(type default)
		)
		(uuid "eeff202c-c095-4cb8-b5a2-e4bd558a19b8")
	)
	(wire
		(pts
			(xy 119.38 100.33) (xy 123.19 100.33)
		)
		(stroke
			(width 0)
			(type default)
		)
		(uuid "f114d761-ddfa-4984-9351-c8e97ffb8f59")
	)
	(wire
		(pts
			(xy 144.78 100.33) (xy 148.59 100.33)
		)
		(stroke
			(width 0)
			(type default)
		)
		(uuid "f3fada47-c3ce-4f89-b9d6-a5437d803ef6")
	)
	(wire
		(pts
			(xy 105.41 68.58) (xy 33.02 68.58)
		)
		(stroke
			(width 0)
			(type default)
		)
		(uuid "f6adc242-91da-4b8d-94a4-2a5bd4162a3b")
	)
	(wire
		(pts
			(xy 45.72 143.51) (xy 50.8 143.51)
		)
		(stroke
			(width 0)
			(type default)
		)
		(uuid "f72d6653-831a-4419-abde-61616f188e0e")
	)
	(wire
		(pts
			(xy 229.87 86.36) (xy 76.2 86.36)
		)
		(stroke
			(width 0)
			(type default)
		)
		(uuid "f78490b0-4f3e-43f7-a136-90e4df7bbe4c")
	)
	(bus
		(pts
			(xy 43.18 140.97) (xy 43.18 143.51)
		)
		(stroke
			(width 0)
			(type default)
		)
		(uuid "f850aca9-3b59-4f4e-9bb5-3b22c41d82a7")
	)
	(wire
		(pts
			(xy 278.13 137.16) (xy 274.32 137.16)
		)
		(stroke
			(width 0)
			(type default)
		)
		(uuid "f9e53f09-2066-4cec-86d5-aef2261866c0")
	)
	(wire
		(pts
			(xy 102.87 125.73) (xy 102.87 123.19)
		)
		(stroke
			(width 0)
			(type default)
		)
		(uuid "fa748ec5-034f-4a8e-a997-142009233347")
	)
	(wire
		(pts
			(xy 63.5 53.34) (xy 73.66 53.34)
		)
		(stroke
			(width 0)
			(type default)
		)
		(uuid "fd15952a-1052-449b-b454-00c3f4166189")
	)
	(wire
		(pts
			(xy 45.72 43.18) (xy 50.8 43.18)
		)
		(stroke
			(width 0)
			(type default)
		)
		(uuid "fe689f94-0065-47f5-927a-3072b5edff0d")
	)
	(bus
		(pts
			(xy 43.18 130.81) (xy 43.18 133.35)
		)
		(stroke
			(width 0)
			(type default)
		)
		(uuid "fff1b38e-79b5-440d-8347-9b74ef0c6399")
	)
	(text "$DF96 = SPI DATA R/W\n\n$DF97 (R) = SPI CLOCK, D0..1: SPI ~{ENABLE}, D4: SCL, D5: SDA, D6: I2C_SCL, D7: I2C_SDA\n$DF97 (W) = D0..1: SPI ~{ENABLE}, D4: SCL, D5: SDA"
		(exclude_from_sim no)
		(at 97.79 31.75 0)
		(effects
			(font
				(size 2.54 2.54)
				(thickness 0.508)
				(bold yes)
			)
			(justify left bottom)
		)
		(uuid "10a87ae3-655e-42e7-a022-5fc097d0e99b")
	)
	(label "PD4"
		(at 50.8 88.9 180)
		(effects
			(font
				(size 1.27 1.27)
			)
			(justify right bottom)
		)
		(uuid "080240fc-12dd-40b9-aa64-fef2a5f02558")
	)
	(label "~{CS3}"
		(at 248.92 134.62 180)
		(effects
			(font
				(size 1.27 1.27)
			)
			(justify right bottom)
		)
		(uuid "1306dd2c-e7f2-4108-92a2-801b5492f126")
	)
	(label "~{WR}"
		(at 83.82 116.84 0)
		(effects
			(font
				(size 1.27 1.27)
			)
			(justify left bottom)
		)
		(uuid "1456e386-e4d1-463d-9d16-6c531d7f3949")
	)
	(label "CLK"
		(at 92.71 121.92 0)
		(effects
			(font
				(size 1.27 1.27)
			)
			(justify left bottom)
		)
		(uuid "16f332e8-dd4c-4cc5-a624-4e8b4157ecde")
	)
	(label "~{CS0}"
		(at 123.19 102.87 180)
		(effects
			(font
				(size 1.27 1.27)
			)
			(justify right bottom)
		)
		(uuid "1ea2c235-b28e-495e-bb9d-d28b87afacbc")
	)
	(label "PD1"
		(at 274.32 129.54 0)
		(effects
			(font
				(size 1.27 1.27)
			)
			(justify left bottom)
		)
		(uuid "1f2fa0e4-f4c6-4f73-bd1e-e1a1b02c466f")
	)
	(label "PD3"
		(at 50.8 83.82 180)
		(effects
			(font
				(size 1.27 1.27)
			)
			(justify right bottom)
		)
		(uuid "2643d7dd-1299-486f-839b-56f5e1a5817b")
	)
	(label "PD4"
		(at 50.8 138.43 180)
		(effects
			(font
				(size 1.27 1.27)
			)
			(justify right bottom)
		)
		(uuid "275dc20c-af7a-4d7e-9f2b-63c9308da4bf")
	)
	(label "~{CS1}"
		(at 148.59 102.87 180)
		(effects
			(font
				(size 1.27 1.27)
			)
			(justify right bottom)
		)
		(uuid "28a2e750-1b0d-4f4f-bdc1-a21d60b41ef8")
	)
	(label "CLK"
		(at 101.6 55.88 0)
		(effects
			(font
				(size 1.27 1.27)
			)
			(justify left bottom)
		)
		(uuid "2a6c5c02-6c3b-42d0-ad00-7b2fd0ab20a1")
	)
	(label "D_SCK"
		(at 199.39 53.34 270)
		(effects
			(font
				(size 1.27 1.27)
			)
			(justify right bottom)
		)
		(uuid "2f6b2a21-f2fc-4f3f-9c53-5009b8d11278")
	)
	(label "PD5"
		(at 50.8 140.97 180)
		(effects
			(font
				(size 1.27 1.27)
			)
			(justify right bottom)
		)
		(uuid "2fb04231-125b-49c5-81e3-978e84bfaff3")
	)
	(label "PD4"
		(at 50.8 48.26 180)
		(effects
			(font
				(size 1.27 1.27)
			)
			(justify right bottom)
		)
		(uuid "305e92cb-d28f-4e8d-a371-981a4e1de8f5")
	)
	(label "PD3"
		(at 50.8 135.89 180)
		(effects
			(font
				(size 1.27 1.27)
			)
			(justify right bottom)
		)
		(uuid "34121389-7042-4d7a-bbb9-6335d998a5b6")
	)
	(label "~{WR}"
		(at 102.87 151.13 180)
		(effects
			(font
				(size 1.27 1.27)
			)
			(justify right bottom)
		)
		(uuid "350e0513-a31f-462a-b25f-c58708f39bbc")
	)
	(label "BA2"
		(at 64.77 45.72 0)
		(effects
			(font
				(size 1.27 1.27)
			)
			(justify left bottom)
		)
		(uuid "362622dc-7416-462e-af54-d6467895c3f3")
	)
	(label "MOSI"
		(at 135.89 100.33 0)
		(effects
			(font
				(size 1.27 1.27)
			)
			(justify left bottom)
		)
		(uuid "3837f578-0154-44f8-9d9b-d20fe5b37476")
	)
	(label "CLK"
		(at 120.65 66.04 270)
		(effects
			(font
				(size 1.27 1.27)
			)
			(justify right bottom)
		)
		(uuid "413b9da2-0816-4778-b4d3-4c978661bba5")
	)
	(label "~{CS1}"
		(at 248.92 129.54 180)
		(effects
			(font
				(size 1.27 1.27)
			)
			(justify right bottom)
		)
		(uuid "45f467e2-ef97-4528-9485-c5f4ef7c0a52")
	)
	(label "PD4"
		(at 102.87 138.43 180)
		(effects
			(font
				(size 1.27 1.27)
			)
			(justify right bottom)
		)
		(uuid "472d13f1-2184-4e41-98d1-52e70c12f8fa")
	)
	(label "SCL"
		(at 232.41 124.46 0)
		(effects
			(font
				(size 1.27 1.27)
			)
			(justify left bottom)
		)
		(uuid "473d7752-fa03-4976-9672-34c6f67fc549")
	)
	(label "MOSI"
		(at 128.27 125.73 0)
		(effects
			(font
				(size 1.27 1.27)
			)
			(justify left bottom)
		)
		(uuid "47fe039c-2577-4ce1-94e4-bf7321888d50")
	)
	(label "I2C_D"
		(at 248.92 144.78 180)
		(effects
			(font
				(size 1.27 1.27)
			)
			(justify right bottom)
		)
		(uuid "49050448-4993-43bc-8d2a-7358b82f50dd")
	)
	(label "PD6"
		(at 50.8 53.34 180)
		(effects
			(font
				(size 1.27 1.27)
			)
			(justify right bottom)
		)
		(uuid "5244b689-81f4-460e-9d73-d97180493a24")
	)
	(label "PD7"
		(at 50.8 146.05 180)
		(effects
			(font
				(size 1.27 1.27)
			)
			(justify right bottom)
		)
		(uuid "57ce85de-bbd4-4a58-8829-0a3f3a58d056")
	)
	(label "MISO"
		(at 83.82 110.49 0)
		(effects
			(font
				(size 1.27 1.27)
			)
			(justify left bottom)
		)
		(uuid "59b18932-40df-4a66-8e6b-e6b8e6f8405e")
	)
	(label "~{SCLK}"
		(at 187.96 53.34 180)
		(effects
			(font
				(size 1.27 1.27)
			)
			(justify right bottom)
		)
		(uuid "59e0f5af-c37b-4c00-ab08-f0bb1615ce0a")
	)
	(label "BA1"
		(at 64.77 43.18 0)
		(effects
			(font
				(size 1.27 1.27)
			)
			(justify left bottom)
		)
		(uuid "5ad48cc0-9dd9-4d98-8792-32177b987565")
	)
	(label "BA0"
		(at 64.77 40.64 0)
		(effects
			(font
				(size 1.27 1.27)
			)
			(justify left bottom)
		)
		(uuid "5e1e7e3e-6f7a-4c3b-a8b8-747bea60b03c")
	)
	(label "PD3"
		(at 50.8 45.72 180)
		(effects
			(font
				(size 1.27 1.27)
			)
			(justify right bottom)
		)
		(uuid "5ef70791-dd43-4efa-8f92-e6b4f306510d")
	)
	(label "~{CTL}"
		(at 101.6 53.34 0)
		(effects
			(font
				(size 1.27 1.27)
			)
			(justify left bottom)
		)
		(uuid "600224c2-c0f7-4d33-abac-330b9b2e46ca")
	)
	(label "PD1"
		(at 102.87 130.81 180)
		(effects
			(font
				(size 1.27 1.27)
			)
			(justify right bottom)
		)
		(uuid "68ba61f3-2067-40e8-b91c-455930253ef2")
	)
	(label "PD0"
		(at 50.8 93.98 180)
		(effects
			(font
				(size 1.27 1.27)
			)
			(justify right bottom)
		)
		(uuid "705897ee-749a-4396-a998-f99a19252300")
	)
	(label "MISO"
		(at 132.08 110.49 180)
		(effects
			(font
				(size 1.27 1.27)
			)
			(justify right bottom)
		)
		(uuid "70cf4ceb-6f81-4e21-86ea-7fe890733e4d")
	)
	(label "~{CS2}"
		(at 76.2 91.44 0)
		(effects
			(font
				(size 1.27 1.27)
			)
			(justify left bottom)
		)
		(uuid "71f0fd20-0b48-49ea-b952-01c0b43f1797")
	)
	(label "PD0"
		(at 102.87 128.27 180)
		(effects
			(font
				(size 1.27 1.27)
			)
			(justify right bottom)
		)
		(uuid "742066c4-58e2-4db4-9b1c-90abffe4b670")
	)
	(label "~{CS1}"
		(at 76.2 81.28 0)
		(effects
			(font
				(size 1.27 1.27)
			)
			(justify left bottom)
		)
		(uuid "7dcd0831-d916-43aa-98ca-a3b47846de07")
	)
	(label "PD7"
		(at 50.8 55.88 180)
		(effects
			(font
				(size 1.27 1.27)
			)
			(justify right bottom)
		)
		(uuid "7dfe3631-9596-4453-a0de-c74eb73dc0bb")
	)
	(label "PD0"
		(at 50.8 128.27 180)
		(effects
			(font
				(size 1.27 1.27)
			)
			(justify right bottom)
		)
		(uuid "8355250f-8107-4e4a-b400-fd63a8d59017")
	)
	(label "SCLK"
		(at 148.59 100.33 180)
		(effects
			(font
				(size 1.27 1.27)
			)
			(justify right bottom)
		)
		(uuid "83bc76a8-a6d9-4734-9681-098217342886")
	)
	(label "~{RD}"
		(at 101.6 50.8 0)
		(effects
			(font
				(size 1.27 1.27)
			)
			(justify left bottom)
		)
		(uuid "84b78ad5-f59e-4537-b017-e232d26095fc")
	)
	(label "PD7"
		(at 274.32 144.78 0)
		(effects
			(font
				(size 1.27 1.27)
			)
			(justify left bottom)
		)
		(uuid "8645823e-64b0-414d-8c2c-c34bd387bac4")
	)
	(label "~{CS0}"
		(at 76.2 93.98 0)
		(effects
			(font
				(size 1.27 1.27)
			)
			(justify left bottom)
		)
		(uuid "8d007b60-6ce7-42c7-869b-7de95ac8be97")
	)
	(label "PD3"
		(at 274.32 134.62 0)
		(effects
			(font
				(size 1.27 1.27)
			)
			(justify left bottom)
		)
		(uuid "8d17a581-514e-4ad8-bf01-f83fbbc1a1a4")
	)
	(label "~{CS2}"
		(at 248.92 132.08 180)
		(effects
			(font
				(size 1.27 1.27)
			)
			(justify right bottom)
		)
		(uuid "8db0017b-0c54-4579-ac4a-863c4610a9c9")
	)
	(label "MISO"
		(at 148.59 97.79 180)
		(effects
			(font
				(size 1.27 1.27)
			)
			(justify right bottom)
		)
		(uuid "908999ae-1a76-4751-b879-f99e812fe105")
	)
	(label "OCLK"
		(at 132.08 114.3 180)
		(effects
			(font
				(size 1.27 1.27)
			)
			(justify right bottom)
		)
		(uuid "956e4c6f-ab25-4769-8527-b7b987ab9fa9")
	)
	(label "PD6"
		(at 50.8 143.51 180)
		(effects
			(font
				(size 1.27 1.27)
			)
			(justify right bottom)
		)
		(uuid "98254e98-5b61-4898-82ed-9ca26f3cca2b")
	)
	(label "SCLK"
		(at 123.19 100.33 180)
		(effects
			(font
				(size 1.27 1.27)
			)
			(justify right bottom)
		)
		(uuid "991927f5-9860-47b1-a575-5937568bb5e1")
	)
	(label "~{CS0}"
		(at 248.92 127 180)
		(effects
			(font
				(size 1.27 1.27)
			)
			(justify right bottom)
		)
		(uuid "9a6aa887-bcbf-4e51-beff-ceb3a5b8c1a2")
	)
	(label "~{CTL}"
		(at 66.04 68.58 0)
		(effects
			(font
				(size 1.27 1.27)
			)
			(justify left bottom)
		)
		(uuid "9b37d8c4-cf9f-4f85-ac2b-a678cac31863")
	)
	(label "~{IOX}"
		(at 64.77 53.34 0)
		(effects
			(font
				(size 1.27 1.27)
			)
			(justify left bottom)
		)
		(uuid "9bfe03d4-714e-4550-9e25-84eab6d47d7b")
	)
	(label "~{RD}"
		(at 83.82 113.03 0)
		(effects
			(font
				(size 1.27 1.27)
			)
			(justify left bottom)
		)
		(uuid "a471a904-a9e8-4d86-b303-3c5f731caafd")
	)
	(label "BA3"
		(at 64.77 48.26 0)
		(effects
			(font
				(size 1.27 1.27)
			)
			(justify left bottom)
		)
		(uuid "a63517f8-4c92-4cc1-b376-76239e66b826")
	)
	(label "CLK"
		(at 102.87 156.21 180)
		(effects
			(font
				(size 1.27 1.27)
			)
			(justify right bottom)
		)
		(uuid "a8790991-237d-4655-9140-678dcf3cf7e2")
	)
	(label "SCL"
		(at 76.2 88.9 0)
		(effects
			(font
				(size 1.27 1.27)
			)
			(justify left bottom)
		)
		(uuid "a8afbe71-e395-466f-ae56-7225b4a885ab")
	)
	(label "PD3"
		(at 102.87 135.89 180)
		(effects
			(font
				(size 1.27 1.27)
			)
			(justify right bottom)
		)
		(uuid "aad4a2bc-74e5-4689-b911-607152a1a14f")
	)
	(label "~{WR}"
		(at 101.6 48.26 0)
		(effects
			(font
				(size 1.27 1.27)
			)
			(justify left bottom)
		)
		(uuid "ab247c96-e66a-4cef-a008-bfff832c7ab6")
	)
	(label "SDA"
		(at 76.2 86.36 0)
		(effects
			(font
				(size 1.27 1.27)
			)
			(justify left bottom)
		)
		(uuid "af1f2f39-86e7-4c26-b381-36090f830b83")
	)
	(label "BR~{W}"
		(at 64.77 50.8 0)
		(effects
			(font
				(size 1.27 1.27)
			)
			(justify left bottom)
		)
		(uuid "b238315c-611d-48fc-83ef-87b99322a597")
	)
	(label "PD5"
		(at 50.8 86.36 180)
		(effects
			(font
				(size 1.27 1.27)
			)
			(justify right bottom)
		)
		(uuid "b42fc5ff-1fbe-4f75-a7e1-c3ccc50efb67")
	)
	(label "CLK"
		(at 248.92 154.94 180)
		(fields_autoplaced yes)
		(effects
			(font
				(size 1.27 1.27)
			)
			(justify right bottom)
		)
		(uuid "b50d2549-8b34-411c-a1b0-cfe2557b357e")
	)
	(label "MOSI"
		(at 161.29 100.33 0)
		(effects
			(font
				(size 1.27 1.27)
			)
			(justify left bottom)
		)
		(uuid "b99d2698-fc2d-40dc-8ed7-32c193c79943")
	)
	(label "PD7"
		(at 102.87 146.05 180)
		(effects
			(font
				(size 1.27 1.27)
			)
			(justify right bottom)
		)
		(uuid "bade21b7-30af-4731-bd5a-957e586b874f")
	)
	(label "PD1"
		(at 50.8 130.81 180)
		(effects
			(font
				(size 1.27 1.27)
			)
			(justify right bottom)
		)
		(uuid "bb94b7a6-781f-4ad5-9528-f09768980e4a")
	)
	(label "MISO"
		(at 71.12 128.27 0)
		(effects
			(font
				(size 1.27 1.27)
			)
			(justify left bottom)
		)
		(uuid "bbeb52fd-2f28-45b1-96b1-9e1ae607bc7b")
	)
	(label "SDA"
		(at 229.87 124.46 180)
		(effects
			(font
				(size 1.27 1.27)
			)
			(justify right bottom)
		)
		(uuid "bdee0ec9-f271-490b-9bae-18c5c0481e43")
	)
	(label "PD2"
		(at 50.8 133.35 180)
		(effects
			(font
				(size 1.27 1.27)
			)
			(justify right bottom)
		)
		(uuid "bf0543a6-2b46-4f21-b13e-8abff7a7d961")
	)
	(label "PD0"
		(at 274.32 127 0)
		(effects
			(font
				(size 1.27 1.27)
			)
			(justify left bottom)
		)
		(uuid "bf5dad30-0a77-449f-81d0-9e326a1a9d04")
	)
	(label "PD1"
		(at 50.8 40.64 180)
		(effects
			(font
				(size 1.27 1.27)
			)
			(justify right bottom)
		)
		(uuid "c0668ab6-05aa-4455-8c80-e925bab85188")
	)
	(label "PD6"
		(at 102.87 143.51 180)
		(effects
			(font
				(size 1.27 1.27)
			)
			(justify right bottom)
		)
		(uuid "c0e86b98-3ef1-4ef1-a9b8-8341650b3b8e")
	)
	(label "~{RD}"
		(at 76.2 143.51 0)
		(effects
			(font
				(size 1.27 1.27)
			)
			(justify left bottom)
		)
		(uuid "c24036fd-4ead-4328-bae4-d849c4dde734")
	)
	(label "PD6"
		(at 274.32 142.24 0)
		(effects
			(font
				(size 1.27 1.27)
			)
			(justify left bottom)
		)
		(uuid "c24a37be-0c66-496b-a97e-7d16e2f2d298")
	)
	(label "PD5"
		(at 50.8 50.8 180)
		(effects
			(font
				(size 1.27 1.27)
			)
			(justify right bottom)
		)
		(uuid "c3a9b732-b776-4130-be77-90f00c4fdde8")
	)
	(label "OCLK"
		(at 217.17 50.8 0)
		(effects
			(font
				(size 1.27 1.27)
			)
			(justify left bottom)
		)
		(uuid "c4133a15-5c70-4572-ac95-8afc52aa0de3")
	)
	(label "PD0"
		(at 50.8 38.1 180)
		(effects
			(font
				(size 1.27 1.27)
			)
			(justify right bottom)
		)
		(uuid "c81319cf-0012-49dc-a71f-7d2272ca84f6")
	)
	(label "~{CS3}"
		(at 76.2 83.82 0)
		(effects
			(font
				(size 1.27 1.27)
			)
			(justify left bottom)
		)
		(uuid "c88f653a-41f5-4886-a66a-dbe27897abf2")
	)
	(label "I2C_C"
		(at 248.92 142.24 180)
		(effects
			(font
				(size 1.27 1.27)
			)
			(justify right bottom)
		)
		(uuid "c93271f2-2d14-4ae8-ae06-3049aab72e0d")
	)
	(label "~{WR}"
		(at 119.38 48.26 0)
		(effects
			(font
				(size 1.27 1.27)
			)
			(justify left bottom)
		)
		(uuid "cb27d9bf-3b80-48e7-9660-0e9305c3d120")
	)
	(label "MISO"
		(at 123.19 97.79 180)
		(effects
			(font
				(size 1.27 1.27)
			)
			(justify right bottom)
		)
		(uuid "cccc2329-5b86-4ff7-92b3-b24b7f8eb703")
	)
	(label "PD2"
		(at 274.32 132.08 0)
		(effects
			(font
				(size 1.27 1.27)
			)
			(justify left bottom)
		)
		(uuid "ccf8f698-3f33-45b9-8361-4df48c49f02a")
	)
	(label "PD5"
		(at 274.32 139.7 0)
		(effects
			(font
				(size 1.27 1.27)
			)
			(justify left bottom)
		)
		(uuid "d079c88c-3e6f-42c4-a020-5b63a0417f01")
	)
	(label "PD2"
		(at 50.8 91.44 180)
		(effects
			(font
				(size 1.27 1.27)
			)
			(justify right bottom)
		)
		(uuid "d58d235f-8bf7-427b-ba65-3513628c224b")
	)
	(label "PD2"
		(at 102.87 133.35 180)
		(effects
			(font
				(size 1.27 1.27)
			)
			(justify right bottom)
		)
		(uuid "d66b9b77-b2ba-4d21-a017-8a042c2ee682")
	)
	(label "PD2"
		(at 50.8 43.18 180)
		(effects
			(font
				(size 1.27 1.27)
			)
			(justify right bottom)
		)
		(uuid "d6f44ba1-4481-4784-8db8-59d32b1d629e")
	)
	(label "R_CLK"
		(at 149.86 63.5 270)
		(effects
			(font
				(size 1.27 1.27)
			)
			(justify right bottom)
		)
		(uuid "d89ded22-04b9-44a7-b708-61498a93128a")
	)
	(label "SCL"
		(at 248.92 137.16 180)
		(effects
			(font
				(size 1.27 1.27)
				(italic yes)
			)
			(justify right bottom)
		)
		(uuid "d9c1944f-eb8f-405f-888a-094675605ef5")
	)
	(label "D_CLK"
		(at 128.27 66.04 0)
		(effects
			(font
				(size 1.27 1.27)
			)
			(justify left bottom)
		)
		(uuid "dba9924b-12e2-4485-842e-97d662d6d67a")
	)
	(label "PD5"
		(at 102.87 140.97 180)
		(effects
			(font
				(size 1.27 1.27)
			)
			(justify right bottom)
		)
		(uuid "dbd26806-a5bc-4c9f-a27a-99d1d071f6b1")
	)
	(label "R_DLY"
		(at 157.48 63.5 270)
		(effects
			(font
				(size 1.27 1.27)
			)
			(justify right bottom)
		)
		(uuid "df640255-1508-45a0-ae73-216bbe74c655")
	)
	(label "SDA"
		(at 248.92 139.7 180)
		(effects
			(font
				(size 1.27 1.27)
				(italic yes)
			)
			(justify right bottom)
		)
		(uuid "e2866c23-134e-4610-abb1-efd8dfb43759")
	)
	(label "R_WR"
		(at 157.48 45.72 270)
		(effects
			(font
				(size 1.27 1.27)
			)
			(justify right bottom)
		)
		(uuid "e999f2b8-d549-42c4-ae18-5cb93d9900f6")
	)
	(label "PD1"
		(at 50.8 81.28 180)
		(effects
			(font
				(size 1.27 1.27)
			)
			(justify right bottom)
		)
		(uuid "eb3bc225-c039-41d2-a039-49a80eb242b8")
	)
	(label "~{CTL}"
		(at 50.8 99.06 180)
		(effects
			(font
				(size 1.27 1.27)
			)
			(justify right bottom)
		)
		(uuid "ed3bd07d-d7e2-415f-92d2-04fcf9cdb1f0")
	)
	(label "PD4"
		(at 274.32 137.16 0)
		(effects
			(font
				(size 1.27 1.27)
			)
			(justify left bottom)
		)
		(uuid "f3cc1225-23a2-44b2-b900-cbc340c73a20")
	)
	(label "D_WR"
		(at 128.27 48.26 0)
		(effects
			(font
				(size 1.27 1.27)
			)
			(justify left bottom)
		)
		(uuid "f765ef35-d338-4aef-93c8-a22bcf7587ef")
	)
	(label "OCLK"
		(at 72.39 114.3 0)
		(effects
			(font
				(size 1.27 1.27)
			)
			(justify left bottom)
		)
		(uuid "f8ceade6-5f1b-46c0-98b3-47ac64b74995")
	)
	(label "SCLK"
		(at 167.64 78.74 0)
		(effects
			(font
				(size 1.27 1.27)
			)
			(justify left bottom)
		)
		(uuid "fd0f9b57-4424-4732-a47d-8cd62105cf2a")
	)
	(global_label "PD[0..7]"
		(shape input)
		(at 43.18 80.01 180)
		(effects
			(font
				(size 1.27 1.27)
			)
			(justify right)
		)
		(uuid "4cb8ca6b-2a63-4907-98cb-1fd26f1fb901")
		(property "Intersheetrefs" "${INTERSHEET_REFS}"
			(at 43.18 80.01 0)
			(effects
				(font
					(size 1.27 1.27)
				)
				(hide yes)
			)
		)
	)
	(symbol
		(lib_id "Connector_Generic:Conn_02x08_Odd_Even")
		(at 58.42 45.72 0)
		(mirror y)
		(unit 1)
		(exclude_from_sim no)
		(in_bom yes)
		(on_board yes)
		(dnp no)
		(uuid "00000000-0000-0000-0000-000064c3fa9e")
		(property "Reference" "J1"
			(at 57.15 32.5882 0)
			(effects
				(font
					(size 1.27 1.27)
				)
			)
		)
		(property "Value" "IOx"
			(at 57.15 34.8996 0)
			(effects
				(font
					(size 1.27 1.27)
				)
			)
		)
		(property "Footprint" "Connector_PinSocket_2.54mm:PinSocket_2x08_P2.54mm_Horizontal"
			(at 58.42 45.72 0)
			(effects
				(font
					(size 1.27 1.27)
				)
				(hide yes)
			)
		)
		(property "Datasheet" "~"
			(at 58.42 45.72 0)
			(effects
				(font
					(size 1.27 1.27)
				)
				(hide yes)
			)
		)
		(property "Description" ""
			(at 58.42 45.72 0)
			(effects
				(font
					(size 1.27 1.27)
				)
				(hide yes)
			)
		)
		(pin "1"
			(uuid "1ac10791-86ba-455d-a6a2-455ce5c4f223")
		)
		(pin "10"
			(uuid "fafbced0-0abc-4e09-bb5a-84de8e1c2c1f")
		)
		(pin "11"
			(uuid "e90e4ef2-7317-41dc-b4ce-1228618390e5")
		)
		(pin "12"
			(uuid "585681c0-a8ac-4a75-80ee-38c8faa05333")
		)
		(pin "13"
			(uuid "5af0ddf3-8882-49cc-9a64-65f4b546ec9d")
		)
		(pin "14"
			(uuid "1126b50c-ec44-4b74-b51e-de552432d7e0")
		)
		(pin "15"
			(uuid "30922285-4c0e-4c2a-bac2-3035779f05d8")
		)
		(pin "16"
			(uuid "d3049114-dffd-42ac-97c9-05aca9165008")
		)
		(pin "2"
			(uuid "11932d64-2176-4908-a890-211b6736dca4")
		)
		(pin "3"
			(uuid "bd0d7281-25b4-4aab-a3df-92246c901abb")
		)
		(pin "4"
			(uuid "a89b2236-307c-450f-a085-bf8a7d38372c")
		)
		(pin "5"
			(uuid "1856b708-a635-4184-aa22-27839d766e5e")
		)
		(pin "6"
			(uuid "ed2a67cb-d090-4df5-b4b0-c989d065344b")
		)
		(pin "7"
			(uuid "5995f9e5-1f85-4ef2-9578-e8213375e320")
		)
		(pin "8"
			(uuid "93ffee5e-becb-41f9-be5c-ad79c72200ee")
		)
		(pin "9"
			(uuid "273b136f-9354-4e20-8f6e-c86d6541f8b7")
		)
		(instances
			(project ""
				(path "/02b1dd05-420e-48b3-9ee8-c9edbf2413ac"
					(reference "J1")
					(unit 1)
				)
			)
		)
	)
	(symbol
		(lib_id "Connector_Generic:Conn_02x03_Odd_Even")
		(at 128.27 100.33 0)
		(unit 1)
		(exclude_from_sim no)
		(in_bom yes)
		(on_board yes)
		(dnp no)
		(uuid "00000000-0000-0000-0000-000064c4033d")
		(property "Reference" "J2"
			(at 129.54 95.25 0)
			(effects
				(font
					(size 1.27 1.27)
				)
			)
		)
		(property "Value" "SPI 0"
			(at 129.54 105.41 0)
			(effects
				(font
					(size 1.27 1.27)
				)
			)
		)
		(property "Footprint" "Connector_IDC:IDC-Header_2x03_P2.54mm_Vertical"
			(at 128.27 100.33 0)
			(effects
				(font
					(size 1.27 1.27)
				)
				(hide yes)
			)
		)
		(property "Datasheet" "~"
			(at 128.27 100.33 0)
			(effects
				(font
					(size 1.27 1.27)
				)
				(hide yes)
			)
		)
		(property "Description" ""
			(at 128.27 100.33 0)
			(effects
				(font
					(size 1.27 1.27)
				)
				(hide yes)
			)
		)
		(pin "1"
			(uuid "1f058e69-2671-485e-86a4-22e55f38298d")
		)
		(pin "2"
			(uuid "7e30259a-e2a0-43c2-b756-7bfa14b33130")
		)
		(pin "3"
			(uuid "d353f3ac-822c-41d3-981b-048bc0595181")
		)
		(pin "4"
			(uuid "4eb6525d-06e5-4b46-971f-6a073c44f20e")
		)
		(pin "5"
			(uuid "f31a8356-24c7-4255-851b-e4665d4b5b8b")
		)
		(pin "6"
			(uuid "20a5d0b1-0d55-406f-ac1b-af3f1286a8fc")
		)
		(instances
			(project ""
				(path "/02b1dd05-420e-48b3-9ee8-c9edbf2413ac"
					(reference "J2")
					(unit 1)
				)
			)
		)
	)
	(symbol
		(lib_id "74xx:74LS138")
		(at 88.9 45.72 0)
		(unit 1)
		(exclude_from_sim no)
		(in_bom yes)
		(on_board yes)
		(dnp no)
		(uuid "00000000-0000-0000-0000-000064c418c7")
		(property "Reference" "U1"
			(at 83.82 34.29 0)
			(effects
				(font
					(size 1.27 1.27)
				)
			)
		)
		(property "Value" "74HC138"
			(at 93.98 34.29 0)
			(effects
				(font
					(size 1.27 1.27)
				)
			)
		)
		(property "Footprint" "Package_DIP:DIP-16_W7.62mm_Socket"
			(at 88.9 45.72 0)
			(effects
				(font
					(size 1.27 1.27)
				)
				(hide yes)
			)
		)
		(property "Datasheet" "http://www.ti.com/lit/gpn/sn74LS138"
			(at 88.9 45.72 0)
			(effects
				(font
					(size 1.27 1.27)
				)
				(hide yes)
			)
		)
		(property "Description" ""
			(at 88.9 45.72 0)
			(effects
				(font
					(size 1.27 1.27)
				)
				(hide yes)
			)
		)
		(pin "1"
			(uuid "9d7409f0-8f17-482b-92f1-56073a102e39")
		)
		(pin "10"
			(uuid "1ec2922a-7e27-4d7c-a6e6-47f9ff35be93")
		)
		(pin "11"
			(uuid "25dce2a7-3473-4799-94cd-7f0e518d2214")
		)
		(pin "12"
			(uuid "4d2fb547-47dd-410f-bf1b-f8087f7af8d1")
		)
		(pin "13"
			(uuid "fa8575ed-efa5-4f6b-b9a7-ec275e537f4c")
		)
		(pin "14"
			(uuid "bfa0b670-f60d-4042-affb-2ce2ee35d635")
		)
		(pin "15"
			(uuid "0287107d-fd79-49d5-a33e-621b48afde4c")
		)
		(pin "16"
			(uuid "955c1481-abf2-4631-87df-6711d3ca39fe")
		)
		(pin "2"
			(uuid "d5040f51-5bac-424a-b4b2-5dd798b69e6f")
		)
		(pin "3"
			(uuid "a012da34-5f84-4377-b7a0-9d36bd4c48ca")
		)
		(pin "4"
			(uuid "106350cb-b0eb-48a0-83f7-4f6cfbb7799c")
		)
		(pin "5"
			(uuid "b213a1ec-cbef-4174-b0b1-faef179376fa")
		)
		(pin "6"
			(uuid "6c307fc4-1496-48c0-b2a7-8bd97b7c99cf")
		)
		(pin "7"
			(uuid "962c6fc8-876c-4445-900d-20e73252a39e")
		)
		(pin "8"
			(uuid "abb371e6-efd5-4da8-8670-314b69896d70")
		)
		(pin "9"
			(uuid "6f43e1b0-d38b-4989-8c5b-b7de9d80ac0d")
		)
		(instances
			(project ""
				(path "/02b1dd05-420e-48b3-9ee8-c9edbf2413ac"
					(reference "U1")
					(unit 1)
				)
			)
		)
	)
	(symbol
		(lib_id "74xx:74LS165")
		(at 115.57 140.97 0)
		(unit 1)
		(exclude_from_sim no)
		(in_bom yes)
		(on_board yes)
		(dnp no)
		(uuid "00000000-0000-0000-0000-000064c425db")
		(property "Reference" "U3"
			(at 110.49 121.92 0)
			(effects
				(font
					(size 1.27 1.27)
				)
			)
		)
		(property "Value" "74HC165"
			(at 120.65 121.92 0)
			(effects
				(font
					(size 1.27 1.27)
				)
			)
		)
		(property "Footprint" "Package_DIP:DIP-16_W7.62mm_Socket"
			(at 115.57 140.97 0)
			(effects
				(font
					(size 1.27 1.27)
				)
				(hide yes)
			)
		)
		(property "Datasheet" "http://www.ti.com/lit/gpn/sn74LS165"
			(at 115.57 140.97 0)
			(effects
				(font
					(size 1.27 1.27)
				)
				(hide yes)
			)
		)
		(property "Description" ""
			(at 115.57 140.97 0)
			(effects
				(font
					(size 1.27 1.27)
				)
				(hide yes)
			)
		)
		(pin "1"
			(uuid "81cc4cf9-c593-436d-9068-b9b0860db010")
		)
		(pin "10"
			(uuid "17bd244a-63ef-4d21-803c-aba7f3a7e87f")
		)
		(pin "11"
			(uuid "a723573f-1208-4d12-8078-f97a06681318")
		)
		(pin "12"
			(uuid "721b6c0c-8165-4b64-8ab8-d26c384dff00")
		)
		(pin "13"
			(uuid "32b00e63-f761-4efa-9e0e-addb7d2404e3")
		)
		(pin "14"
			(uuid "0a143d4a-d29d-4e61-92ff-9bda7ce24876")
		)
		(pin "15"
			(uuid "257b3dfb-2c2c-4a89-9c09-2c9ac0e2149d")
		)
		(pin "16"
			(uuid "e13772d7-b979-4ac1-ab2c-190db9ba2a28")
		)
		(pin "2"
			(uuid "ce5d87eb-52e5-4284-b4f1-7e04a83d25d1")
		)
		(pin "3"
			(uuid "68479757-efca-4801-99f8-fad87427638e")
		)
		(pin "4"
			(uuid "4515fb46-29f9-4b2a-9d23-f0f104d90c64")
		)
		(pin "5"
			(uuid "3513b3c1-3c6f-41e5-a7b1-1c3673251aa9")
		)
		(pin "6"
			(uuid "14b80060-d187-44b7-b9be-e6a1777b8f6b")
		)
		(pin "7"
			(uuid "12f5d795-3e6a-4753-90e6-11c9143d8cdc")
		)
		(pin "8"
			(uuid "57318d92-d9f6-47ee-bed1-b99d08614646")
		)
		(pin "9"
			(uuid "cedeee42-d76e-45c6-bb33-34ffd608503b")
		)
		(instances
			(project ""
				(path "/02b1dd05-420e-48b3-9ee8-c9edbf2413ac"
					(reference "U3")
					(unit 1)
				)
			)
		)
	)
	(symbol
		(lib_id "74xx:74HC595")
		(at 60.96 138.43 0)
		(mirror y)
		(unit 1)
		(exclude_from_sim no)
		(in_bom yes)
		(on_board yes)
		(dnp no)
		(uuid "00000000-0000-0000-0000-000064c42dae")
		(property "Reference" "U4"
			(at 57.15 124.46 0)
			(effects
				(font
					(size 1.27 1.27)
				)
			)
		)
		(property "Value" "74HC595"
			(at 66.04 124.46 0)
			(effects
				(font
					(size 1.27 1.27)
				)
			)
		)
		(property "Footprint" "Package_DIP:DIP-16_W7.62mm_Socket"
			(at 60.96 138.43 0)
			(effects
				(font
					(size 1.27 1.27)
				)
				(hide yes)
			)
		)
		(property "Datasheet" "http://www.ti.com/lit/ds/symlink/sn74hc595.pdf"
			(at 60.96 138.43 0)
			(effects
				(font
					(size 1.27 1.27)
				)
				(hide yes)
			)
		)
		(property "Description" ""
			(at 60.96 138.43 0)
			(effects
				(font
					(size 1.27 1.27)
				)
				(hide yes)
			)
		)
		(pin "3"
			(uuid "b8c87863-9976-4639-864f-758ae2ccbc53")
		)
		(pin "4"
			(uuid "7a583596-3e8e-47a8-a5dc-33410d85d9c1")
		)
		(pin "5"
			(uuid "eabc508b-cd26-484a-b595-1874b027f512")
		)
		(pin "6"
			(uuid "638070bb-bfd9-4bfe-b3df-e9aeec40f215")
		)
		(pin "7"
			(uuid "707ff185-ee64-465c-8da1-4f03a6de1142")
		)
		(pin "8"
			(uuid "e74fd466-461a-4c5d-9a0b-5734db85bd03")
		)
		(pin "9"
			(uuid "12a404d2-cece-4530-a3f4-444b0e60db3e")
		)
		(pin "1"
			(uuid "eab07a79-1021-443e-b776-c83f7620b098")
		)
		(pin "10"
			(uuid "29ae609b-8415-4cbf-8388-4285a94d1b80")
		)
		(pin "11"
			(uuid "55893697-9f1f-4726-bd22-6cdf487a33ad")
		)
		(pin "12"
			(uuid "77a84b0b-a53e-43c8-b16d-e26a6b7111aa")
		)
		(pin "13"
			(uuid "9aa66eaa-9911-4fd4-ba0d-c3307a5e7514")
		)
		(pin "14"
			(uuid "42243d22-2083-4d2a-9fe6-5ee55a940fb5")
		)
		(pin "15"
			(uuid "2cbe55c2-9750-4c71-b9c7-9569dd55eb7d")
		)
		(pin "16"
			(uuid "07ad6ca5-04da-4a7b-aedf-4fb48faf32fd")
		)
		(pin "2"
			(uuid "c3f3f21e-ee38-4c9a-983a-67abb155cac1")
		)
		(instances
			(project ""
				(path "/02b1dd05-420e-48b3-9ee8-c9edbf2413ac"
					(reference "U4")
					(unit 1)
				)
			)
		)
	)
	(symbol
		(lib_id "74xx:74LS174")
		(at 63.5 91.44 0)
		(unit 1)
		(exclude_from_sim no)
		(in_bom yes)
		(on_board yes)
		(dnp no)
		(uuid "00000000-0000-0000-0000-000064c4633b")
		(property "Reference" "U2"
			(at 58.42 77.47 0)
			(effects
				(font
					(size 1.27 1.27)
				)
			)
		)
		(property "Value" "74HC174"
			(at 68.58 77.47 0)
			(effects
				(font
					(size 1.27 1.27)
				)
			)
		)
		(property "Footprint" "Package_DIP:DIP-16_W7.62mm_Socket"
			(at 63.5 91.44 0)
			(effects
				(font
					(size 1.27 1.27)
				)
				(hide yes)
			)
		)
		(property "Datasheet" "http://www.ti.com/lit/gpn/sn74LS174"
			(at 63.5 91.44 0)
			(effects
				(font
					(size 1.27 1.27)
				)
				(hide yes)
			)
		)
		(property "Description" ""
			(at 63.5 91.44 0)
			(effects
				(font
					(size 1.27 1.27)
				)
				(hide yes)
			)
		)
		(pin "12"
			(uuid "a7b7c52b-2286-409b-9f97-1bd6e46383b7")
		)
		(pin "16"
			(uuid "fa29f47f-c794-473c-ada9-7637f788732c")
		)
		(pin "6"
			(uuid "5358b6c6-4b8c-4070-83b3-e8e47a498daa")
		)
		(pin "4"
			(uuid "218328ed-1c0b-4788-b1dd-4f82cd2bbac3")
		)
		(pin "15"
			(uuid "c3bf1c5a-9cf3-4a1e-a3e6-47c63097252a")
		)
		(pin "7"
			(uuid "2882d806-6486-45bc-ba36-93b05794d69b")
		)
		(pin "14"
			(uuid "b5ea1c0d-e560-4935-8f72-0cb5338eb312")
		)
		(pin "13"
			(uuid "55d9ea45-bf69-4f7b-b965-799ec2b68edc")
		)
		(pin "8"
			(uuid "860d4573-c3af-474e-8851-5a198922a4f5")
		)
		(pin "9"
			(uuid "593c6ff2-ec48-44bd-bae2-08fe56e08b2e")
		)
		(pin "3"
			(uuid "90f10436-1de8-42a2-a0a6-c000734d0328")
		)
		(pin "2"
			(uuid "5f36964b-5be0-45e5-9412-57f59bf89648")
		)
		(pin "5"
			(uuid "2c858aeb-351c-4eae-b9c8-450bff1ee1dd")
		)
		(pin "1"
			(uuid "f5f768f0-6e61-4eba-91a5-703302e1890f")
		)
		(pin "11"
			(uuid "fe5cc0ea-bff2-4dae-b8b3-1e5f201d1efa")
		)
		(pin "10"
			(uuid "a0605f1a-85de-4bbb-9aac-defa9f96259b")
		)
		(instances
			(project ""
				(path "/02b1dd05-420e-48b3-9ee8-c9edbf2413ac"
					(reference "U2")
					(unit 1)
				)
			)
		)
	)
	(symbol
		(lib_id "rtc-sd-rescue:+5V-power")
		(at 63.5 30.48 0)
		(unit 1)
		(exclude_from_sim no)
		(in_bom yes)
		(on_board yes)
		(dnp no)
		(uuid "00000000-0000-0000-0000-000064caf1ba")
		(property "Reference" "#PWR0101"
			(at 63.5 34.29 0)
			(effects
				(font
					(size 1.27 1.27)
				)
				(hide yes)
			)
		)
		(property "Value" "+5V"
			(at 63.881 26.0858 0)
			(effects
				(font
					(size 1.27 1.27)
				)
			)
		)
		(property "Footprint" ""
			(at 63.5 30.48 0)
			(effects
				(font
					(size 1.27 1.27)
				)
				(hide yes)
			)
		)
		(property "Datasheet" ""
			(at 63.5 30.48 0)
			(effects
				(font
					(size 1.27 1.27)
				)
				(hide yes)
			)
		)
		(property "Description" ""
			(at 63.5 30.48 0)
			(effects
				(font
					(size 1.27 1.27)
				)
				(hide yes)
			)
		)
		(pin "1"
			(uuid "e25ca26d-21e5-4770-aa0c-a2a70855624b")
		)
		(instances
			(project ""
				(path "/02b1dd05-420e-48b3-9ee8-c9edbf2413ac"
					(reference "#PWR0101")
					(unit 1)
				)
			)
		)
	)
	(symbol
		(lib_id "rtc-sd-rescue:GND-power")
		(at 63.5 63.5 0)
		(unit 1)
		(exclude_from_sim no)
		(in_bom yes)
		(on_board yes)
		(dnp no)
		(uuid "00000000-0000-0000-0000-000064caf465")
		(property "Reference" "#PWR0102"
			(at 63.5 69.85 0)
			(effects
				(font
					(size 1.27 1.27)
				)
				(hide yes)
			)
		)
		(property "Value" "GND"
			(at 60.96 66.04 0)
			(effects
				(font
					(size 1.27 1.27)
				)
			)
		)
		(property "Footprint" ""
			(at 63.5 63.5 0)
			(effects
				(font
					(size 1.27 1.27)
				)
				(hide yes)
			)
		)
		(property "Datasheet" ""
			(at 63.5 63.5 0)
			(effects
				(font
					(size 1.27 1.27)
				)
				(hide yes)
			)
		)
		(property "Description" ""
			(at 63.5 63.5 0)
			(effects
				(font
					(size 1.27 1.27)
				)
				(hide yes)
			)
		)
		(pin "1"
			(uuid "9d9edbff-3c51-4fcf-9018-c2e0b9e14168")
		)
		(instances
			(project ""
				(path "/02b1dd05-420e-48b3-9ee8-c9edbf2413ac"
					(reference "#PWR0102")
					(unit 1)
				)
			)
		)
	)
	(symbol
		(lib_id "Device:R")
		(at 128.27 52.07 0)
		(unit 1)
		(exclude_from_sim no)
		(in_bom yes)
		(on_board yes)
		(dnp no)
		(uuid "00000000-0000-0000-0000-000064cbd13f")
		(property "Reference" "R2"
			(at 127 45.72 0)
			(effects
				(font
					(size 1.27 1.27)
				)
				(justify left)
			)
		)
		(property "Value" "3K3"
			(at 128.27 52.07 90)
			(effects
				(font
					(size 1.27 1.27)
				)
			)
		)
		(property "Footprint" "Resistor_THT:R_Axial_DIN0207_L6.3mm_D2.5mm_P2.54mm_Vertical"
			(at 126.492 52.07 90)
			(effects
				(font
					(size 1.27 1.27)
				)
				(hide yes)
			)
		)
		(property "Datasheet" "~"
			(at 128.27 52.07 0)
			(effects
				(font
					(size 1.27 1.27)
				)
				(hide yes)
			)
		)
		(property "Description" ""
			(at 128.27 52.07 0)
			(effects
				(font
					(size 1.27 1.27)
				)
				(hide yes)
			)
		)
		(pin "1"
			(uuid "b69068a3-455f-4e36-b3d2-b9a0b625fc7b")
		)
		(pin "2"
			(uuid "3af866b9-9635-4ab0-b34a-8f5764059693")
		)
		(instances
			(project ""
				(path "/02b1dd05-420e-48b3-9ee8-c9edbf2413ac"
					(reference "R2")
					(unit 1)
				)
			)
		)
	)
	(symbol
		(lib_id "Device:R")
		(at 128.27 69.85 0)
		(unit 1)
		(exclude_from_sim no)
		(in_bom yes)
		(on_board yes)
		(dnp no)
		(uuid "00000000-0000-0000-0000-000064cbd149")
		(property "Reference" "R3"
			(at 127 63.5 0)
			(effects
				(font
					(size 1.27 1.27)
				)
				(justify left)
			)
		)
		(property "Value" "3K3"
			(at 128.27 69.85 90)
			(effects
				(font
					(size 1.27 1.27)
				)
			)
		)
		(property "Footprint" "Resistor_THT:R_Axial_DIN0207_L6.3mm_D2.5mm_P2.54mm_Vertical"
			(at 126.492 69.85 90)
			(effects
				(font
					(size 1.27 1.27)
				)
				(hide yes)
			)
		)
		(property "Datasheet" "~"
			(at 128.27 69.85 0)
			(effects
				(font
					(size 1.27 1.27)
				)
				(hide yes)
			)
		)
		(property "Description" ""
			(at 128.27 69.85 0)
			(effects
				(font
					(size 1.27 1.27)
				)
				(hide yes)
			)
		)
		(pin "1"
			(uuid "704b2f64-e894-4f9c-9b68-9757d00cc6a6")
		)
		(pin "2"
			(uuid "bf4722cf-b1b6-4d01-b6c4-00825f33b5c7")
		)
		(instances
			(project ""
				(path "/02b1dd05-420e-48b3-9ee8-c9edbf2413ac"
					(reference "R3")
					(unit 1)
				)
			)
		)
	)
	(symbol
		(lib_id "Device:R")
		(at 153.67 63.5 270)
		(unit 1)
		(exclude_from_sim no)
		(in_bom yes)
		(on_board yes)
		(dnp no)
		(uuid "00000000-0000-0000-0000-000064cbd15d")
		(property "Reference" "R5"
			(at 153.67 60.96 90)
			(effects
				(font
					(size 1.27 1.27)
				)
			)
		)
		(property "Value" "3K3"
			(at 153.67 63.5 90)
			(effects
				(font
					(size 1.27 1.27)
				)
			)
		)
		(property "Footprint" "Resistor_THT:R_Axial_DIN0207_L6.3mm_D2.5mm_P2.54mm_Vertical"
			(at 153.67 61.722 90)
			(effects
				(font
					(size 1.27 1.27)
				)
				(hide yes)
			)
		)
		(property "Datasheet" "~"
			(at 153.67 63.5 0)
			(effects
				(font
					(size 1.27 1.27)
				)
				(hide yes)
			)
		)
		(property "Description" ""
			(at 153.67 63.5 0)
			(effects
				(font
					(size 1.27 1.27)
				)
				(hide yes)
			)
		)
		(pin "1"
			(uuid "6ce99b4f-ac48-488c-a337-776c4d0572f8")
		)
		(pin "2"
			(uuid "9c253918-73ff-4e4d-861d-75a5cf1e59d0")
		)
		(instances
			(project ""
				(path "/02b1dd05-420e-48b3-9ee8-c9edbf2413ac"
					(reference "R5")
					(unit 1)
				)
			)
		)
	)
	(symbol
		(lib_id "Device:C")
		(at 124.46 48.26 270)
		(unit 1)
		(exclude_from_sim no)
		(in_bom yes)
		(on_board yes)
		(dnp no)
		(uuid "00000000-0000-0000-0000-000064cbd167")
		(property "Reference" "C2"
			(at 124.46 44.45 90)
			(effects
				(font
					(size 1.27 1.27)
				)
			)
		)
		(property "Value" "68p"
			(at 124.46 52.07 90)
			(effects
				(font
					(size 1.27 1.27)
				)
			)
		)
		(property "Footprint" "Capacitor_THT:C_Disc_D3.8mm_W2.6mm_P2.50mm"
			(at 120.65 49.2252 0)
			(effects
				(font
					(size 1.27 1.27)
				)
				(hide yes)
			)
		)
		(property "Datasheet" "~"
			(at 124.46 48.26 0)
			(effects
				(font
					(size 1.27 1.27)
				)
				(hide yes)
			)
		)
		(property "Description" ""
			(at 124.46 48.26 0)
			(effects
				(font
					(size 1.27 1.27)
				)
				(hide yes)
			)
		)
		(pin "1"
			(uuid "a521e462-575f-4c5a-9ceb-4819db40b5e9")
		)
		(pin "2"
			(uuid "a877b32c-d709-4f9e-b704-d44a91aa2ee1")
		)
		(instances
			(project ""
				(path "/02b1dd05-420e-48b3-9ee8-c9edbf2413ac"
					(reference "C2")
					(unit 1)
				)
			)
		)
	)
	(symbol
		(lib_id "Device:C")
		(at 124.46 66.04 270)
		(unit 1)
		(exclude_from_sim no)
		(in_bom yes)
		(on_board yes)
		(dnp no)
		(uuid "00000000-0000-0000-0000-000064cbd171")
		(property "Reference" "C3"
			(at 124.46 62.23 90)
			(effects
				(font
					(size 1.27 1.27)
				)
			)
		)
		(property "Value" "68p"
			(at 124.46 69.85 90)
			(effects
				(font
					(size 1.27 1.27)
				)
			)
		)
		(property "Footprint" "Capacitor_THT:C_Disc_D3.8mm_W2.6mm_P2.50mm"
			(at 120.65 67.0052 0)
			(effects
				(font
					(size 1.27 1.27)
				)
				(hide yes)
			)
		)
		(property "Datasheet" "~"
			(at 124.46 66.04 0)
			(effects
				(font
					(size 1.27 1.27)
				)
				(hide yes)
			)
		)
		(property "Description" ""
			(at 124.46 66.04 0)
			(effects
				(font
					(size 1.27 1.27)
				)
				(hide yes)
			)
		)
		(pin "1"
			(uuid "6a5302bf-f58f-4317-ba79-248d783ae57c")
		)
		(pin "2"
			(uuid "995cb764-fe04-45e9-8f6d-71a12fc2e3b1")
		)
		(instances
			(project ""
				(path "/02b1dd05-420e-48b3-9ee8-c9edbf2413ac"
					(reference "C3")
					(unit 1)
				)
			)
		)
	)
	(symbol
		(lib_id "Device:C")
		(at 191.77 53.34 270)
		(unit 1)
		(exclude_from_sim no)
		(in_bom yes)
		(on_board yes)
		(dnp no)
		(uuid "00000000-0000-0000-0000-000064cbd17b")
		(property "Reference" "C4"
			(at 191.77 49.53 90)
			(effects
				(font
					(size 1.27 1.27)
				)
			)
		)
		(property "Value" "68p"
			(at 191.77 57.15 90)
			(effects
				(font
					(size 1.27 1.27)
				)
			)
		)
		(property "Footprint" "Capacitor_THT:C_Disc_D3.8mm_W2.6mm_P2.50mm"
			(at 187.96 54.3052 0)
			(effects
				(font
					(size 1.27 1.27)
				)
				(hide yes)
			)
		)
		(property "Datasheet" "~"
			(at 191.77 53.34 0)
			(effects
				(font
					(size 1.27 1.27)
				)
				(hide yes)
			)
		)
		(property "Description" ""
			(at 191.77 53.34 0)
			(effects
				(font
					(size 1.27 1.27)
				)
				(hide yes)
			)
		)
		(pin "1"
			(uuid "8eb75c15-7845-424d-90b1-e58719c34a03")
		)
		(pin "2"
			(uuid "1f3ba4bc-0268-40bf-b52d-1053aa39b2df")
		)
		(instances
			(project ""
				(path "/02b1dd05-420e-48b3-9ee8-c9edbf2413ac"
					(reference "C4")
					(unit 1)
				)
			)
		)
	)
	(symbol
		(lib_id "Device:D")
		(at 134.62 52.07 270)
		(unit 1)
		(exclude_from_sim no)
		(in_bom yes)
		(on_board yes)
		(dnp no)
		(uuid "00000000-0000-0000-0000-000064cbd185")
		(property "Reference" "D1"
			(at 134.62 49.53 90)
			(effects
				(font
					(size 1.27 1.27)
				)
				(justify left)
			)
		)
		(property "Value" "4148"
			(at 134.62 54.61 90)
			(effects
				(font
					(size 1.27 1.27)
				)
				(justify left)
			)
		)
		(property "Footprint" "Diode_THT:D_DO-35_SOD27_P2.54mm_Vertical_AnodeUp"
			(at 134.62 52.07 0)
			(effects
				(font
					(size 1.27 1.27)
				)
				(hide yes)
			)
		)
		(property "Datasheet" "~"
			(at 134.62 52.07 0)
			(effects
				(font
					(size 1.27 1.27)
				)
				(hide yes)
			)
		)
		(property "Description" ""
			(at 134.62 52.07 0)
			(effects
				(font
					(size 1.27 1.27)
				)
				(hide yes)
			)
		)
		(pin "1"
			(uuid "72db0bf2-bea2-4f45-ab60-a6279c9e684b")
		)
		(pin "2"
			(uuid "0f1f8ee2-bf57-4ce8-a94a-a670521b230b")
		)
		(instances
			(project ""
				(path "/02b1dd05-420e-48b3-9ee8-c9edbf2413ac"
					(reference "D1")
					(unit 1)
				)
			)
		)
	)
	(symbol
		(lib_id "Device:D")
		(at 134.62 69.85 270)
		(unit 1)
		(exclude_from_sim no)
		(in_bom yes)
		(on_board yes)
		(dnp no)
		(uuid "00000000-0000-0000-0000-000064cbd18f")
		(property "Reference" "D2"
			(at 134.62 67.31 90)
			(effects
				(font
					(size 1.27 1.27)
				)
				(justify left)
			)
		)
		(property "Value" "4148"
			(at 134.62 72.39 90)
			(effects
				(font
					(size 1.27 1.27)
				)
				(justify left)
			)
		)
		(property "Footprint" "Diode_THT:D_DO-35_SOD27_P2.54mm_Vertical_AnodeUp"
			(at 134.62 69.85 0)
			(effects
				(font
					(size 1.27 1.27)
				)
				(hide yes)
			)
		)
		(property "Datasheet" "~"
			(at 134.62 69.85 0)
			(effects
				(font
					(size 1.27 1.27)
				)
				(hide yes)
			)
		)
		(property "Description" ""
			(at 134.62 69.85 0)
			(effects
				(font
					(size 1.27 1.27)
				)
				(hide yes)
			)
		)
		(pin "1"
			(uuid "1eb95ac8-5d4b-4c8d-894c-b38a5229baf0")
		)
		(pin "2"
			(uuid "17ef9aca-f66a-4995-b8e2-5f27e881080b")
		)
		(instances
			(project ""
				(path "/02b1dd05-420e-48b3-9ee8-c9edbf2413ac"
					(reference "D2")
					(unit 1)
				)
			)
		)
	)
	(symbol
		(lib_id "Device:R")
		(at 195.58 57.15 0)
		(unit 1)
		(exclude_from_sim no)
		(in_bom yes)
		(on_board yes)
		(dnp no)
		(uuid "00000000-0000-0000-0000-000064cbd1ad")
		(property "Reference" "R4"
			(at 194.31 50.8 0)
			(effects
				(font
					(size 1.27 1.27)
				)
				(justify left)
			)
		)
		(property "Value" "6K8"
			(at 195.58 57.15 90)
			(effects
				(font
					(size 1.27 1.27)
				)
			)
		)
		(property "Footprint" "Resistor_THT:R_Axial_DIN0207_L6.3mm_D2.5mm_P2.54mm_Vertical"
			(at 193.802 57.15 90)
			(effects
				(font
					(size 1.27 1.27)
				)
				(hide yes)
			)
		)
		(property "Datasheet" "~"
			(at 195.58 57.15 0)
			(effects
				(font
					(size 1.27 1.27)
				)
				(hide yes)
			)
		)
		(property "Description" ""
			(at 195.58 57.15 0)
			(effects
				(font
					(size 1.27 1.27)
				)
				(hide yes)
			)
		)
		(pin "1"
			(uuid "57e22d9b-057d-4992-94f6-bdf83cfa9a73")
		)
		(pin "2"
			(uuid "f08e5ebb-9abd-4864-8a0a-84e37c6cb87e")
		)
		(instances
			(project ""
				(path "/02b1dd05-420e-48b3-9ee8-c9edbf2413ac"
					(reference "R4")
					(unit 1)
				)
			)
		)
	)
	(symbol
		(lib_id "Device:D")
		(at 201.93 57.15 270)
		(unit 1)
		(exclude_from_sim no)
		(in_bom yes)
		(on_board yes)
		(dnp no)
		(uuid "00000000-0000-0000-0000-000064cbd1b7")
		(property "Reference" "D3"
			(at 201.93 54.61 90)
			(effects
				(font
					(size 1.27 1.27)
				)
				(justify left)
			)
		)
		(property "Value" "4148"
			(at 205.74 59.69 90)
			(effects
				(font
					(size 1.27 1.27)
				)
			)
		)
		(property "Footprint" "Diode_THT:D_DO-35_SOD27_P2.54mm_Vertical_AnodeUp"
			(at 201.93 57.15 0)
			(effects
				(font
					(size 1.27 1.27)
				)
				(hide yes)
			)
		)
		(property "Datasheet" "~"
			(at 201.93 57.15 0)
			(effects
				(font
					(size 1.27 1.27)
				)
				(hide yes)
			)
		)
		(property "Description" ""
			(at 201.93 57.15 0)
			(effects
				(font
					(size 1.27 1.27)
				)
				(hide yes)
			)
		)
		(pin "1"
			(uuid "a32a626d-4323-44e7-b6ed-5a25b5630ac4")
		)
		(pin "2"
			(uuid "cd9f904d-1511-4fdf-b43f-aa7df91860d1")
		)
		(instances
			(project ""
				(path "/02b1dd05-420e-48b3-9ee8-c9edbf2413ac"
					(reference "D3")
					(unit 1)
				)
			)
		)
	)
	(symbol
		(lib_id "rtc-sd-rescue:GND-power")
		(at 128.27 55.88 0)
		(unit 1)
		(exclude_from_sim no)
		(in_bom yes)
		(on_board yes)
		(dnp no)
		(uuid "00000000-0000-0000-0000-000064cbd1cf")
		(property "Reference" "#PWR0114"
			(at 128.27 62.23 0)
			(effects
				(font
					(size 1.27 1.27)
				)
				(hide yes)
			)
		)
		(property "Value" "GND"
			(at 128.397 60.2742 0)
			(effects
				(font
					(size 1.27 1.27)
				)
			)
		)
		(property "Footprint" ""
			(at 128.27 55.88 0)
			(effects
				(font
					(size 1.27 1.27)
				)
				(hide yes)
			)
		)
		(property "Datasheet" ""
			(at 128.27 55.88 0)
			(effects
				(font
					(size 1.27 1.27)
				)
				(hide yes)
			)
		)
		(property "Description" ""
			(at 128.27 55.88 0)
			(effects
				(font
					(size 1.27 1.27)
				)
				(hide yes)
			)
		)
		(pin "1"
			(uuid "eb214364-ec55-4280-98a4-89db7f16fcc8")
		)
		(instances
			(project ""
				(path "/02b1dd05-420e-48b3-9ee8-c9edbf2413ac"
					(reference "#PWR0114")
					(unit 1)
				)
			)
		)
	)
	(symbol
		(lib_id "rtc-sd-rescue:GND-power")
		(at 128.27 73.66 0)
		(unit 1)
		(exclude_from_sim no)
		(in_bom yes)
		(on_board yes)
		(dnp no)
		(uuid "00000000-0000-0000-0000-000064cbd1d9")
		(property "Reference" "#PWR0115"
			(at 128.27 80.01 0)
			(effects
				(font
					(size 1.27 1.27)
				)
				(hide yes)
			)
		)
		(property "Value" "GND"
			(at 124.46 76.2 0)
			(effects
				(font
					(size 1.27 1.27)
				)
			)
		)
		(property "Footprint" ""
			(at 128.27 73.66 0)
			(effects
				(font
					(size 1.27 1.27)
				)
				(hide yes)
			)
		)
		(property "Datasheet" ""
			(at 128.27 73.66 0)
			(effects
				(font
					(size 1.27 1.27)
				)
				(hide yes)
			)
		)
		(property "Description" ""
			(at 128.27 73.66 0)
			(effects
				(font
					(size 1.27 1.27)
				)
				(hide yes)
			)
		)
		(pin "1"
			(uuid "44cace6c-1fdb-4e57-bbf8-0e316e31ff79")
		)
		(instances
			(project ""
				(path "/02b1dd05-420e-48b3-9ee8-c9edbf2413ac"
					(reference "#PWR0115")
					(unit 1)
				)
			)
		)
	)
	(symbol
		(lib_id "rtc-sd-rescue:GND-power")
		(at 195.58 60.96 0)
		(unit 1)
		(exclude_from_sim no)
		(in_bom yes)
		(on_board yes)
		(dnp no)
		(uuid "00000000-0000-0000-0000-000064cbd201")
		(property "Reference" "#PWR0116"
			(at 195.58 67.31 0)
			(effects
				(font
					(size 1.27 1.27)
				)
				(hide yes)
			)
		)
		(property "Value" "GND"
			(at 195.707 65.3542 0)
			(effects
				(font
					(size 1.27 1.27)
				)
			)
		)
		(property "Footprint" ""
			(at 195.58 60.96 0)
			(effects
				(font
					(size 1.27 1.27)
				)
				(hide yes)
			)
		)
		(property "Datasheet" ""
			(at 195.58 60.96 0)
			(effects
				(font
					(size 1.27 1.27)
				)
				(hide yes)
			)
		)
		(property "Description" ""
			(at 195.58 60.96 0)
			(effects
				(font
					(size 1.27 1.27)
				)
				(hide yes)
			)
		)
		(pin "1"
			(uuid "01ef9ba9-bca8-46aa-b5a4-cd56e5e7743e")
		)
		(instances
			(project ""
				(path "/02b1dd05-420e-48b3-9ee8-c9edbf2413ac"
					(reference "#PWR0116")
					(unit 1)
				)
			)
		)
	)
	(symbol
		(lib_id "rtc-sd-rescue:GND-power")
		(at 135.89 104.14 0)
		(unit 1)
		(exclude_from_sim no)
		(in_bom yes)
		(on_board yes)
		(dnp no)
		(uuid "00000000-0000-0000-0000-000064cd7290")
		(property "Reference" "#PWR0103"
			(at 135.89 110.49 0)
			(effects
				(font
					(size 1.27 1.27)
				)
				(hide yes)
			)
		)
		(property "Value" "GND"
			(at 136.017 108.5342 0)
			(effects
				(font
					(size 1.27 1.27)
				)
			)
		)
		(property "Footprint" ""
			(at 135.89 104.14 0)
			(effects
				(font
					(size 1.27 1.27)
				)
				(hide yes)
			)
		)
		(property "Datasheet" ""
			(at 135.89 104.14 0)
			(effects
				(font
					(size 1.27 1.27)
				)
				(hide yes)
			)
		)
		(property "Description" ""
			(at 135.89 104.14 0)
			(effects
				(font
					(size 1.27 1.27)
				)
				(hide yes)
			)
		)
		(pin "1"
			(uuid "c8d16fb1-61e5-4b90-9078-a9809ec0affd")
		)
		(instances
			(project ""
				(path "/02b1dd05-420e-48b3-9ee8-c9edbf2413ac"
					(reference "#PWR0103")
					(unit 1)
				)
			)
		)
	)
	(symbol
		(lib_id "rtc-sd-rescue:+5V-power")
		(at 135.89 96.52 0)
		(unit 1)
		(exclude_from_sim no)
		(in_bom yes)
		(on_board yes)
		(dnp no)
		(uuid "00000000-0000-0000-0000-000064cd7513")
		(property "Reference" "#PWR0104"
			(at 135.89 100.33 0)
			(effects
				(font
					(size 1.27 1.27)
				)
				(hide yes)
			)
		)
		(property "Value" "+5V"
			(at 138.43 96.52 0)
			(effects
				(font
					(size 1.27 1.27)
				)
			)
		)
		(property "Footprint" ""
			(at 135.89 96.52 0)
			(effects
				(font
					(size 1.27 1.27)
				)
				(hide yes)
			)
		)
		(property "Datasheet" ""
			(at 135.89 96.52 0)
			(effects
				(font
					(size 1.27 1.27)
				)
				(hide yes)
			)
		)
		(property "Description" ""
			(at 135.89 96.52 0)
			(effects
				(font
					(size 1.27 1.27)
				)
				(hide yes)
			)
		)
		(pin "1"
			(uuid "b5e5c078-7da5-4608-869c-78376a1e187e")
		)
		(instances
			(project ""
				(path "/02b1dd05-420e-48b3-9ee8-c9edbf2413ac"
					(reference "#PWR0104")
					(unit 1)
				)
			)
		)
	)
	(symbol
		(lib_id "Device:C")
		(at 156.21 153.67 0)
		(unit 1)
		(exclude_from_sim no)
		(in_bom yes)
		(on_board yes)
		(dnp no)
		(uuid "00000000-0000-0000-0000-000064cd893d")
		(property "Reference" "C1"
			(at 157.48 151.13 0)
			(effects
				(font
					(size 1.27 1.27)
				)
				(justify left)
			)
		)
		(property "Value" "22n"
			(at 157.48 156.21 0)
			(effects
				(font
					(size 1.27 1.27)
				)
				(justify left)
			)
		)
		(property "Footprint" "Capacitor_THT:C_Disc_D5.0mm_W2.5mm_P5.00mm"
			(at 157.1752 157.48 0)
			(effects
				(font
					(size 1.27 1.27)
				)
				(hide yes)
			)
		)
		(property "Datasheet" "~"
			(at 156.21 153.67 0)
			(effects
				(font
					(size 1.27 1.27)
				)
				(hide yes)
			)
		)
		(property "Description" ""
			(at 156.21 153.67 0)
			(effects
				(font
					(size 1.27 1.27)
				)
				(hide yes)
			)
		)
		(pin "1"
			(uuid "2b4e7c5b-b65e-42a0-b485-2330c4db8e2a")
		)
		(pin "2"
			(uuid "930917ee-0967-4ee0-b5b3-8c6bbe04036d")
		)
		(instances
			(project ""
				(path "/02b1dd05-420e-48b3-9ee8-c9edbf2413ac"
					(reference "C1")
					(unit 1)
				)
			)
		)
	)
	(symbol
		(lib_id "74xx:74LS132")
		(at 142.24 45.72 0)
		(unit 1)
		(exclude_from_sim no)
		(in_bom yes)
		(on_board yes)
		(dnp no)
		(uuid "00000000-0000-0000-0000-000064ce1123")
		(property "Reference" "U5"
			(at 142.24 40.64 0)
			(effects
				(font
					(size 1.27 1.27)
				)
			)
		)
		(property "Value" "74HC132"
			(at 142.24 50.8 0)
			(effects
				(font
					(size 1.27 1.27)
				)
			)
		)
		(property "Footprint" "Package_DIP:DIP-14_W7.62mm_Socket"
			(at 142.24 45.72 0)
			(effects
				(font
					(size 1.27 1.27)
				)
				(hide yes)
			)
		)
		(property "Datasheet" "http://www.ti.com/lit/gpn/sn74LS132"
			(at 142.24 45.72 0)
			(effects
				(font
					(size 1.27 1.27)
				)
				(hide yes)
			)
		)
		(property "Description" ""
			(at 142.24 45.72 0)
			(effects
				(font
					(size 1.27 1.27)
				)
				(hide yes)
			)
		)
		(pin "1"
			(uuid "37ffc0e6-1bdb-423c-aa05-31fa65980b04")
		)
		(pin "2"
			(uuid "2893d6ee-44e5-420e-82aa-c08dd9e8267b")
		)
		(pin "3"
			(uuid "2d325f0d-e816-42d8-a852-ec23b2079ef3")
		)
		(pin "4"
			(uuid "c6b14f12-721c-402d-b0b7-6794a3f9e5ef")
		)
		(pin "5"
			(uuid "e4b1da7b-986a-438e-acd7-f5cc579c2403")
		)
		(pin "6"
			(uuid "71dc320f-0646-4736-b343-dd03b0fcd6d1")
		)
		(pin "10"
			(uuid "91c0ae62-31d9-4adc-94bb-23a5fc8d5c93")
		)
		(pin "8"
			(uuid "f27b0a47-5dab-4407-9646-1d3be6d28059")
		)
		(pin "9"
			(uuid "00096e28-bf15-4532-a10d-cd7f70f35426")
		)
		(pin "11"
			(uuid "d0bd9493-a4ef-466c-8702-c20c35dd9f42")
		)
		(pin "12"
			(uuid "44b64480-1b12-4f54-92f3-6c80d3eca9e8")
		)
		(pin "13"
			(uuid "ac2de06a-da8b-4b52-897c-19580232c2c4")
		)
		(pin "14"
			(uuid "5e33641f-dee3-43ac-ab36-2d229a1c20e7")
		)
		(pin "7"
			(uuid "84c38ac4-0ce9-4618-a341-a00c465514f7")
		)
		(instances
			(project ""
				(path "/02b1dd05-420e-48b3-9ee8-c9edbf2413ac"
					(reference "U5")
					(unit 1)
				)
			)
		)
	)
	(symbol
		(lib_id "74xx:74LS132")
		(at 142.24 63.5 0)
		(unit 2)
		(exclude_from_sim no)
		(in_bom yes)
		(on_board yes)
		(dnp no)
		(uuid "00000000-0000-0000-0000-000064ce4e10")
		(property "Reference" "U5"
			(at 142.24 58.42 0)
			(effects
				(font
					(size 1.27 1.27)
				)
			)
		)
		(property "Value" "74HC132"
			(at 142.24 68.58 0)
			(effects
				(font
					(size 1.27 1.27)
				)
			)
		)
		(property "Footprint" "Package_DIP:DIP-14_W7.62mm_Socket"
			(at 142.24 63.5 0)
			(effects
				(font
					(size 1.27 1.27)
				)
				(hide yes)
			)
		)
		(property "Datasheet" "http://www.ti.com/lit/gpn/sn74LS132"
			(at 142.24 63.5 0)
			(effects
				(font
					(size 1.27 1.27)
				)
				(hide yes)
			)
		)
		(property "Description" ""
			(at 142.24 63.5 0)
			(effects
				(font
					(size 1.27 1.27)
				)
				(hide yes)
			)
		)
		(pin "1"
			(uuid "351b3bfa-9063-4729-8de3-868f6108e623")
		)
		(pin "2"
			(uuid "6449c2bb-cdef-4105-ae45-8741f6097fae")
		)
		(pin "3"
			(uuid "b872a0f4-4c88-4e46-b164-4a3cd23c94f3")
		)
		(pin "4"
			(uuid "37c9c843-e6eb-415c-a3d2-62bfed448237")
		)
		(pin "5"
			(uuid "d721ee3a-5392-402e-8fd8-8b6c8641fcae")
		)
		(pin "6"
			(uuid "e12fb516-3d59-4c31-ae47-ce76137287e4")
		)
		(pin "10"
			(uuid "1ed76e5e-5d7e-4b28-ad29-53386f3bcb0f")
		)
		(pin "8"
			(uuid "fc3060ff-77d7-43eb-9982-e8eeb0acc13b")
		)
		(pin "9"
			(uuid "f4d353ef-6c76-4dde-a124-db412aaf42e3")
		)
		(pin "11"
			(uuid "39d18770-159a-4f9a-8cb3-a82343fe11b6")
		)
		(pin "12"
			(uuid "acfc4022-9f6b-4799-aadf-d07c6549b59c")
		)
		(pin "13"
			(uuid "97951b6a-9e1f-4c9b-80cb-c7c086a86ae8")
		)
		(pin "14"
			(uuid "d33c2bf0-58a0-422f-9e47-44be6253fbc0")
		)
		(pin "7"
			(uuid "0f6a1386-f639-454b-b385-a90878430935")
		)
		(instances
			(project ""
				(path "/02b1dd05-420e-48b3-9ee8-c9edbf2413ac"
					(reference "U5")
					(unit 2)
				)
			)
		)
	)
	(symbol
		(lib_id "74xx:74LS132")
		(at 209.55 50.8 0)
		(unit 3)
		(exclude_from_sim no)
		(in_bom yes)
		(on_board yes)
		(dnp no)
		(uuid "00000000-0000-0000-0000-000064ce7c25")
		(property "Reference" "U5"
			(at 209.55 42.545 0)
			(effects
				(font
					(size 1.27 1.27)
				)
			)
		)
		(property "Value" "74HC132"
			(at 209.55 44.8564 0)
			(effects
				(font
					(size 1.27 1.27)
				)
			)
		)
		(property "Footprint" "Package_DIP:DIP-14_W7.62mm_Socket"
			(at 209.55 50.8 0)
			(effects
				(font
					(size 1.27 1.27)
				)
				(hide yes)
			)
		)
		(property "Datasheet" "http://www.ti.com/lit/gpn/sn74LS132"
			(at 209.55 50.8 0)
			(effects
				(font
					(size 1.27 1.27)
				)
				(hide yes)
			)
		)
		(property "Description" ""
			(at 209.55 50.8 0)
			(effects
				(font
					(size 1.27 1.27)
				)
				(hide yes)
			)
		)
		(pin "1"
			(uuid "8c2d2646-f83f-48a1-9525-a60e73edb289")
		)
		(pin "2"
			(uuid "4939f9f8-e261-4621-af69-86d01e87fb2d")
		)
		(pin "3"
			(uuid "2cc90cee-ac80-4977-aed0-8bc2e00385d3")
		)
		(pin "4"
			(uuid "356e8bcb-6864-40ef-a2ff-095af85ba81f")
		)
		(pin "5"
			(uuid "198c261d-95a7-4578-aebf-c8eb4bdc8e33")
		)
		(pin "6"
			(uuid "5812b9df-57ac-4551-b6c1-304851fc02f4")
		)
		(pin "10"
			(uuid "daf043c5-3fd7-457b-be98-41857e4ac963")
		)
		(pin "8"
			(uuid "8dc03093-2a8c-4484-9092-0f99a28a2041")
		)
		(pin "9"
			(uuid "8802bacb-d3d6-4ecd-a60d-ca88d98c596b")
		)
		(pin "11"
			(uuid "788ffe27-299f-473f-b176-a96ebd0f05ac")
		)
		(pin "12"
			(uuid "6ec1216a-07f1-4409-9595-47b73d8c0666")
		)
		(pin "13"
			(uuid "ade3433a-69ff-4601-9c7e-606f16e1a06a")
		)
		(pin "14"
			(uuid "c4d5b3c9-1127-47aa-971b-cf8c531448b1")
		)
		(pin "7"
			(uuid "4003f803-ca4d-4dd9-912f-5cec52a330b2")
		)
		(instances
			(project ""
				(path "/02b1dd05-420e-48b3-9ee8-c9edbf2413ac"
					(reference "U5")
					(unit 3)
				)
			)
		)
	)
	(symbol
		(lib_id "rtc-sd-rescue:+5V-power")
		(at 63.5 73.66 0)
		(unit 1)
		(exclude_from_sim no)
		(in_bom yes)
		(on_board yes)
		(dnp no)
		(uuid "00000000-0000-0000-0000-000064ce951d")
		(property "Reference" "#PWR0105"
			(at 63.5 77.47 0)
			(effects
				(font
					(size 1.27 1.27)
				)
				(hide yes)
			)
		)
		(property "Value" "+5V"
			(at 60.96 71.12 0)
			(effects
				(font
					(size 1.27 1.27)
				)
			)
		)
		(property "Footprint" ""
			(at 63.5 73.66 0)
			(effects
				(font
					(size 1.27 1.27)
				)
				(hide yes)
			)
		)
		(property "Datasheet" ""
			(at 63.5 73.66 0)
			(effects
				(font
					(size 1.27 1.27)
				)
				(hide yes)
			)
		)
		(property "Description" ""
			(at 63.5 73.66 0)
			(effects
				(font
					(size 1.27 1.27)
				)
				(hide yes)
			)
		)
		(pin "1"
			(uuid "7c7ab650-2696-494a-a817-114e8d2b12bd")
		)
		(instances
			(project ""
				(path "/02b1dd05-420e-48b3-9ee8-c9edbf2413ac"
					(reference "#PWR0105")
					(unit 1)
				)
			)
		)
	)
	(symbol
		(lib_id "rtc-sd-rescue:+5V-power")
		(at 50.8 104.14 90)
		(unit 1)
		(exclude_from_sim no)
		(in_bom yes)
		(on_board yes)
		(dnp no)
		(uuid "00000000-0000-0000-0000-000064ce9815")
		(property "Reference" "#PWR0106"
			(at 54.61 104.14 0)
			(effects
				(font
					(size 1.27 1.27)
				)
				(hide yes)
			)
		)
		(property "Value" "+5V"
			(at 48.26 102.87 90)
			(effects
				(font
					(size 1.27 1.27)
				)
				(justify left)
			)
		)
		(property "Footprint" ""
			(at 50.8 104.14 0)
			(effects
				(font
					(size 1.27 1.27)
				)
				(hide yes)
			)
		)
		(property "Datasheet" ""
			(at 50.8 104.14 0)
			(effects
				(font
					(size 1.27 1.27)
				)
				(hide yes)
			)
		)
		(property "Description" ""
			(at 50.8 104.14 0)
			(effects
				(font
					(size 1.27 1.27)
				)
				(hide yes)
			)
		)
		(pin "1"
			(uuid "d1215429-2506-4982-90d2-35553d4e76aa")
		)
		(instances
			(project ""
				(path "/02b1dd05-420e-48b3-9ee8-c9edbf2413ac"
					(reference "#PWR0106")
					(unit 1)
				)
			)
		)
	)
	(symbol
		(lib_id "rtc-sd-rescue:GND-power")
		(at 63.5 111.76 0)
		(unit 1)
		(exclude_from_sim no)
		(in_bom yes)
		(on_board yes)
		(dnp no)
		(uuid "00000000-0000-0000-0000-000064ce9be3")
		(property "Reference" "#PWR0107"
			(at 63.5 118.11 0)
			(effects
				(font
					(size 1.27 1.27)
				)
				(hide yes)
			)
		)
		(property "Value" "GND"
			(at 63.627 116.1542 0)
			(effects
				(font
					(size 1.27 1.27)
				)
			)
		)
		(property "Footprint" ""
			(at 63.5 111.76 0)
			(effects
				(font
					(size 1.27 1.27)
				)
				(hide yes)
			)
		)
		(property "Datasheet" ""
			(at 63.5 111.76 0)
			(effects
				(font
					(size 1.27 1.27)
				)
				(hide yes)
			)
		)
		(property "Description" ""
			(at 63.5 111.76 0)
			(effects
				(font
					(size 1.27 1.27)
				)
				(hide yes)
			)
		)
		(pin "1"
			(uuid "1c91485d-fd77-4438-8dff-6e3057606edb")
		)
		(instances
			(project ""
				(path "/02b1dd05-420e-48b3-9ee8-c9edbf2413ac"
					(reference "#PWR0107")
					(unit 1)
				)
			)
		)
	)
	(symbol
		(lib_id "rtc-sd-rescue:GND-power")
		(at 60.96 166.37 0)
		(unit 1)
		(exclude_from_sim no)
		(in_bom yes)
		(on_board yes)
		(dnp no)
		(uuid "00000000-0000-0000-0000-000064cec69b")
		(property "Reference" "#PWR0108"
			(at 60.96 172.72 0)
			(effects
				(font
					(size 1.27 1.27)
				)
				(hide yes)
			)
		)
		(property "Value" "GND"
			(at 61.087 170.7642 0)
			(effects
				(font
					(size 1.27 1.27)
				)
			)
		)
		(property "Footprint" ""
			(at 60.96 166.37 0)
			(effects
				(font
					(size 1.27 1.27)
				)
				(hide yes)
			)
		)
		(property "Datasheet" ""
			(at 60.96 166.37 0)
			(effects
				(font
					(size 1.27 1.27)
				)
				(hide yes)
			)
		)
		(property "Description" ""
			(at 60.96 166.37 0)
			(effects
				(font
					(size 1.27 1.27)
				)
				(hide yes)
			)
		)
		(pin "1"
			(uuid "91c875f4-d0eb-4895-95bc-e9097ba1039e")
		)
		(instances
			(project ""
				(path "/02b1dd05-420e-48b3-9ee8-c9edbf2413ac"
					(reference "#PWR0108")
					(unit 1)
				)
			)
		)
	)
	(symbol
		(lib_id "rtc-sd-rescue:PWR_FLAG-power")
		(at 156.21 140.97 0)
		(unit 1)
		(exclude_from_sim no)
		(in_bom yes)
		(on_board yes)
		(dnp no)
		(uuid "00000000-0000-0000-0000-000064cec9b0")
		(property "Reference" "#FLG0101"
			(at 156.21 139.065 0)
			(effects
				(font
					(size 1.27 1.27)
				)
				(hide yes)
			)
		)
		(property "Value" "PWR_FLAG"
			(at 156.21 136.5758 0)
			(effects
				(font
					(size 1.27 1.27)
				)
			)
		)
		(property "Footprint" ""
			(at 156.21 140.97 0)
			(effects
				(font
					(size 1.27 1.27)
				)
				(hide yes)
			)
		)
		(property "Datasheet" "~"
			(at 156.21 140.97 0)
			(effects
				(font
					(size 1.27 1.27)
				)
				(hide yes)
			)
		)
		(property "Description" ""
			(at 156.21 140.97 0)
			(effects
				(font
					(size 1.27 1.27)
				)
				(hide yes)
			)
		)
		(pin "1"
			(uuid "1ea67113-2d12-47ba-9d81-af7d7013eee2")
		)
		(instances
			(project ""
				(path "/02b1dd05-420e-48b3-9ee8-c9edbf2413ac"
					(reference "#FLG0101")
					(unit 1)
				)
			)
		)
	)
	(symbol
		(lib_id "rtc-sd-rescue:PWR_FLAG-power")
		(at 156.21 166.37 180)
		(unit 1)
		(exclude_from_sim no)
		(in_bom yes)
		(on_board yes)
		(dnp no)
		(uuid "00000000-0000-0000-0000-000064cecc20")
		(property "Reference" "#FLG0102"
			(at 156.21 168.275 0)
			(effects
				(font
					(size 1.27 1.27)
				)
				(hide yes)
			)
		)
		(property "Value" "PWR_FLAG"
			(at 156.21 170.7642 0)
			(effects
				(font
					(size 1.27 1.27)
				)
			)
		)
		(property "Footprint" ""
			(at 156.21 166.37 0)
			(effects
				(font
					(size 1.27 1.27)
				)
				(hide yes)
			)
		)
		(property "Datasheet" "~"
			(at 156.21 166.37 0)
			(effects
				(font
					(size 1.27 1.27)
				)
				(hide yes)
			)
		)
		(property "Description" ""
			(at 156.21 166.37 0)
			(effects
				(font
					(size 1.27 1.27)
				)
				(hide yes)
			)
		)
		(pin "1"
			(uuid "274635c5-ef6b-41b4-a905-0709d724a926")
		)
		(instances
			(project ""
				(path "/02b1dd05-420e-48b3-9ee8-c9edbf2413ac"
					(reference "#FLG0102")
					(unit 1)
				)
			)
		)
	)
	(symbol
		(lib_id "74xx:74LS132")
		(at 165.1 60.96 0)
		(unit 4)
		(exclude_from_sim no)
		(in_bom yes)
		(on_board yes)
		(dnp no)
		(uuid "00000000-0000-0000-0000-000064cf0a17")
		(property "Reference" "U5"
			(at 165.1 52.705 0)
			(effects
				(font
					(size 1.27 1.27)
				)
			)
		)
		(property "Value" "74HC132"
			(at 165.1 55.0164 0)
			(effects
				(font
					(size 1.27 1.27)
				)
			)
		)
		(property "Footprint" "Package_DIP:DIP-14_W7.62mm_Socket"
			(at 165.1 60.96 0)
			(effects
				(font
					(size 1.27 1.27)
				)
				(hide yes)
			)
		)
		(property "Datasheet" "http://www.ti.com/lit/gpn/sn74LS132"
			(at 165.1 60.96 0)
			(effects
				(font
					(size 1.27 1.27)
				)
				(hide yes)
			)
		)
		(property "Description" ""
			(at 165.1 60.96 0)
			(effects
				(font
					(size 1.27 1.27)
				)
				(hide yes)
			)
		)
		(pin "1"
			(uuid "76b205ec-8cf5-495d-990b-b2956080991b")
		)
		(pin "2"
			(uuid "e8cd0eb5-2b5f-41c0-8475-d2a484831deb")
		)
		(pin "3"
			(uuid "fdce91c2-f9b5-4622-af72-adb49bf8c91e")
		)
		(pin "4"
			(uuid "c7e529a7-6467-4afa-9559-5a3ebe79e173")
		)
		(pin "5"
			(uuid "5287233a-9bfb-41c5-adfd-75c1d0dc8c4c")
		)
		(pin "6"
			(uuid "30878120-123a-4f2f-919d-ab8ce59a698d")
		)
		(pin "10"
			(uuid "75e67a04-db15-4e85-a45d-a7c113267c04")
		)
		(pin "8"
			(uuid "b4107856-fb7c-46f1-892b-26947aed45fe")
		)
		(pin "9"
			(uuid "2b76e9de-afdb-4d09-a26e-66edf543a7a9")
		)
		(pin "11"
			(uuid "2b11a3c1-6d29-4215-9598-8a462e254419")
		)
		(pin "12"
			(uuid "e5ecf8f5-8e5c-40aa-9820-65096eccf991")
		)
		(pin "13"
			(uuid "dd178352-3a07-464b-8867-77505e493896")
		)
		(pin "14"
			(uuid "9c66ca3d-b25b-480f-a570-157d55c35a0e")
		)
		(pin "7"
			(uuid "bc160436-89a6-42c2-bb29-b7b699736b7b")
		)
		(instances
			(project ""
				(path "/02b1dd05-420e-48b3-9ee8-c9edbf2413ac"
					(reference "U5")
					(unit 4)
				)
			)
		)
	)
	(symbol
		(lib_id "rtc-sd-rescue:+5V-power")
		(at 115.57 118.11 0)
		(unit 1)
		(exclude_from_sim no)
		(in_bom yes)
		(on_board yes)
		(dnp no)
		(uuid "00000000-0000-0000-0000-000064cfd0dc")
		(property "Reference" "#PWR0109"
			(at 115.57 121.92 0)
			(effects
				(font
					(size 1.27 1.27)
				)
				(hide yes)
			)
		)
		(property "Value" "+5V"
			(at 118.11 116.84 0)
			(effects
				(font
					(size 1.27 1.27)
				)
			)
		)
		(property "Footprint" ""
			(at 115.57 118.11 0)
			(effects
				(font
					(size 1.27 1.27)
				)
				(hide yes)
			)
		)
		(property "Datasheet" ""
			(at 115.57 118.11 0)
			(effects
				(font
					(size 1.27 1.27)
				)
				(hide yes)
			)
		)
		(property "Description" ""
			(at 115.57 118.11 0)
			(effects
				(font
					(size 1.27 1.27)
				)
				(hide yes)
			)
		)
		(pin "1"
			(uuid "b899778a-a9a9-4582-990b-9faf16e432e7")
		)
		(instances
			(project ""
				(path "/02b1dd05-420e-48b3-9ee8-c9edbf2413ac"
					(reference "#PWR0109")
					(unit 1)
				)
			)
		)
	)
	(symbol
		(lib_id "rtc-sd-rescue:2N7000-dk_Transistors-FETs-MOSFETs-Single")
		(at 180.34 58.42 0)
		(unit 1)
		(exclude_from_sim no)
		(in_bom yes)
		(on_board yes)
		(dnp no)
		(uuid "00000000-0000-0000-0000-000064d132a2")
		(property "Reference" "Q1"
			(at 183.0832 57.0738 0)
			(effects
				(font
					(size 1.524 1.524)
				)
				(justify left)
			)
		)
		(property "Value" "2N7000"
			(at 183.0832 59.7662 0)
			(effects
				(font
					(size 1.524 1.524)
				)
				(justify left)
			)
		)
		(property "Footprint" "digikey-footprints:TO-92-3"
			(at 185.42 53.34 0)
			(effects
				(font
					(size 1.524 1.524)
				)
				(justify left)
				(hide yes)
			)
		)
		(property "Datasheet" "https://www.onsemi.com/pub/Collateral/NDS7002A-D.PDF"
			(at 185.42 50.8 0)
			(effects
				(font
					(size 1.524 1.524)
				)
				(justify left)
				(hide yes)
			)
		)
		(property "Description" ""
			(at 180.34 58.42 0)
			(effects
				(font
					(size 1.27 1.27)
				)
				(hide yes)
			)
		)
		(property "Digi-Key_PN" "2N7000FS-ND"
			(at 185.42 48.26 0)
			(effects
				(font
					(size 1.524 1.524)
				)
				(justify left)
				(hide yes)
			)
		)
		(property "MPN" "2N7000"
			(at 185.42 45.72 0)
			(effects
				(font
					(size 1.524 1.524)
				)
				(justify left)
				(hide yes)
			)
		)
		(property "Category" "Discrete Semiconductor Products"
			(at 185.42 43.18 0)
			(effects
				(font
					(size 1.524 1.524)
				)
				(justify left)
				(hide yes)
			)
		)
		(property "Family" "Transistors - FETs, MOSFETs - Single"
			(at 185.42 40.64 0)
			(effects
				(font
					(size 1.524 1.524)
				)
				(justify left)
				(hide yes)
			)
		)
		(property "DK_Datasheet_Link" "https://www.onsemi.com/pub/Collateral/NDS7002A-D.PDF"
			(at 185.42 38.1 0)
			(effects
				(font
					(size 1.524 1.524)
				)
				(justify left)
				(hide yes)
			)
		)
		(property "DK_Detail_Page" "/product-detail/en/on-semiconductor/2N7000/2N7000FS-ND/244278"
			(at 185.42 35.56 0)
			(effects
				(font
					(size 1.524 1.524)
				)
				(justify left)
				(hide yes)
			)
		)
		(property "Description" "MOSFET N-CH 60V 200MA TO-92"
			(at 185.42 33.02 0)
			(effects
				(font
					(size 1.524 1.524)
				)
				(justify left)
				(hide yes)
			)
		)
		(property "Manufacturer" "ON Semiconductor"
			(at 185.42 30.48 0)
			(effects
				(font
					(size 1.524 1.524)
				)
				(justify left)
				(hide yes)
			)
		)
		(property "Status" "Active"
			(at 185.42 27.94 0)
			(effects
				(font
					(size 1.524 1.524)
				)
				(justify left)
				(hide yes)
			)
		)
		(pin "1"
			(uuid "15508716-1df1-4a7f-863f-312425fc8192")
		)
		(pin "2"
			(uuid "35eb6977-549d-48aa-b4e8-5054b8baaa8a")
		)
		(pin "3"
			(uuid "1a1cf4b3-b6df-437c-bff6-ec949f3d4261")
		)
		(instances
			(project ""
				(path "/02b1dd05-420e-48b3-9ee8-c9edbf2413ac"
					(reference "Q1")
					(unit 1)
				)
			)
		)
	)
	(symbol
		(lib_id "rtc-sd-rescue:GND-power")
		(at 180.34 63.5 0)
		(unit 1)
		(exclude_from_sim no)
		(in_bom yes)
		(on_board yes)
		(dnp no)
		(uuid "00000000-0000-0000-0000-000064d1fe00")
		(property "Reference" "#PWR0117"
			(at 180.34 69.85 0)
			(effects
				(font
					(size 1.27 1.27)
				)
				(hide yes)
			)
		)
		(property "Value" "GND"
			(at 180.467 67.8942 0)
			(effects
				(font
					(size 1.27 1.27)
				)
			)
		)
		(property "Footprint" ""
			(at 180.34 63.5 0)
			(effects
				(font
					(size 1.27 1.27)
				)
				(hide yes)
			)
		)
		(property "Datasheet" ""
			(at 180.34 63.5 0)
			(effects
				(font
					(size 1.27 1.27)
				)
				(hide yes)
			)
		)
		(property "Description" ""
			(at 180.34 63.5 0)
			(effects
				(font
					(size 1.27 1.27)
				)
				(hide yes)
			)
		)
		(pin "1"
			(uuid "1328dc48-6d2e-4544-b84a-ac309da5ff20")
		)
		(instances
			(project ""
				(path "/02b1dd05-420e-48b3-9ee8-c9edbf2413ac"
					(reference "#PWR0117")
					(unit 1)
				)
			)
		)
	)
	(symbol
		(lib_id "Device:R")
		(at 180.34 49.53 0)
		(unit 1)
		(exclude_from_sim no)
		(in_bom yes)
		(on_board yes)
		(dnp no)
		(uuid "00000000-0000-0000-0000-000064d21b4a")
		(property "Reference" "R1"
			(at 175.26 49.53 0)
			(effects
				(font
					(size 1.27 1.27)
				)
				(justify left)
			)
		)
		(property "Value" "1K2"
			(at 180.34 49.53 90)
			(effects
				(font
					(size 1.27 1.27)
				)
			)
		)
		(property "Footprint" "Resistor_THT:R_Axial_DIN0207_L6.3mm_D2.5mm_P2.54mm_Vertical"
			(at 178.562 49.53 90)
			(effects
				(font
					(size 1.27 1.27)
				)
				(hide yes)
			)
		)
		(property "Datasheet" "~"
			(at 180.34 49.53 0)
			(effects
				(font
					(size 1.27 1.27)
				)
				(hide yes)
			)
		)
		(property "Description" ""
			(at 180.34 49.53 0)
			(effects
				(font
					(size 1.27 1.27)
				)
				(hide yes)
			)
		)
		(pin "1"
			(uuid "f144ef6d-b0dd-40f2-8371-6a29b1976c61")
		)
		(pin "2"
			(uuid "4ab789ca-1e98-4ebb-b7a8-8c77ff9d1d49")
		)
		(instances
			(project ""
				(path "/02b1dd05-420e-48b3-9ee8-c9edbf2413ac"
					(reference "R1")
					(unit 1)
				)
			)
		)
	)
	(symbol
		(lib_id "rtc-sd-rescue:+5V-power")
		(at 180.34 45.72 0)
		(unit 1)
		(exclude_from_sim no)
		(in_bom yes)
		(on_board yes)
		(dnp no)
		(uuid "00000000-0000-0000-0000-000064d2370d")
		(property "Reference" "#PWR0118"
			(at 180.34 49.53 0)
			(effects
				(font
					(size 1.27 1.27)
				)
				(hide yes)
			)
		)
		(property "Value" "+5V"
			(at 180.721 41.3258 0)
			(effects
				(font
					(size 1.27 1.27)
				)
			)
		)
		(property "Footprint" ""
			(at 180.34 45.72 0)
			(effects
				(font
					(size 1.27 1.27)
				)
				(hide yes)
			)
		)
		(property "Datasheet" ""
			(at 180.34 45.72 0)
			(effects
				(font
					(size 1.27 1.27)
				)
				(hide yes)
			)
		)
		(property "Description" ""
			(at 180.34 45.72 0)
			(effects
				(font
					(size 1.27 1.27)
				)
				(hide yes)
			)
		)
		(pin "1"
			(uuid "6f2a98f8-1778-45c5-b992-4b478b7f6eed")
		)
		(instances
			(project ""
				(path "/02b1dd05-420e-48b3-9ee8-c9edbf2413ac"
					(reference "#PWR0118")
					(unit 1)
				)
			)
		)
	)
	(symbol
		(lib_id "Graphic:Logo_Open_Hardware_Small")
		(at 85.09 181.61 0)
		(unit 1)
		(exclude_from_sim no)
		(in_bom yes)
		(on_board yes)
		(dnp no)
		(uuid "00000000-0000-0000-0000-000064d370d2")
		(property "Reference" "LOGO1"
			(at 85.09 174.625 0)
			(effects
				(font
					(size 1.27 1.27)
				)
				(hide yes)
			)
		)
		(property "Value" "Logo_Open_Hardware_Small"
			(at 85.09 187.325 0)
			(effects
				(font
					(size 1.27 1.27)
				)
				(hide yes)
			)
		)
		(property "Footprint" "durango:j300"
			(at 85.09 181.61 0)
			(effects
				(font
					(size 1.27 1.27)
				)
				(hide yes)
			)
		)
		(property "Datasheet" "~"
			(at 85.09 181.61 0)
			(effects
				(font
					(size 1.27 1.27)
				)
				(hide yes)
			)
		)
		(property "Description" ""
			(at 85.09 181.61 0)
			(effects
				(font
					(size 1.27 1.27)
				)
				(hide yes)
			)
		)
		(instances
			(project ""
				(path "/02b1dd05-420e-48b3-9ee8-c9edbf2413ac"
					(reference "LOGO1")
					(unit 1)
				)
			)
		)
	)
	(symbol
		(lib_id "74xx:74LS132")
		(at 133.35 153.67 0)
		(unit 5)
		(exclude_from_sim no)
		(in_bom yes)
		(on_board yes)
		(dnp no)
		(uuid "00000000-0000-0000-0000-000064d67236")
		(property "Reference" "U5"
			(at 139.192 152.5016 0)
			(effects
				(font
					(size 1.27 1.27)
				)
				(justify left)
			)
		)
		(property "Value" "74HC132"
			(at 139.192 154.813 0)
			(effects
				(font
					(size 1.27 1.27)
				)
				(justify left)
			)
		)
		(property "Footprint" "Package_DIP:DIP-14_W7.62mm_Socket"
			(at 133.35 153.67 0)
			(effects
				(font
					(size 1.27 1.27)
				)
				(hide yes)
			)
		)
		(property "Datasheet" "http://www.ti.com/lit/gpn/sn74LS132"
			(at 133.35 153.67 0)
			(effects
				(font
					(size 1.27 1.27)
				)
				(hide yes)
			)
		)
		(property "Description" ""
			(at 133.35 153.67 0)
			(effects
				(font
					(size 1.27 1.27)
				)
				(hide yes)
			)
		)
		(pin "1"
			(uuid "0d9510f8-0d11-42b2-b224-cd4d79b6b74f")
		)
		(pin "2"
			(uuid "45725a75-711d-47a6-8193-b68ec9209aef")
		)
		(pin "3"
			(uuid "df30b8f1-01e7-4ed8-b0dc-18b89a280f91")
		)
		(pin "4"
			(uuid "b2670d25-f497-4644-996e-978bef62211a")
		)
		(pin "5"
			(uuid "bd7eba0d-98d9-4f87-b354-e80a3132d17f")
		)
		(pin "6"
			(uuid "1cea8a3a-6db9-41ef-9c06-0ba3cd18ae7b")
		)
		(pin "10"
			(uuid "ffe39568-b4f7-4aa4-b1ef-d8cac012d34d")
		)
		(pin "8"
			(uuid "3d6114fd-d77f-415a-ae08-dc9768a122c4")
		)
		(pin "9"
			(uuid "1de6dfe6-49b0-4f51-8a2b-03a055922496")
		)
		(pin "11"
			(uuid "9841e047-bc60-4349-9dfe-4860eab35e95")
		)
		(pin "12"
			(uuid "604d8bc0-ac4c-4bc5-a16e-f7207cc9e512")
		)
		(pin "13"
			(uuid "9481eeca-0547-488f-8da5-b7487cdc4184")
		)
		(pin "14"
			(uuid "fa88bcee-f31e-4e29-a47c-c2fc12d08eec")
		)
		(pin "7"
			(uuid "5bfcebc2-fb33-473c-bf44-83132b0b0349")
		)
		(instances
			(project ""
				(path "/02b1dd05-420e-48b3-9ee8-c9edbf2413ac"
					(reference "U5")
					(unit 5)
				)
			)
		)
	)
	(symbol
		(lib_id "Connector_Generic:Conn_02x03_Odd_Even")
		(at 153.67 100.33 0)
		(unit 1)
		(exclude_from_sim no)
		(in_bom yes)
		(on_board yes)
		(dnp no)
		(uuid "00000000-0000-0000-0000-000064db05f1")
		(property "Reference" "J3"
			(at 154.94 95.25 0)
			(effects
				(font
					(size 1.27 1.27)
				)
			)
		)
		(property "Value" "SPI 1"
			(at 154.94 105.41 0)
			(effects
				(font
					(size 1.27 1.27)
				)
			)
		)
		(property "Footprint" "Connector_IDC:IDC-Header_2x03_P2.54mm_Vertical"
			(at 153.67 100.33 0)
			(effects
				(font
					(size 1.27 1.27)
				)
				(hide yes)
			)
		)
		(property "Datasheet" "~"
			(at 153.67 100.33 0)
			(effects
				(font
					(size 1.27 1.27)
				)
				(hide yes)
			)
		)
		(property "Description" ""
			(at 153.67 100.33 0)
			(effects
				(font
					(size 1.27 1.27)
				)
				(hide yes)
			)
		)
		(pin "1"
			(uuid "4d8845b3-1640-4cb7-bd00-1801b3fcc33a")
		)
		(pin "2"
			(uuid "b10f2da0-0050-4a8c-afea-3b763b196473")
		)
		(pin "3"
			(uuid "2272cc23-ec07-4d27-8071-a083ed00c53e")
		)
		(pin "4"
			(uuid "1c784b29-b4a8-49dd-9ffc-a7ee3a5a8f9c")
		)
		(pin "5"
			(uuid "32029e30-11ca-452a-8f27-b06f159f2009")
		)
		(pin "6"
			(uuid "d0611fef-9d03-4ef9-bf55-663aac1e4bad")
		)
		(instances
			(project ""
				(path "/02b1dd05-420e-48b3-9ee8-c9edbf2413ac"
					(reference "J3")
					(unit 1)
				)
			)
		)
	)
	(symbol
		(lib_id "rtc-sd-rescue:GND-power")
		(at 161.29 104.14 0)
		(unit 1)
		(exclude_from_sim no)
		(in_bom yes)
		(on_board yes)
		(dnp no)
		(uuid "00000000-0000-0000-0000-000064db05fc")
		(property "Reference" "#PWR0110"
			(at 161.29 110.49 0)
			(effects
				(font
					(size 1.27 1.27)
				)
				(hide yes)
			)
		)
		(property "Value" "GND"
			(at 161.417 108.5342 0)
			(effects
				(font
					(size 1.27 1.27)
				)
			)
		)
		(property "Footprint" ""
			(at 161.29 104.14 0)
			(effects
				(font
					(size 1.27 1.27)
				)
				(hide yes)
			)
		)
		(property "Datasheet" ""
			(at 161.29 104.14 0)
			(effects
				(font
					(size 1.27 1.27)
				)
				(hide yes)
			)
		)
		(property "Description" ""
			(at 161.29 104.14 0)
			(effects
				(font
					(size 1.27 1.27)
				)
				(hide yes)
			)
		)
		(pin "1"
			(uuid "8fdaa3cf-5975-4d01-ab83-5286d2617ed1")
		)
		(instances
			(project ""
				(path "/02b1dd05-420e-48b3-9ee8-c9edbf2413ac"
					(reference "#PWR0110")
					(unit 1)
				)
			)
		)
	)
	(symbol
		(lib_id "rtc-sd-rescue:+5V-power")
		(at 161.29 96.52 0)
		(unit 1)
		(exclude_from_sim no)
		(in_bom yes)
		(on_board yes)
		(dnp no)
		(uuid "00000000-0000-0000-0000-000064db0606")
		(property "Reference" "#PWR0111"
			(at 161.29 100.33 0)
			(effects
				(font
					(size 1.27 1.27)
				)
				(hide yes)
			)
		)
		(property "Value" "+5V"
			(at 163.83 96.52 0)
			(effects
				(font
					(size 1.27 1.27)
				)
			)
		)
		(property "Footprint" ""
			(at 161.29 96.52 0)
			(effects
				(font
					(size 1.27 1.27)
				)
				(hide yes)
			)
		)
		(property "Datasheet" ""
			(at 161.29 96.52 0)
			(effects
				(font
					(size 1.27 1.27)
				)
				(hide yes)
			)
		)
		(property "Description" ""
			(at 161.29 96.52 0)
			(effects
				(font
					(size 1.27 1.27)
				)
				(hide yes)
			)
		)
		(pin "1"
			(uuid "33263d9b-71a5-40e7-960d-1e9b0b7a7abc")
		)
		(instances
			(project ""
				(path "/02b1dd05-420e-48b3-9ee8-c9edbf2413ac"
					(reference "#PWR0111")
					(unit 1)
				)
			)
		)
	)
	(symbol
		(lib_id "Device:R")
		(at 224.79 134.62 90)
		(unit 1)
		(exclude_from_sim no)
		(in_bom yes)
		(on_board yes)
		(dnp no)
		(uuid "00000000-0000-0000-0000-000065385903")
		(property "Reference" "R6"
			(at 224.79 132.08 90)
			(effects
				(font
					(size 1.27 1.27)
				)
				(justify left)
			)
		)
		(property "Value" "3K3"
			(at 224.79 134.62 90)
			(effects
				(font
					(size 1.27 1.27)
				)
			)
		)
		(property "Footprint" "Resistor_THT:R_Axial_DIN0207_L6.3mm_D2.5mm_P2.54mm_Vertical"
			(at 224.79 136.398 90)
			(effects
				(font
					(size 1.27 1.27)
				)
				(hide yes)
			)
		)
		(property "Datasheet" "~"
			(at 224.79 134.62 0)
			(effects
				(font
					(size 1.27 1.27)
				)
				(hide yes)
			)
		)
		(property "Description" ""
			(at 224.79 134.62 0)
			(effects
				(font
					(size 1.27 1.27)
				)
				(hide yes)
			)
		)
		(pin "1"
			(uuid "817a703e-4f93-4986-9e81-496cc8542c4c")
		)
		(pin "2"
			(uuid "2495952b-7278-4f6d-8b61-dc1b2003beae")
		)
		(instances
			(project ""
				(path "/02b1dd05-420e-48b3-9ee8-c9edbf2413ac"
					(reference "R6")
					(unit 1)
				)
			)
		)
	)
	(symbol
		(lib_id "Device:R")
		(at 224.79 144.78 90)
		(unit 1)
		(exclude_from_sim no)
		(in_bom yes)
		(on_board yes)
		(dnp no)
		(uuid "00000000-0000-0000-0000-00006538f9d6")
		(property "Reference" "R7"
			(at 224.79 142.24 90)
			(effects
				(font
					(size 1.27 1.27)
				)
				(justify left)
			)
		)
		(property "Value" "3K3"
			(at 224.79 144.78 90)
			(effects
				(font
					(size 1.27 1.27)
				)
			)
		)
		(property "Footprint" "Resistor_THT:R_Axial_DIN0207_L6.3mm_D2.5mm_P2.54mm_Vertical"
			(at 224.79 146.558 90)
			(effects
				(font
					(size 1.27 1.27)
				)
				(hide yes)
			)
		)
		(property "Datasheet" "~"
			(at 224.79 144.78 0)
			(effects
				(font
					(size 1.27 1.27)
				)
				(hide yes)
			)
		)
		(property "Description" ""
			(at 224.79 144.78 0)
			(effects
				(font
					(size 1.27 1.27)
				)
				(hide yes)
			)
		)
		(pin "1"
			(uuid "aadab6bb-b5a3-4672-8640-e7a5fd2611ae")
		)
		(pin "2"
			(uuid "b9eed1af-9023-453b-a0e0-a0786e4d27da")
		)
		(instances
			(project ""
				(path "/02b1dd05-420e-48b3-9ee8-c9edbf2413ac"
					(reference "R7")
					(unit 1)
				)
			)
		)
	)
	(symbol
		(lib_id "Device:D")
		(at 232.41 130.81 270)
		(unit 1)
		(exclude_from_sim no)
		(in_bom yes)
		(on_board yes)
		(dnp no)
		(uuid "00000000-0000-0000-0000-00006539468c")
		(property "Reference" "D4"
			(at 229.87 133.35 90)
			(effects
				(font
					(size 1.27 1.27)
				)
				(justify left)
			)
		)
		(property "Value" "BAT85"
			(at 232.41 128.524 90)
			(effects
				(font
					(size 1.27 1.27)
				)
				(justify left)
			)
		)
		(property "Footprint" "Diode_THT:D_DO-35_SOD27_P2.54mm_Vertical_KathodeUp"
			(at 232.41 130.81 0)
			(effects
				(font
					(size 1.27 1.27)
				)
				(hide yes)
			)
		)
		(property "Datasheet" "~"
			(at 232.41 130.81 0)
			(effects
				(font
					(size 1.27 1.27)
				)
				(hide yes)
			)
		)
		(property "Description" ""
			(at 232.41 130.81 0)
			(effects
				(font
					(size 1.27 1.27)
				)
				(hide yes)
			)
		)
		(pin "1"
			(uuid "f9bd3dfe-f8b7-48cc-ad67-5119f6db849d")
		)
		(pin "2"
			(uuid "20d65068-b228-41cf-ba1e-45825566d2ef")
		)
		(instances
			(project ""
				(path "/02b1dd05-420e-48b3-9ee8-c9edbf2413ac"
					(reference "D4")
					(unit 1)
				)
			)
		)
	)
	(symbol
		(lib_id "Device:D")
		(at 229.87 140.97 270)
		(unit 1)
		(exclude_from_sim no)
		(in_bom yes)
		(on_board yes)
		(dnp no)
		(uuid "00000000-0000-0000-0000-000065396ea4")
		(property "Reference" "D5"
			(at 227.33 143.51 90)
			(effects
				(font
					(size 1.27 1.27)
				)
				(justify left)
			)
		)
		(property "Value" "BAT85"
			(at 223.774 138.684 90)
			(effects
				(font
					(size 1.27 1.27)
				)
				(justify left)
			)
		)
		(property "Footprint" "Diode_THT:D_DO-35_SOD27_P2.54mm_Vertical_KathodeUp"
			(at 229.87 140.97 0)
			(effects
				(font
					(size 1.27 1.27)
				)
				(hide yes)
			)
		)
		(property "Datasheet" "~"
			(at 229.87 140.97 0)
			(effects
				(font
					(size 1.27 1.27)
				)
				(hide yes)
			)
		)
		(property "Description" ""
			(at 229.87 140.97 0)
			(effects
				(font
					(size 1.27 1.27)
				)
				(hide yes)
			)
		)
		(pin "1"
			(uuid "3fbe9998-5326-422a-9ac4-e9c62ad166f9")
		)
		(pin "2"
			(uuid "e52dc93a-2631-408f-a488-b6685035f681")
		)
		(instances
			(project ""
				(path "/02b1dd05-420e-48b3-9ee8-c9edbf2413ac"
					(reference "D5")
					(unit 1)
				)
			)
		)
	)
	(symbol
		(lib_id "Connector_Generic:Conn_01x05")
		(at 229.87 154.94 270)
		(unit 1)
		(exclude_from_sim no)
		(in_bom yes)
		(on_board yes)
		(dnp no)
		(uuid "00000000-0000-0000-0000-0000653994e9")
		(property "Reference" "J6"
			(at 220.98 154.94 90)
			(effects
				(font
					(size 1.27 1.27)
				)
				(justify left)
			)
		)
		(property "Value" "I2C"
			(at 228.6 157.48 90)
			(effects
				(font
					(size 1.27 1.27)
				)
				(justify left)
			)
		)
		(property "Footprint" "Connector_PinHeader_2.54mm:PinHeader_1x05_P2.54mm_Horizontal"
			(at 229.87 154.94 0)
			(effects
				(font
					(size 1.27 1.27)
				)
				(hide yes)
			)
		)
		(property "Datasheet" "~"
			(at 229.87 154.94 0)
			(effects
				(font
					(size 1.27 1.27)
				)
				(hide yes)
			)
		)
		(property "Description" ""
			(at 229.87 154.94 0)
			(effects
				(font
					(size 1.27 1.27)
				)
				(hide yes)
			)
		)
		(pin "1"
			(uuid "77475e9d-117a-46b2-8607-df695d7e1213")
		)
		(pin "2"
			(uuid "6ff7e4b6-5f0a-4f70-a050-321850ddd436")
		)
		(pin "3"
			(uuid "898b881f-1ff8-49b8-a522-2abbacdfc32e")
		)
		(pin "4"
			(uuid "f6e66a09-29b7-49ab-9190-f0ac64251c8d")
		)
		(pin "5"
			(uuid "2c7627c6-4438-4b93-a27b-175520518572")
		)
		(instances
			(project ""
				(path "/02b1dd05-420e-48b3-9ee8-c9edbf2413ac"
					(reference "J6")
					(unit 1)
				)
			)
		)
	)
	(symbol
		(lib_id "74xx:74HC245")
		(at 261.62 139.7 0)
		(unit 1)
		(exclude_from_sim no)
		(in_bom yes)
		(on_board yes)
		(dnp no)
		(uuid "00000000-0000-0000-0000-00006548ba9d")
		(property "Reference" "U6"
			(at 256.54 123.19 0)
			(effects
				(font
					(size 1.27 1.27)
				)
			)
		)
		(property "Value" "74HC245"
			(at 266.7 123.19 0)
			(effects
				(font
					(size 1.27 1.27)
				)
			)
		)
		(property "Footprint" "Package_DIP:DIP-20_W7.62mm_Socket"
			(at 261.62 139.7 0)
			(effects
				(font
					(size 1.27 1.27)
				)
				(hide yes)
			)
		)
		(property "Datasheet" "http://www.ti.com/lit/gpn/sn74HC245"
			(at 261.62 139.7 0)
			(effects
				(font
					(size 1.27 1.27)
				)
				(hide yes)
			)
		)
		(property "Description" ""
			(at 261.62 139.7 0)
			(effects
				(font
					(size 1.27 1.27)
				)
				(hide yes)
			)
		)
		(pin "1"
			(uuid "f5493c21-8656-4a2e-976a-9795b0b9ed49")
		)
		(pin "10"
			(uuid "ebd0a73f-37e4-42b4-8804-0afaeaf215dc")
		)
		(pin "11"
			(uuid "e0e6c033-fe6a-4ffc-898a-2a0730f0262e")
		)
		(pin "12"
			(uuid "f9b75529-2ec7-4832-ae64-ee167600a21a")
		)
		(pin "13"
			(uuid "4361ff9b-ae11-4067-b162-1b94ed453381")
		)
		(pin "14"
			(uuid "3078327e-a707-4d3a-9fba-1e128d228e8a")
		)
		(pin "15"
			(uuid "3b58f3d1-de92-42a4-9052-66445808cfe3")
		)
		(pin "16"
			(uuid "17c97eff-0062-42e1-b293-41699814f14c")
		)
		(pin "17"
			(uuid "52d226e5-bc17-41d7-a5ef-3ecb015737e2")
		)
		(pin "18"
			(uuid "619a1b8d-fa8f-45a2-aa93-7a2fb2f84b9a")
		)
		(pin "19"
			(uuid "c8a6e240-b5ca-42b2-831f-c6df6f9b7b5a")
		)
		(pin "2"
			(uuid "4a8084c9-f90e-4da7-85bd-ffae32f05fa3")
		)
		(pin "20"
			(uuid "d79cff64-3560-4bf2-91aa-f62f504951f5")
		)
		(pin "3"
			(uuid "e1bb094d-69f0-4723-9fdb-55751f7a2d72")
		)
		(pin "4"
			(uuid "bda60543-a666-49d2-8cb7-51d9517fb633")
		)
		(pin "5"
			(uuid "9bb8b963-ad46-4266-81d6-14d4b335802d")
		)
		(pin "6"
			(uuid "3d607542-a37b-4972-8c55-4269b0254230")
		)
		(pin "7"
			(uuid "5271cb73-b4a4-42d9-9286-d28ede7a0012")
		)
		(pin "8"
			(uuid "1b402b97-10b9-494f-9588-28897db15a5e")
		)
		(pin "9"
			(uuid "6488a480-b89a-456f-b25d-57be9f841bf8")
		)
		(instances
			(project ""
				(path "/02b1dd05-420e-48b3-9ee8-c9edbf2413ac"
					(reference "U6")
					(unit 1)
				)
			)
		)
	)
	(symbol
		(lib_id "rtc-sd-rescue:+5V-power")
		(at 220.98 149.86 90)
		(unit 1)
		(exclude_from_sim no)
		(in_bom yes)
		(on_board yes)
		(dnp no)
		(uuid "00000000-0000-0000-0000-000065492bf2")
		(property "Reference" "#PWR0124"
			(at 224.79 149.86 0)
			(effects
				(font
					(size 1.27 1.27)
				)
				(hide yes)
			)
		)
		(property "Value" "+5V"
			(at 217.7288 149.479 90)
			(effects
				(font
					(size 1.27 1.27)
				)
				(justify left)
			)
		)
		(property "Footprint" ""
			(at 220.98 149.86 0)
			(effects
				(font
					(size 1.27 1.27)
				)
				(hide yes)
			)
		)
		(property "Datasheet" ""
			(at 220.98 149.86 0)
			(effects
				(font
					(size 1.27 1.27)
				)
				(hide yes)
			)
		)
		(property "Description" ""
			(at 220.98 149.86 0)
			(effects
				(font
					(size 1.27 1.27)
				)
				(hide yes)
			)
		)
		(pin "1"
			(uuid "2dce96e4-18ba-4921-b79d-b24cda7f9ce6")
		)
		(instances
			(project ""
				(path "/02b1dd05-420e-48b3-9ee8-c9edbf2413ac"
					(reference "#PWR0124")
					(unit 1)
				)
			)
		)
	)
	(symbol
		(lib_id "rtc-sd-rescue:GND-power")
		(at 234.95 149.86 180)
		(unit 1)
		(exclude_from_sim no)
		(in_bom yes)
		(on_board yes)
		(dnp no)
		(uuid "00000000-0000-0000-0000-000065493383")
		(property "Reference" "#PWR0125"
			(at 234.95 143.51 0)
			(effects
				(font
					(size 1.27 1.27)
				)
				(hide yes)
			)
		)
		(property "Value" "GND"
			(at 234.95 146.05 0)
			(effects
				(font
					(size 1.27 1.27)
				)
			)
		)
		(property "Footprint" ""
			(at 234.95 149.86 0)
			(effects
				(font
					(size 1.27 1.27)
				)
				(hide yes)
			)
		)
		(property "Datasheet" ""
			(at 234.95 149.86 0)
			(effects
				(font
					(size 1.27 1.27)
				)
				(hide yes)
			)
		)
		(property "Description" ""
			(at 234.95 149.86 0)
			(effects
				(font
					(size 1.27 1.27)
				)
				(hide yes)
			)
		)
		(pin "1"
			(uuid "082f6ea3-8b48-4caf-969a-4282a9734f05")
		)
		(instances
			(project ""
				(path "/02b1dd05-420e-48b3-9ee8-c9edbf2413ac"
					(reference "#PWR0125")
					(unit 1)
				)
			)
		)
	)
	(symbol
		(lib_id "rtc-sd-rescue:+5V-power")
		(at 261.62 119.38 0)
		(unit 1)
		(exclude_from_sim no)
		(in_bom yes)
		(on_board yes)
		(dnp no)
		(uuid "00000000-0000-0000-0000-0000654a598a")
		(property "Reference" "#PWR0121"
			(at 261.62 123.19 0)
			(effects
				(font
					(size 1.27 1.27)
				)
				(hide yes)
			)
		)
		(property "Value" "+5V"
			(at 262.001 114.9858 0)
			(effects
				(font
					(size 1.27 1.27)
				)
			)
		)
		(property "Footprint" ""
			(at 261.62 119.38 0)
			(effects
				(font
					(size 1.27 1.27)
				)
				(hide yes)
			)
		)
		(property "Datasheet" ""
			(at 261.62 119.38 0)
			(effects
				(font
					(size 1.27 1.27)
				)
				(hide yes)
			)
		)
		(property "Description" ""
			(at 261.62 119.38 0)
			(effects
				(font
					(size 1.27 1.27)
				)
				(hide yes)
			)
		)
		(pin "1"
			(uuid "0ca5fe07-45e8-4f56-8dd6-890b9fb73889")
		)
		(instances
			(project ""
				(path "/02b1dd05-420e-48b3-9ee8-c9edbf2413ac"
					(reference "#PWR0121")
					(unit 1)
				)
			)
		)
	)
	(symbol
		(lib_id "rtc-sd-rescue:GND-power")
		(at 261.62 160.02 0)
		(unit 1)
		(exclude_from_sim no)
		(in_bom yes)
		(on_board yes)
		(dnp no)
		(uuid "00000000-0000-0000-0000-0000654a5ed7")
		(property "Reference" "#PWR0122"
			(at 261.62 166.37 0)
			(effects
				(font
					(size 1.27 1.27)
				)
				(hide yes)
			)
		)
		(property "Value" "GND"
			(at 261.747 164.4142 0)
			(effects
				(font
					(size 1.27 1.27)
				)
			)
		)
		(property "Footprint" ""
			(at 261.62 160.02 0)
			(effects
				(font
					(size 1.27 1.27)
				)
				(hide yes)
			)
		)
		(property "Datasheet" ""
			(at 261.62 160.02 0)
			(effects
				(font
					(size 1.27 1.27)
				)
				(hide yes)
			)
		)
		(property "Description" ""
			(at 261.62 160.02 0)
			(effects
				(font
					(size 1.27 1.27)
				)
				(hide yes)
			)
		)
		(pin "1"
			(uuid "5556ffef-6ea4-43b1-8a03-53535e33ca27")
		)
		(instances
			(project ""
				(path "/02b1dd05-420e-48b3-9ee8-c9edbf2413ac"
					(reference "#PWR0122")
					(unit 1)
				)
			)
		)
	)
	(symbol
		(lib_id "rtc-sd-rescue:+5V-power")
		(at 248.92 149.86 90)
		(unit 1)
		(exclude_from_sim no)
		(in_bom yes)
		(on_board yes)
		(dnp no)
		(uuid "00000000-0000-0000-0000-0000654b7d95")
		(property "Reference" "#PWR0123"
			(at 252.73 149.86 0)
			(effects
				(font
					(size 1.27 1.27)
				)
				(hide yes)
			)
		)
		(property "Value" "+5V"
			(at 245.6688 149.479 90)
			(effects
				(font
					(size 1.27 1.27)
				)
				(justify left)
			)
		)
		(property "Footprint" ""
			(at 248.92 149.86 0)
			(effects
				(font
					(size 1.27 1.27)
				)
				(hide yes)
			)
		)
		(property "Datasheet" ""
			(at 248.92 149.86 0)
			(effects
				(font
					(size 1.27 1.27)
				)
				(hide yes)
			)
		)
		(property "Description" ""
			(at 248.92 149.86 0)
			(effects
				(font
					(size 1.27 1.27)
				)
				(hide yes)
			)
		)
		(pin "1"
			(uuid "c5dcac9e-16bd-4ed4-9f3d-c1bfaefe49fc")
		)
		(instances
			(project ""
				(path "/02b1dd05-420e-48b3-9ee8-c9edbf2413ac"
					(reference "#PWR0123")
					(unit 1)
				)
			)
		)
	)
	(sheet_instances
		(path "/"
			(page "1")
		)
	)
)
