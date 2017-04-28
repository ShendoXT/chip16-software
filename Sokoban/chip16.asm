;Sokoban clone for the Chip16
;Shendo, 2012 - 2013
;
;r0 - Unused
;r1 - Unused
;r2 - Unused
;r3 - Unused
;r4 - Level completed bool
;r5 - Player X coordinate
;r6 - Player Y coordinate
;r7 - PAD1 status
;r8 - PAD1 D-PAD timeout value
;r9 - Current level (50 levels max)
;ra - Scratchpad used by subroutines
;rb - Scratchpad used by subroutines
;rc - Scratchpad used by subroutines
;rd - Scratchpad used by subroutines
;re - Scratchpad used by subroutines
;rf - Scratchpad used by subroutines
;
;Game tiles:
;0x0000 - Nothing
;0x0001 - Floor
;0x0002 - Wall
;0x0003 - Goal
;0x0010 - Crate
;
;Compressed game tiles
;0x00 - Nothing
;0x01 - Floor
;0x02 - Wall
;0x03 - Goal
;0x10 - Crate
;0x20 - Player

importbin logo.bin 0 3000 logo			;Logo for the main screen
importbin tiles.bin 0 490 tiles			;Tileset data
importbin font.bin 0 7125 font			;Monospace font
importbin levels.bin 0 15200 levels		;Compressed level data
importbin work_area.bin 0 608 work_area		;Working area containing current level

start:						;Start of the application
	cls					;Clear screen for fresh start
	ldi r9, 0				;Reset current level

	;jmp game_setup				;DEBUG FEATURE, SKIP START MENU!

menu:						;Main menu of the game
	vblnk					;Wait for VBlank
	cls					;Clear screen

	ldm r7, 0xFFF0				;Get PAD1 status

	tsti r7, 0xF				;Isolate PAD1 D-PAD
	cz restore_pad_timeout			;If D-PAD keys are not pressed restore timeout

	tsti r8, 0xFF				;Update flags for PAD1 D-PAD timeout
	jz menu_skip_decrement			;Skip decrement if the value is zero
	call decrement_pad_timeout		;Decrement the PAD1 D-PAD value

menu_skip_decrement:

	ldi ra, 100				;Logo X coordinate
	ldi rb, 65				;Logo Y coordinate
	spr #323C				;Set 120x50 px sprites
	drw ra, rb, logo			;Draw logo on screen

	mov re, r9				;Copy level for BCD conversion
	addi re, 1				;Add 1 since levels are zero based
	ldi rd, string_4_bcd			;Load BCD store address
	call i_to_bcd				;Convert integer value to BCD

	ldi re, 132				;Load string X coordinate
	ldi rf, 40				;Load string Y coordinate
	ldi rd, string_0			;Load string memory location
	call draw_string			;Draw string on screen

	ldi re, 80				;Load string X coordinate
	ldi rf, 140				;Load string Y coordinate
	ldi rd, string_4			;Load string memory location
	call draw_string			;Draw string on screen

	ldi re, 80				;Load string X coordinate
	ldi rf, 155				;Load string Y coordinate
	ldi rd, string_3			;Load string memory location
	call draw_string			;Draw string on screen

	ldi re, 32				;Load string X coordinate
	ldi rf, 200				;Load string Y coordinate
	ldi rd, string_1			;Load string memory location
	call draw_string			;Draw string on screen

	ldi re, 8				;Load string X coordinate
	ldi rf, 215				;Load string Y coordinate
	ldi rd, string_2			;Load string memory location
	call draw_string			;Draw string on screen

check_menu_pad_start:
	tsti r7, 32				;Isolate START button
	jz check_menu_pad_timeout		;If START is not pressed skip going to game
	jmp game_setup				;Jump to game scene

check_menu_pad_timeout:
	tsti r8, 0XFF				;Update flags for PAD1 D-PAD timeout
	jz check_menu_pad_left			;If there is no timeout check keys

	jmp menu				;Skip checking keys

check_menu_pad_left:				;Check if LEFT button is pressed
	tsti r7, 4				;Isolate LEFT button
	jz check_menu_pad_right			;If the key is not pressed skip level decrement
	tsti r9, 0xFF				;Update flags for current level
	jz check_menu_pad_right			;If the value is zero skip decrementing
	subi r9, 1				;Decrement current level
	snd2, 5					;Play 1000 Hz tone for 5 ms
	ldi r8, 7				;Set PAD1 D-PAD timeout

check_menu_pad_right:				;Check if the RIGHT button is pressed
	tsti r7, 8				;Isolate RIGHT button
	jz menu					;If the key is not pressed skip level increment
	mov ra, r9				;Copy current level to scratchpad
	subi ra, 49				;Substract maximum level offset
	jz menu					;If the value is zero skip incrementing
	addi r9, 1				;Increment current level
	snd2, 5					;Play 1000 Hz tone for 5 ms
	ldi r8, 7				;Set PAD1 D-PAD timeout

	jmp menu				;Draw another frame

game_setup:					;Set everything up before executing game
	ldi r5, 0				;Set default Player X coordinate
	ldi r6, 0				;Set default player Y coordinate

	call decompress_level			;Decompress current level to memory (work area)

game:						;Main loop of the game
	vblnk 					;Wait for VBlank
	cls					;Clear screen

	bgc 0xC					;Set blue background

	ldm r7, 0xFFF0				;Get PAD1 status

	mov re, r9				;Copy level for BCD conversion
	addi re, 1				;Add 1 since levels are zero based
	ldi rd, string_5_bcd			;Load BCD store address
	call i_to_bcd				;Convert integer value to BCD

	ldi re, 272				;Load string X coordinate
	ldi rf, 10				;Load string Y coordinate
	ldi rd, string_5			;Load string memory location
	call draw_string			;Draw string on screen

	ldi r4, 0x1				;Lie that level is completed (will be debunked if there are unsolved goals)

	call draw_board				;Draw current game board on screen
	call draw_player			;Draw player sprite

	mov ra, r4				;Copy level completed bool to scratchpad
	subi ra, 1				;Isolate TRUE state
	jz level_completed			;Level is completed, load next one


check_game_pad_select:
	tsti r7, 16				;Isolate SELECT button
	jz check_game_pad_b			;If SELECT is not pressed proceed further
	jmp menu				;Go to menu scene

check_game_pad_b:
	tsti r7, 128				;Isolate B button
	jz player_movement			;If B is not pressed proceed further
	jmp game_setup				;Go to menu scene


player_movement:				;Part of the code responsible for player movement
	tsti r7, 0xF				;Isolate PAD1 D-PAD
	cz restore_pad_timeout			;If D-PAD keys are not pressed restore timeout

	tsti r8, 0xFF				;Update flags for PAD1 D-PAD timeout
	jz check_game_pad_timeout		;Skip decrement if the value is zero
	call decrement_pad_timeout		;Decrement the PAD1 D-PAD value

check_game_pad_timeout:
	tsti r8, 0XFF				;Update flags for PAD1 D-PAD timeout
	jz check_game_pad_up			;If there is no timeout check keys

	jmp game				;Skip checking keys

check_game_pad_up:
	tsti r7, 0x1				;Isolate PAD1 UP
	jz check_game_pad_down			;UP is not pressed
	ldi r8, 9				;Set PAD1 D-PAD timeout

	call move_player_up			;Run UP subroutine

check_game_pad_down:
	tsti r7, 0x2				;Isolate PAD1 DOWN
	jz check_game_pad_left			;DOWN is not pressed
	ldi r8, 9				;Set PAD1 D-PAD timeout

	call move_player_down			;Run DOWN subroutine

check_game_pad_left:
	tsti r7, 0x4				;Isolate PAD1 LEFT
	jz check_game_pad_right			;LEFT is not pressed
	ldi r8, 9				;Set PAD1 D-PAD timeout

	call move_player_left			;Run LEFT subroutine

check_game_pad_right:
	tsti r7, 0x8				;Isolate PAD1 RIGHT
	jz game					;RIGHT is not pressed
	ldi r8, 9				;Set PAD1 D-PAD timeout

	call move_player_right			;Run RIGHT subroutine

	jmp game				;Run game routine again

level_completed:				;Level is completed
	ldi ra, 30				;Wait 30 frames
	call wait_frames			;Call wait subroutine

	mov ra, r9				;Copy current level
	subi ra, 50				;Get the maximum number of levels
	jz menu					;Max level beaten, go to menu

	addi r9, 1				;Increment current level
	jmp game_setup				;Start new level

;SUBROUTINES

move_player_up:					;Check surroundings and move player up
	mov ra, r5				;Copy X coordinate
	mov rb, r6				;Copy Y coordinate
	subi rb, 1				;UP needs to be checked
	call get_address_to_check		;Calculate work area related address to check
	mov re, ra				;Copy calculated address

	mov ra, r5				;Copy X coordinate
	mov rb, r6				;Copy Y coordinate
	subi rb, 2				;UP needs to be checked
	call get_address_to_check		;Calculate work area related address to check

	call get_ok_to_move			;Check if it's OK to move UP
	
	tsti rf, 0x1				;Check if the value is true
	jz fret					;Value is FALSE return from subroutine

	subi r6, 1				;Move player UP

	jmp fret

move_player_down:				;Check surroundings and move player down
	mov ra, r5				;Copy X coordinate
	mov rb, r6				;Copy Y coordinate
	addi rb, 1				;DOWN needs to be checked
	call get_address_to_check		;Calculate work area related address to check
	mov re, ra				;Copy calculated address

	mov ra, r5				;Copy X coordinate
	mov rb, r6				;Copy Y coordinate
	addi rb, 2				;DOWN needs to be checked
	call get_address_to_check		;Calculate work area related address to check

	call get_ok_to_move			;Check if it's OK to move DOWN
	
	tsti rf, 0x1				;Check if the value is true
	jz fret					;Value is FALSE return from subroutine

	addi r6, 1				;Move player DOWN

	jmp fret

move_player_left:				;Check surroundings and move player left
	mov ra, r5				;Copy X coordinate
	mov rb, r6				;Copy Y coordinate
	subi ra, 1				;LEFT needs to be checked
	call get_address_to_check		;Calculate work area related address to check
	mov re, ra				;Copy calculated address

	mov ra, r5				;Copy X coordinate
	mov rb, r6				;Copy Y coordinate
	subi ra, 2				;LEFT needs to be checked
	call get_address_to_check		;Calculate work area related address to check

	call get_ok_to_move			;Check if it's OK to move LEFT
	
	tsti rf, 0x1				;Check if the value is true
	jz fret					;Value is FALSE return from subroutine

	subi r5, 1				;Move player LEFT

	jmp fret

move_player_right:				;Check surroundings and move player right
	mov ra, r5				;Copy X coordinate
	mov rb, r6				;Copy Y coordinate
	addi ra, 1				;RIGHT needs to be checked
	call get_address_to_check		;Calculate work area related address to check
	mov re, ra				;Copy calculated address

	mov ra, r5				;Copy X coordinate
	mov rb, r6				;Copy Y coordinate
	addi ra, 2				;RIGHT needs to be checked
	call get_address_to_check		;Calculate work area related address to check

	call get_ok_to_move			;Check if it's OK to move RIGHT
	
	tsti rf, 0x1				;Check if the value is true
	jz fret					;Value is FALSE return from subroutine

	addi r5, 1				;Move player RIGHT

	jmp fret

get_ok_to_move:					;Check if it's ok to move to the selected field
	ldi rf, 0				;Bool value FALSE, not OK to move
	ldm rc, re				;Load value from work_area

	andi rc, 0xF				;Isolate only lower layer
	subi rc, 1				;Isolate floor tile
	jz check_upper_layer			;It's OK to move on floor surface
	
	subi rc, 2				;Isolate goal tile
	jz check_upper_layer			;It's OK to move on goal surface	

	jmp fret				;Return from this subroutine

check_upper_layer:				;Check upper layer for crates
	ldm rc, re				;Load value from work_area
	andi rc, 0xF0				;Isolate only upper layer
	subi rc, 0x10				;Isolate crate
	jz crate_encountered			;Crate on the path, need further calculation

	jmp set_ok_to_move			;No obstructions, player is free to move

crate_encountered:				;There is a crate on the path
	ldm rc, ra				;Load data for next tile
	andi rc, 0xFF				;Isolate only 8 bit data

	subi rc, 0x1				;Isolate wall tile
	jz move_crate				;It's OK to move crate on the wall

	subi rc, 0x2				;Isolate goal tile
	jz move_crate				;It's OK to move crate on the goal

	jmp fret				;Something is blocking the path, return from subroutine

move_crate:					;Move crate to next tile
	ldm rc, re				;Get current tile data from work_area
	andi rc, 0xF				;Leave only low layer
	stm rc, re				;Store modified data

	ldm rc, ra				;Get next tile from work_area
	ori rc, 0x10				;Add crate to the value
	stm rc, ra				;Store modified data

	snd1, 5					;Play 500 Hz tone for 5 ms

set_ok_to_move:					;Player is allowed to move
	ldi rf, 1				;Bool value TRUE, OK to move
	jmp fret

get_address_to_check:				;Convert check coordinates to work address
	muli rb, 19				;1Y = 19X
	add ra, rb				;Address = Y+X
	muli ra, 2				;Address is 16 bit
	
	addi ra, work_area			;Add work area offset

	jmp fret

draw_player:					;Draw player on the screen
	spr #0E07				;Set 14x14 px sprites
	mov ra, r5				;Copy X coordinate
	mov rb, r6				;Copy Y coordinate

	muli ra, 14				;Sprite width
	muli rb, 14				;Sprite height

	ldi rc, tiles				;Load address of the sprite data
	addi rc, 392				;Set address to player sprite

	drw ra, rb, rc				;Draw sprite on screen

	jmp fret

draw_tile:					;Draw 16x6 px tile on screen
	ldm rf, rd				;Get tile index from memory in work area
	addi rf, 0				;Update flags
	jz fret					;If the value is zero don't draw anything

	andi rf, 0xFF				;Isolate all tile data
	subi rf, 0x03				;Uncompleted goal tile
	cz set_completed_false			;Set FALSE for completed level

	ldm rf, rd				;Get tile index from memory in work area	

	andi rf, 0x0F				;Remove upper layer
	subi rf, 1				;Remove floor index
	jz draw_tile_floor			;Index is floor tile

	subi rf, 1				;Remove wall index
	jz draw_tile_wall			;Index is wall tile

	subi rf, 1				;Remove goal index
	jz draw_tile_goal			;Index is goal tile

	jmp fret	

draw_tile_upper:				;Draw upper tile layer
	ldm rf, rd				;Get tile index from memory in work area
	addi rf, 0				;Update flags
	jz fret					;If the value is zero don't draw anything
	
	andi rf, 0xF0				;Remove lower layer
	
	subi rf, 0x10				;Remove crate
	jz draw_tile_crate			;index is crate tile

	jmp fret

draw_tile_floor:				;Draw floor tile
	ldi re, tiles				;Load start address of tiles
	drw ra, rb, re				;Draw floor tile
	jmp fret

draw_tile_wall:					;Draw wall tile
	ldi re, tiles				;Load start address of tiles
	addi re, 98				;Add wall offset
	drw ra, rb, re				;Draw wall tile
	jmp fret

draw_tile_goal:					;Draw goal tile
	ldi re, tiles				;Load start address of tiles
	addi re, 196				;Add goal offset
	drw ra, rb, re				;Draw goal tile
	jmp fret

draw_tile_crate:				;Draw crate tile
	ldi re, tiles				;Load start address of tiles
	addi re, 294				;Add crate offset
	drw ra, rb, re				;Draw crate tile
	jmp fret


draw_board:					;Draw 19x16 tile gameboard
	spr #0E07				;Set 14x14 px sprites
	ldi ra, 0				;Tile X coordinate
	ldi rb, 0				;Tile Y coordinate
	ldi rd, work_area			;Start address of work area

draw_board_x_loop:				;Draw tiles along X axis
	call draw_tile				;Draw floor tile (wall, floor, goal)
	call draw_tile_upper			;Draw upper layer (crate, player)
	addi rd, 2				;Increase memory offset of work area

	addi ra, 14				;Increase X by tile width
	ldi rc, 266				;Load max X coordinate to scratchpad
	jme ra, rc, draw_board_y_loop		;If max coordinate is reached stop drawing
	jmp draw_board_x_loop			;Repeat for the next tile

draw_board_y_loop:				;Draw tiles along Y axis
	ldi ra, 0				;Reset tile X coordinate
	addi rb, 14				;Increase Y by tile height
	ldi rc, 224				;Load max Y coordinate to scratchpad
	jme rb, rc, fret			;If max coordinate is reached stop drawing
	jmp draw_board_x_loop			;Contine drawing on X asis

	jmp fret				;This code should't be reached, but it's here for safety

decrement_pad_timeout:				;Decrement PAD1 D-PAD timeout
	subi r8, 1				;Decrement PAD1 D-PAD timeout
	jmp fret

restore_pad_timeout:				;Restore PAD1 D-PAD timeout value
	ldi r8, 0				;Set no timeout
	jmp fret

i_to_bcd:					;Convert integer and store it as BCD
	mov ra, re				;Copy integer to scratchpad
	mov rb, re				;Copy integer to scratchpad

	divi ra, 10				;Isolate tenths
	mov rc, ra				;Copy tenths to scratchpad
	muli ra, 10				;Get tenths without ones
	sub rb, ra				;Get ones by removing tenths

	addi rb, 0x30				;Convert ones to ASCII
	addi rc, 0x30				;Convert tenths to ascii

	shl rb, 8				;Move ones to hi byte
	add rb, rc				;Add tenths to output buffer

	stm rb, rd				;Store BCD to memory

	jmp fret


draw_string:					;Draw string on screen
	spr #0F05				;Set 10x15 px sprites
	ldm ra, rd				;Load characted from memory
	andi ra, #FF				;Only the lo byte is needed

	addi ra, 0				;Update flags
	jz fret					;Null reached, break subroutine

	subi ra, 0x20				;Remove difference between ASCII code and graphics
	
	mov rb, ra				;Copy data to scratchpad
	muli rb, 75				;Each character is 75 bytes long
	addi rb, font				;Apply offset to font address

	drw re, rf, rb				;Draw 10x15 character on the set coordinates

	addi rd, 1				;Increase memory offset
	addi re, 8				;Increase X coordinate

	jmp draw_string

decompress_level:				;Decompress current level to work area
	mov ra, r9				;Get current level
	muli ra, 304				;Multiply it by number of bytes for each level
	addi ra, levels				;Add a starting address of the levels data

	ldi rb, work_area			;Get address of the work area

	ldi re, 304				;Counter for each byte

decompress_level_loop:
	ldm rf, ra				;Load tile data from memory
	andi rf, 0xFF				;Get only lower byte (8 bit data)
	stm rf, rb				;Store "decompressed" data
	
	ldm rf, ra				;Load tile data from memory
	andi rf, 0xF0				;Get only upper layer data (crates and player)
	subi rf, 0x20				;Isolate player index
	cz calc_player_def_pos			;Get player coordinates

	addi ra, 1				;Increase address (8 bit)
	addi rb, 2				;Increase address (16 bit)
	
	subi re, 1				;Decrement counter

	jz fret					;Data is loaded, break subroutine
	jmp decompress_level_loop		;Loop for the next byte
	
	jmp fret				;This code should't be reached, but it's here for safety

calc_player_def_pos:				;Calculate player's default position and remove it from tileset
	mov rc, rb				;Copy address
	subi rc, work_area			;Remove work area offset to get clean coordinate
	divi rc, 2				;Divide by 2 since data is 16 bit
	mov rd, rc				;Copy clean address
	
	divi rc, 19				;Get Y coordinate
	mov r6, rc				;Copy Player Y coordinate

	muli rc, 19				;Get address without remainder
	sub rd, rc				;Get remainder (X cordinate)
	
	mov r5, rd				;Copy Player X coordinate

	ldi, rf, 0x1				;Kill player from the board (Replace it with floor tile)
	stm rf, rb				;Store new data

	jmp fret

set_completed_false:				;Set level completed bool to false
	ldi r4, 0				;FALSE
	jmp fret

wait_frames:					;Wait for required number of frames
	vblnk					;Wait for VBLANK
	subi ra, 1				;Decrement wait number
	jz fret					;Value is zero, stop waiting
	jmp wait_frames				;Wait for another frame

fret:						;Subroutine return function
	ret					;Return from a subroutine

;STRING DATA

string_author:					;Author's name
	db "Shendo"
	db 0x00

string_0:
	db "SOKOBAN"
	db 0x00

string_1:
	db "Original game by Thinking Rabbit"
	db 0x00

string_2:
	db "Remake by Shendo, Cettah and AxisZ8008"
	db 0x00

string_3:
	db "Press START to begin"
	db 0x00

string_4:
	db "Select level: < "
string_4_bcd:
	db "00 >"
	db 0x00

string_5:
	db "LV:"
string_5_bcd:
	db "00"
	db 0x00
